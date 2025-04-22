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
func AddExpenseHandler(w http.ResponseWriter, r *http.Request) {

	var req AddExpenseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"status":false,"message":"Invalid request body"}`, http.StatusBadRequest)
		return
	}

	// Start the transaction at the beginning
	tx, err := config.DB.Begin()
	if err != nil {
		log.Println("Failed to begin transaction:", err)
		http.Error(w, `{"status":false,"message":"Internal server error"}`, http.StatusInternalServerError)
		return
	}
	defer func() {
		if p := recover(); p != nil {
			tx.Rollback()
			panic(p)
		} else if err != nil {
			tx.Rollback()
			log.Println("Transaction rolled back due to error:", err)
			http.Error(w, `{"status":false,"message":"Transaction failed"}`, http.StatusInternalServerError)
		} else {
			err = tx.Commit()
			if err != nil {
				log.Println("Failed to commit transaction:", err)
				http.Error(w, `{"status":false,"message":"Failed to commit transaction"}`, http.StatusInternalServerError)
			}
		}
	}()

	// Step 1: Check if group exists
	var groupExists bool
	err = tx.QueryRow(`SELECT EXISTS(SELECT 1 FROM groups WHERE group_id = $1)`, req.GroupID).Scan(&groupExists)
	if err != nil || !groupExists {
		tx.Rollback()
		http.Error(w, `{"status":false,"message":"Group not found"}`, http.StatusNotFound)
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
		log.Println("Validation query error:", err)
		tx.Rollback()
		http.Error(w, `{"status":false,"message":"Internal server error"}`, http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	validUsers := map[string]bool{}
	for rows.Next() {
		var username string
		if err := rows.Scan(&username); err == nil {
			validUsers[username] = true
		}
	}
	for user := range userSet {
		if !validUsers[user] {
			tx.Rollback()
			w.WriteHeader(http.StatusForbidden)
			json.NewEncoder(w).Encode(AddExpenseResponse{
				Status:  false,
				Message: fmt.Sprintf("User '%s' has left the group or is invalid", user),
			})
			return
		}
	}

	// Step 3: Insert the expense into the database
	tagInt := mapTagToInt(req.Tag)

	var expenseID string
	err = tx.QueryRow(`
		INSERT INTO expenses (group_id, description, tag, added_by, amount)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING expense_id
	`, req.GroupID, req.Description, tagInt, req.Username, req.Amount).Scan(&expenseID)
	if err != nil {
		log.Println("Error inserting expense:", err)
		tx.Rollback()
		http.Error(w, `{"status":false,"message":"Failed to add expense"}`, http.StatusInternalServerError)
		return
	}

	// Step 4: Prepare and insert bill splits
	stmt, err := tx.Prepare(`
		INSERT INTO bill_split (expense_id, username, amount_contributed, amount_owed)
		VALUES ($1, $2, $3, $4)
	`)
	if err != nil {
		log.Println("Prepare failed:", err)
		tx.Rollback()
		http.Error(w, `{"status":false,"message":"Internal error"}`, http.StatusInternalServerError)
		return
	}
	defer stmt.Close()

	for user := range userSet {
		contrib := req.PaidBy[user]
		owed := req.SplitBetween[user]

		if contrib == 0 && owed == 0 {
			continue
		}

		_, err := stmt.Exec(expenseID, user, contrib, owed)
		if err != nil {
			log.Println("Insert bill_split failed:", err)
			tx.Rollback()
			http.Error(w, `{"status":false,"message":"Failed to insert bill_split"}`, http.StatusInternalServerError)
			return
		}
	}

	// Step 5: Call OptimiseBalances to update balances after the expense
	netChanges := map[string]float64{}
	// Populate netChanges map with appropriate changes based on PaidBy and SplitBetween
	for user, paidAmount := range req.PaidBy {
		netChanges[user] = netChanges[user] + paidAmount
	}
	for user, owedAmount := range req.SplitBetween {
		netChanges[user] = netChanges[user] - owedAmount
	}

	err = OptimiseBalances(tx, req.GroupID, netChanges) // Use the same transaction here
	if err != nil {
		log.Println("Error optimizing balances:", err)
		tx.Rollback()
		http.Error(w, `{"status":false,"message":"Failed to optimize balances"}`, http.StatusInternalServerError)
		return
	}

	// Final commit at the end of the function
	err = tx.Commit()
	if err != nil {
		log.Println("Failed to commit transaction:", err)
		http.Error(w, `{"status":false,"message":"Failed to commit transaction"}`, http.StatusInternalServerError)
		return
	}

	// Respond with success message
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(AddExpenseResponse{
		Status:  true,
		Message: "Expense added successfully",
	})

	if WS != nil{
		payload, _ := json.Marshal(map[string]interface{}{
			"type": "expense_added",
			"group_id": req.GroupID,
			"by": req.Username,
			"amount": req.Amount,
		})
		pubsub.NotifyExpense(WS, payload)
	}
}


// OptimiseBalances now takes tx (transaction) as an argument
func OptimiseBalances(tx *sql.Tx, groupID string, netChanges map[string]float64) error {
	// No need to start a new transaction here, just use the passed tx

	// Step 1: Get all balances for the group
	rows, err := tx.Query(`
		SELECT from_user, to_user, amount
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
		return utils.IntComparator(b, a) // reverse comparison
	}

	// Create TreeMaps for debtors and creditors
	debtors := treemap.NewWith(utils.IntComparator)           // ascending order for debtors
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
		creditAmount := cKey.(int)
		creditUser := cVal.(string)

		// Get top debtor (most negative balance)
		dKey, dVal := debtors.Min() // key: amount (negative), val: username
		debitAmount := dKey.(int)
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
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}