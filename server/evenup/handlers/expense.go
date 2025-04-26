package handlers

import(
	"fmt"
	"log"
	"net/http"
	"strings"
	"github.com/lib/pq"
	_ "github.com/lib/pq" // PostgreSQL driver
	"github.com/anshikag020/EvenUp/server/evenup/config"
	"encoding/json"
	"github.com/anshikag020/EvenUp/ws_server/pubsub"
	"github.com/emirpasic/gods/maps/treemap"
	"github.com/emirpasic/gods/utils"
	"database/sql"
	"errors"
)

type AddExpenseRequest struct {
	GroupID      string             `json:"group_id"`
	Username     string             `json:"username"`
	Description  string             `json:"description"`
	Amount       float64            `json:"amount"`
	Tag          string             `json:"tag"` // One tag string
	SplitBetween map[string]float64 `json:"split_between"` // username: amount_owed
	PaidBy       map[string]float64 `json:"paid_by"`       // username: amount_contributed
}

type AddExpenseResponse struct {
	Status  bool   `json:"status"`
	Message string `json:"message"`
}

// Single string-to-int mapping
func mapTagToInt(tag string) int {
	switch strings.ToLower(tag) {
	case "food":
		return 0
	case "transport":
		return 1
	case "entertainment":
		return 2
	case "shopping":
		return 3
	case "bills":
		return 4
	default:
		return 5 // other
	}
}

func Float64Comparator(a, b interface{}) int {
	fa := a.(float64)
	fb := b.(float64)

	switch {
	case fa < fb:
		return -1
	case fa > fb:
		return 1
	default:
		return 0
	}
}

func autoDetectTag(description string) string {
	desc := strings.ToLower(description)

	tagKeywords := map[string][]string{
		"food": {
			"restaurant", "pizza", "lunch", "groceries", "grocery", "coffee", "snacks", "meal", "meals",
			"food", "breakfast", "dinner", "kfc", "mcdonalds", "zomato", "swiggy", "cafeteria", "takeout",
			"dominos", "chai", "thali", "dessert", "juice", "beverage", "bar", "pub", "canteen",
		},
		"transport": {
			"uber", "ola", "taxi", "bus", "train", "metro", "fuel", "cab", "car", "bike", "auto",
			"toll", "parking", "flight", "airfare", "transport", "fare", "gas", "petrol", "diesel", "ride",
			"commute", "pass", "ticket", "carpool",
		},
		"entertainment": {
			"movie", "cinema", "netflix", "hotstar", "prime", "party", "game", "games", "concert", "event",
			"music", "theatre", "fun", "outing", "show", "match", "youtube", "spotify", "standup",
			"amusement", "zoo", "park", "hangout", "sports", "fair", "exhibition",
		},
		"shopping": {
			"clothes", "shoes", "shopping", "amazon", "flipkart", "purchase", "store", "mall", "order",
			"bought", "dress", "jeans", "jacket", "kurti", "saree", "tshirt", "shirt", "bag", "makeup",
			"cosmetics", "gift", "jewelry", "accessory", "watch", "phone", "mobile", "electronics",
			"charger", "headphones", "tech", "appliance", "laptop", "stationery", "furniture",
		},
		"bills": {
			"electricity", "water", "internet", "wifi", "recharge", "mobile", "bill", "rent", "emi",
			"loan", "subscription", "payment", "postpaid", "prepaid", "broadband", "dues", "fees",
			"gas bill", "maintenance", "housing", "net", "connection", "utilities", "tv", "dth",
		},
	}

	for tag, keywords := range tagKeywords {
		for _, keyword := range keywords {
			if strings.Contains(desc, keyword) {
				return tag
			}
		}
	}
	return "other"
}

func AddExpenseHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var req AddExpenseRequest
	var err error
	responded := false

	if err = json.NewDecoder(r.Body).Decode(&req); err != nil {
		json.NewEncoder(w).Encode(AddExpenseResponse{
			Status:  false,
			Message: "Invalid request body",
		})
		return
	}

	tx, err := config.DB.Begin()
	if err != nil {
		log.Println("Failed to begin transaction:", err)
		json.NewEncoder(w).Encode(AddExpenseResponse{
			Status:  false,
			Message: "Internal server error",
		})
		return
	}

	defer func() {
		if p := recover(); p != nil {
			_ = tx.Rollback()
			panic(p)
		} else if err != nil {
			_ = tx.Rollback()
			log.Println("Transaction rolled back due to error:", err)
		} else {
			if commitErr := tx.Commit(); commitErr != nil {
				log.Println("Failed to commit transaction:", commitErr)
				if !responded {
					json.NewEncoder(w).Encode(AddExpenseResponse{
						Status:  false,
						Message: "Failed to commit transaction",
					})
				}
			}
		}
	}()

	// Step 1: Check if group exists
	var groupExists bool
	err = tx.QueryRow(`SELECT EXISTS(SELECT 1 FROM groups WHERE group_id = $1)`, req.GroupID).Scan(&groupExists)
	if err != nil {
		log.Println("Failed to check group existence:", err)
		json.NewEncoder(w).Encode(AddExpenseResponse{
			Status:  false,
			Message: "Internal server error",
		})
		responded = true
		return
	}
	if !groupExists {
		json.NewEncoder(w).Encode(AddExpenseResponse{
			Status:  false,
			Message: "Group not found",
		})
		err = errors.New("group not found")
		responded = true
		return
	}

	// Step 2: Validate users in the group
	userSet := map[string]bool{}
	for u := range req.SplitBetween {
		userSet[u] = true
	}
	for u := range req.PaidBy {
		userSet[u] = true
	}
	userList := make([]string, 0, len(userSet))
	for u := range userSet {
		userList = append(userList, u)
	}

	rows, err := tx.Query(`
		SELECT participant FROM group_participants
		WHERE group_id = $1 AND participant = ANY($2)
	`, req.GroupID, pq.Array(userList))
	if err != nil {
		log.Println("Failed to validate users:", err)
		json.NewEncoder(w).Encode(AddExpenseResponse{
			Status:  false,
			Message: "Internal server error",
		})
		responded = true
		return
	}
	defer rows.Close()

	validUsers := map[string]bool{}
	for rows.Next() {
		var username string
		if scanErr := rows.Scan(&username); scanErr == nil {
			validUsers[username] = true
		} else {
			log.Println("Failed to scan username:", scanErr)
			// Don't early return here; just skip
		}
	}
	for user := range userSet {
		if !validUsers[user] {
			json.NewEncoder(w).Encode(AddExpenseResponse{
				Status:  false,
				Message: fmt.Sprintf("User '%s' has left the group or is invalid", user),
			})
			err = errors.New("invalid user found")
			responded = true
			return
		}
	}

	// Auto-detect tag if needed
	if strings.ToLower(req.Tag) == "other" || strings.TrimSpace(req.Tag) == "" {
		req.Tag = autoDetectTag(req.Description)
	}

	// Step 3: Insert the expense
	tagInt := mapTagToInt(req.Tag)

	var expenseID string
	err = tx.QueryRow(`
		INSERT INTO expenses (group_id, description, tag, added_by, amount)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING expense_id
	`, req.GroupID, req.Description, tagInt, req.Username, req.Amount).Scan(&expenseID)
	if err != nil {
		log.Println("Error inserting expense:", err)
		json.NewEncoder(w).Encode(AddExpenseResponse{
			Status:  false,
			Message: "Failed to add expense",
		})
		responded = true
		return
	}

	// Step 4: Insert bill splits
	stmt, err := tx.Prepare(`
		INSERT INTO bill_split (expense_id, username, amount_contributed, amount_owed)
		VALUES ($1, $2, $3, $4)
	`)
	if err != nil {
		log.Println("Prepare statement failed:", err)
		json.NewEncoder(w).Encode(AddExpenseResponse{
			Status:  false,
			Message: "Internal server error",
		})
		responded = true
		return
	}
	defer stmt.Close()

	for user := range userSet {
		contrib := req.PaidBy[user]
		owed := req.SplitBetween[user]

		if contrib == 0 && owed == 0 {
			continue
		}

		_, execErr := stmt.Exec(expenseID, user, contrib, owed)
		if execErr != nil {
			log.Println("Insert bill_split failed:", execErr)
			json.NewEncoder(w).Encode(AddExpenseResponse{
				Status:  false,
				Message: "Failed to save split info",
			})
			responded = true
			return
		}
	}

	// Step 5: Update balances
	netChanges := make(map[string]float64)
	for user, paidAmount := range req.PaidBy {
		netChanges[user] += paidAmount
	}
	for user, owedAmount := range req.SplitBetween {
		netChanges[user] -= owedAmount
	}

	err = OptimiseBalances(tx, req.GroupID, netChanges)
	if err != nil {
		log.Println("Error optimizing balances:", err)
		json.NewEncoder(w).Encode(AddExpenseResponse{
			Status:  false,
			Message: "Failed to update balances",
		})
		responded = true
		return
	}


	// Success response
	json.NewEncoder(w).Encode(AddExpenseResponse{
		Status:  true,
		Message: "Expense added successfully",
	})
	responded = true

	// Send WebSocket Notification
	if WS != nil {
		payload, _ := json.Marshal(map[string]interface{}{
			"type":     "expense_added",
			"group_id": req.GroupID,
			"by":       req.Username,
			"amount":   req.Amount,
		})
		pubsub.NotifyExpense(WS, payload)
	}
}

// OptimiseBalances now takes tx (transaction) as an argument
func OptimiseBalances(tx *sql.Tx, groupID string, netChanges map[string]float64) error {
	// No need to start a new transaction here, just use the passed tx

	// Step 1: Get all balances for the group
	rows, err := tx.Query(`
		SELECT sender, receiver, amount
		FROM balances
		WHERE group_id = $1
	`, groupID)
	if err != nil {
		log.Println("Error fetching balances:", err)
		return err
	}
	defer rows.Close()

	// Step 2: Create map to hold net balances for each user
	userNet := make(map[string]float64)

	// Step 3: Populate userNet with net balances
	for rows.Next() {
		var fromUser, toUser string
		var amount float64
		if err := rows.Scan(&fromUser, &toUser, &amount); err != nil {
			log.Println("Error scanning balance row:", err)
			return err
		}

		// Initialize if not already in map
		if _, exists := userNet[fromUser]; !exists {
			userNet[fromUser] = 0
		}
		if _, exists := userNet[toUser]; !exists {
			userNet[toUser] = 0
		}

		userNet[fromUser] -= amount
		userNet[toUser] += amount
	}

	// Step 4: Delete all balances for the group
	_, err = tx.Exec(`
		DELETE FROM balances
		WHERE group_id = $1
	`, groupID)
	if err != nil {
		log.Println("Error deleting balances:", err)
		return err
	}

	// Step 5: Apply the provided netChanges to the userNet map
	for user, delta := range netChanges {
		if _, exists := userNet[user]; !exists {
			userNet[user] = 0
		}
		userNet[user] += delta
	}

	// Custom comparator for descending order (reverse of ascending)
	descendingComparator := func(a, b interface{}) int {
		return utils.Float64Comparator(b, a) // reverse comparison
	}

	// Create TreeMaps for debtors and creditors
	debtors := treemap.NewWith(utils.Float64Comparator)           // ascending order for debtors
	creditors := treemap.NewWith(descendingComparator) // descending order for creditors

	// Fill debtors and creditors based on net balances
	for user, amount := range userNet {
		if amount > 0 {
			creditors.Put(amount, user)
		} else if amount < 0 {
			debtors.Put(amount, user)
		}
	}

	// Step 6: Settle balances between debtors and creditors
	for !creditors.Empty() && !debtors.Empty() {
		// Get top creditor (most positive balance)
		cKey, cVal := creditors.Min() // key: amount, val: username
		creditAmount := cKey.(float64)
		creditUser := cVal.(string)

		// Get top debtor (most negative balance)
		dKey, dVal := debtors.Min() // key: amount (negative), val: username
		debitAmount := dKey.(float64)
		debitUser := dVal.(string)

		// Determine the amount to settle between the two
		settleAmount := min(creditAmount, -debitAmount)

		// Insert new balance into the balances table
		_, err := tx.Exec(`
			INSERT INTO balances (group_id, sender, receiver, amount)
			VALUES ($1, $2, $3, $4)
		`, groupID, debitUser, creditUser, settleAmount)
		if err != nil {
			log.Println("Failed to insert new balance:", err)
			return err
		}

		// Update and reinsert if necessary
		creditors.Remove(cKey)
		debtors.Remove(dKey)

		remainingCredit := creditAmount - settleAmount
		remainingDebit := debitAmount + settleAmount

		if remainingCredit > 0 {
			creditors.Put(remainingCredit, creditUser)
		}
		if remainingDebit < 0 {
			debtors.Put(remainingDebit, debitUser)
		}
	}

	return nil
}

// Helper function to get the minimum of two values
func min(a, b float64) float64 {
	if a < b {
		return a
	}
	return b
}


func DeleteExpenseHandler(w http.ResponseWriter, r *http.Request) {
    var req struct {
        ExpenseID string `json:"expense_id"`
        Username  string `json:"username"`
        Cookie    string `json:"cookie"`
    }
    _ = json.NewDecoder(r.Body).Decode(&req)

    // Start transaction
    tx, err := config.DB.Begin()
    if err != nil {
        respondWithError(w, "Failed to start transaction")
        return
    }
    defer func() {
        if p := recover(); p != nil {
            tx.Rollback()
            panic(p)
        } else if err != nil {
            tx.Rollback()
        }
    }()

    // Step 2: Find group_id
    var groupID string
    err = tx.QueryRow(`SELECT group_id FROM expenses WHERE expense_id = $1`, req.ExpenseID).Scan(&groupID)
    if err == sql.ErrNoRows {
        respondWithError(w, "Expense not found")
        return
    } else if err != nil {
        respondWithError(w, "Database error")
        return
    }

    // Step 3: Check if user is part of the group
    var exists bool
    err = tx.QueryRow(`
        SELECT EXISTS(
            SELECT 1 FROM group_participants
            WHERE group_id = $1 AND participant = $2
        )
    `, groupID, req.Username).Scan(&exists)
    if err != nil || !exists {
        respondWithError(w, "You are not part of the group")
        return
    }

    // Step 4: Get users involved in the expense
    rows, err := tx.Query(`
        SELECT username, amount_contributed, amount_owed
        FROM bill_split
        WHERE expense_id = $1
    `, req.ExpenseID)
    if err != nil {
        respondWithError(w, "Error fetching bill split")
        return
    }
    defer rows.Close()

    type UserAmounts struct {
        Username          string
        AmountContributed float64
        AmountOwed        float64
    }
    var usersInExpense []UserAmounts
    for rows.Next() {
        var ua UserAmounts
        err = rows.Scan(&ua.Username, &ua.AmountContributed, &ua.AmountOwed)
        if err != nil {
            respondWithError(w, "Error scanning bill split")
            return
        }
        if ua.AmountContributed != 0 || ua.AmountOwed != 0 {
            usersInExpense = append(usersInExpense, ua)
        }
    }

    // Step 5: Verify all involved users are still in the group
    usernames := []string{}
    for _, ua := range usersInExpense {
        usernames = append(usernames, ua.Username)
    }

    rows2, err := tx.Query(`
        SELECT participant
        FROM group_participants
        WHERE group_id = $1 AND participant = ANY($2)
    `, groupID, pq.Array(usernames))
    if err != nil {
        respondWithError(w, "Error fetching participants")
        return
    }
    defer rows2.Close()

    participantsSet := make(map[string]bool)
    for rows2.Next() {
        var participant string
        _ = rows2.Scan(&participant)
        participantsSet[participant] = true
    }

    // Ensure all involved users are still participants
    for _, ua := range usersInExpense {
        if !participantsSet[ua.Username] {
            respondWithError(w, "Cannot delete expense. Some member has left the group")
            return
        }
    }

    // Step 6: Calculate net changes for each user
    netChanges := make(map[string]float64)
    for _, ua := range usersInExpense {
        if ua.AmountContributed != 0 {
            netChanges[ua.Username] -= ua.AmountContributed
        }
        if ua.AmountOwed != 0 {
            netChanges[ua.Username] += ua.AmountOwed
        }
    }

    // Step 7: Optimise balances based on net changes
    err = OptimiseBalances(tx, groupID, netChanges)
    if err != nil {
        respondWithError(w, "Failed to optimise balances")
        return
    }

    // Step 8: Delete the expense
    _, err = tx.Exec(`DELETE FROM expenses WHERE expense_id = $1`, req.ExpenseID)
    if err != nil {
        respondWithError(w, "Failed to delete expense")
        return
    }

    // Step 9: Commit transaction
    err = tx.Commit()
    if err != nil {
        respondWithError(w, "Failed to commit transaction")
        return
    }

    // Step 10: Respond with success
    respondWithJSON(w, true, "Expense deleted successfully")
}

func respondWithError(w http.ResponseWriter, message string) {
    respondWithJSON(w, false, message)
}

func respondWithJSON(w http.ResponseWriter, status bool, message string) {
    json.NewEncoder(w).Encode(map[string]interface{}{
        "status":  status,
        "message": message,
    })
}

