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
	"database/sql"
	"errors"
	"github.com/anshikag020/EvenUp/server/evenup/middleware"
	"time"
	"github.com/google/uuid"
	"github.com/anshikag020/EvenUp/server/evenup/services"
	"math"
	"sort"
)

type AddExpenseRequest struct {
	GroupID      string             `json:"group_id"`
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

type party struct {
    User   string
    Amount float64
}

// and use NewWith(utils.CompositeComparator)…


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

	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		json.NewEncoder(w).Encode(AddExpenseResponse{Status:false, Message:"User not authorized"})
		return
	}

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

	// Step 1.5: Check if group is OTS and confirmed
	var groupType int
	err = tx.QueryRow(`SELECT group_type FROM groups WHERE group_id = $1`, req.GroupID).Scan(&groupType)
	if err != nil {
		log.Println("Failed to get group type:", err)
		json.NewEncoder(w).Encode(AddExpenseResponse{
			Status:  false,
			Message: "Internal server error",
		})
		responded = true
		return
	}

	if groupType == 0 {
		var confirmed bool
		err = tx.QueryRow(`SELECT confirmed FROM ots_group_participants WHERE group_id = $1 AND user_name = $2`, req.GroupID, username).Scan(&confirmed)
		if err != nil {
			if err == sql.ErrNoRows {
				json.NewEncoder(w).Encode(AddExpenseResponse{
					Status:  false,
					Message: "OTS group confirmation info not found",
				})
			} else {
				log.Println("Failed to get OTS confirmation:", err)
				json.NewEncoder(w).Encode(AddExpenseResponse{
					Status:  false,
					Message: "Internal server error",
				})
			}
			err = errors.New("OTS group confirmation check failed")
			responded = true
			return
		}

		if confirmed {
			json.NewEncoder(w).Encode(AddExpenseResponse{
				Status:  false,
				Message: "Expenses cannot be added to this group anymore",
			})
			err = errors.New("OTS group already confirmed")
			responded = true
			return
		}
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
	`, req.GroupID, req.Description, tagInt, username, req.Amount).Scan(&expenseID)
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
	// print netchanges for each user
	log.Println("Net changes for each user:", netChanges)
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
	go func() {
		involved := map[string]bool{}
		for u := range req.PaidBy {
			if u != username {
				involved[u] = true
			}
		}
		for u := range req.SplitBetween {
			if u != username {
				involved[u] = true
			}
		}
	
		if len(involved) == 0 {
			return
		}
		
		var groupName string
		if err := config.DB.QueryRow(
			`SELECT group_name FROM groups WHERE group_id=$1`,
			req.GroupID,
		).Scan(&groupName); err != nil {
			log.Println("could not load group_name for email:", err)
			groupName = req.GroupID // fallback
		}

		// Fetch emails of involved users
		usernames := make([]string, 0, len(involved))
		for u := range involved {
			usernames = append(usernames, u)
		}
		expenseTime := time.Now().Format("02 Jan 2006 15:04")
	
		query := `
			SELECT username, name, email FROM users
			WHERE username = ANY($1)
		`
		rows, err := config.DB.Query(query, pq.Array(usernames))
		if err != nil {
			log.Println("fetch user emails for expense notification:", err)
			return
		}
		defer rows.Close()
	
		subject := fmt.Sprintf("New Expense in Group %s", groupName)
	
		for rows.Next() {
			var uname, fullName, email string
			if err := rows.Scan(&uname, &fullName, &email); err != nil {
				log.Println("scan email row:", err)
				continue
			}
	
			contributed := req.PaidBy[uname]
			owed := req.SplitBetween[uname]
	
			body := fmt.Sprintf(
				`Hi %s,
				
				%s just added a new expense in group %s.
				
				Description  : %s
				Total amount : ₹%.2f
				Date & time  : %s
				
				Your share
				───────────
				Contributed  : ₹%.2f
				Owe          : ₹%.2f
				
				Open Evenup to view full details.
				
				Thanks,
				Evenup Team`,
						fullName,
						username, groupName,
						req.Description,
						req.Amount,
						expenseTime,
						contributed,
						owed,
					)
	
			// Send the email
			if mailErr := services.SendMail([]string{email}, subject, body); mailErr != nil {
				log.Printf("Email to %s failed: %v\n", uname, mailErr)
			}
		}
	}()
	

	// Send WebSocket Notification
	if WS != nil {
		payload, _ := json.Marshal(map[string]interface{}{
			"type":     "expense_added",
			"group_id": req.GroupID,
			"by":       username,
			"amount":   req.Amount,
		})
		pubsub.NotifyExpense(WS, payload)
	}
}

func OptimiseBalances(tx *sql.Tx, groupID string, netChanges map[string]float64) error {
    // 1) Load existing balances
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

    userNet := make(map[string]float64)
    for rows.Next() {
        var from, to string
        var amt float64
        if err := rows.Scan(&from, &to, &amt); err != nil {
            log.Println("Error scanning balance row:", err)
            return err
        }
        userNet[from] -= amt
        userNet[to]   += amt
    }
    if err := rows.Err(); err != nil {
        log.Println("Error iterating balances:", err)
        return err
    }

    // 2) Wipe out old balances
    if _, err := tx.Exec(`
        DELETE FROM balances
        WHERE group_id = $1
    `, groupID); err != nil {
        log.Println("Error deleting balances:", err)
        return err
    }

    // 3) Apply in-memory netChanges
    for user, delta := range netChanges {
        userNet[user] += delta
    }

    // 4) Build debtor/creditor heaps
    //    debtors: ascending (most-negative first)
    // Build slices
    var creditors []party
    var debtors  []party
    for user, bal := range userNet {
        if bal > 0 {
            creditors = append(creditors, party{user, bal})
        } else if bal < 0 {
            debtors = append(debtors, party{user, bal})
        }
    }

    // Sort creditors descending, debtors ascending
    sort.Slice(creditors, func(i, j int) bool {
        return creditors[i].Amount > creditors[j].Amount
    })
    sort.Slice(debtors, func(i, j int) bool {
        return debtors[i].Amount < debtors[j].Amount
    })

    i, j, count := 0, 0, 0
    for i < len(creditors) && j < len(debtors) {
        cr := &creditors[i]
        db := &debtors[j]

        settle := math.Min(cr.Amount, -db.Amount)

        // insert into balances table
        if _, err := tx.Exec(`
            INSERT INTO balances (group_id, sender, receiver, amount)
            VALUES ($1, $2, $3, $4)
        `, groupID, db.User, cr.User, settle); err != nil {
            return err
        }

        cr.Amount -= settle
        db.Amount += settle
        count++

        if cr.Amount == 0 {
            i++
        }
        if db.Amount == 0 {
            j++
        }
    }

    log.Println("Settled transactions count:", count)
    return nil
}

type deleteExpenseRequest struct {
	ExpenseID string `json:"expense_id"`
}

type deleteExpenseResponse struct {
	Status  bool   `json:"status"`
	Message string `json:"message"`
}

// -------------------- HTTP handler --------------------

// DELETE /api/delete_expense
func DeleteExpenseHandler(w http.ResponseWriter, r *http.Request) {
	var req deleteExpenseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respond(w, false, "Malformed JSON body")
		return
	}
	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		respond(w, false, "User not authorized")
		return
	}
	if req.ExpenseID == "" {
		respond(w, false, "expense_id is required")
		return
	}

	tx, err := config.DB.Begin()
	if err != nil {
		log.Println("could not start tx:", err)
		respond(w, false, "Internal server error")
		return
	}
	// make sure we leave the DB in a clean state
	defer func() {
		// if Commit was not reached, tx.Rollback returns sql.ErrTxDone (safe to ignore)
		_ = tx.Rollback()
	}()

	//-------------------------------------------------------
	// 1. locate the group that owns this expense
	//-------------------------------------------------------
	var groupID string
	err = tx.QueryRow(`
		SELECT group_id
		FROM expenses
		WHERE expense_id = $1
	`, req.ExpenseID).Scan(&groupID)

	switch {
	case errors.Is(err, sql.ErrNoRows):
		respond(w, false, "Expense not found")
		return
	case err != nil:
		log.Println("query group_id:", err)
		respond(w, false, "Internal server error")
		return
	}
	// ------------------------------------------------------
// 1.5 Check if group is OTS and already confirmed
// ------------------------------------------------------
	var groupType int
	err = tx.QueryRow(`
		SELECT group_type FROM groups
		WHERE group_id = $1
	`, groupID).Scan(&groupType)
	if err != nil {
		log.Println("group type lookup:", err)
		respond(w, false, "Internal server error")
		return
	}

	if groupType == 0 {
		var confirmed bool
		err = tx.QueryRow(`
			SELECT confirmed FROM ots_group_participants
			WHERE group_id = $1 AND user_name = $2
		`, groupID, username).Scan(&confirmed)


		if err != nil {
			if err == sql.ErrNoRows {
				respond(w, false, "OTS group confirmation info not found")
			} else {
				log.Println("OTS confirmation fetch:", err)
				respond(w, false, "Internal server error")
			}
			return
		}

		if confirmed {
			respond(w, false, "Expenses cannot be deleted anymore")
			return
		}
	}


	//-------------------------------------------------------
	// 2. make sure the requesting user is in the group
	//-------------------------------------------------------
	if err = tx.QueryRow(`
		SELECT EXISTS (
			SELECT 1
			FROM group_participants
			WHERE group_id = $1 AND participant = $2
		)
	`, groupID, username).Scan(&ok); err != nil {
		log.Println("user membership check:", err)
		respond(w, false, "Internal server error")
		return
	}
	if !ok {
		respond(w, false, "You are not a member of this group")
		return
	}

	//-------------------------------------------------------
	// 3. gather bill_split rows for the expense
	//-------------------------------------------------------
	rows, err := tx.Query(`
		SELECT username, amount_contributed, amount_owed
		FROM bill_split
		WHERE expense_id = $1
	`, req.ExpenseID)
	if err != nil {
		log.Println("bill_split fetch:", err)
		respond(w, false, "Internal server error")
		return
	}
	defer rows.Close()
	type userSplit struct {
		Owed        float64
		Contributed float64
	}
	
	userSplits := make(map[string]userSplit)
	
	netChanges := make(map[string]float64) // username -> delta
	involved   := make([]string, 0, 8)     // to test membership later

	for rows.Next() {
		var user string
		var contributed, owed float64
		if err = rows.Scan(&user, &contributed, &owed); err != nil {
			log.Println("scan bill_split:", err)
			respond(w, false, "Internal server error")
			return
		}
		// record user so we can verify membership in step 4
		involved = append(involved, user)

		// *** reverse the original posting ***
		// original posting was: delta = contributed - owed
		// so to undo:          delta = owed - contributed
		netChanges[user] += owed - contributed
	}
	if err = rows.Err(); err != nil {
		log.Println("iterate bill_split:", err)
		respond(w, false, "Internal server error")
		return
	}

	//-------------------------------------------------------
	// 4. ensure every involved user is still in the group
	//-------------------------------------------------------
	for _, u := range involved {
		if err = tx.QueryRow(`
			SELECT EXISTS (
				SELECT 1
				FROM group_participants
				WHERE group_id = $1 AND participant = $2
			)
		`, groupID, u).Scan(&ok); err != nil {
			log.Println("membership check:", err)
			respond(w, false, "Internal server error")
			return
		}
		if !ok {
			respond(w, false, "Cannot delete expense. Some member has left the group")
			return
		}
	}

	//-------------------------------------------------------
	// 5. actually delete the expense (CASCADE removes bill_split rows)
	//-------------------------------------------------------
	if _, err = tx.Exec(`
		DELETE FROM expenses
		WHERE expense_id = $1
	`, req.ExpenseID); err != nil {
		log.Println("delete expenses row:", err)
		respond(w, false, "Internal server error")
		return
	}

	//-------------------------------------------------------
	// 6. re-optimise balances inside the SAME tx
	//-------------------------------------------------------
	if err = OptimiseBalances(tx, groupID, netChanges); err != nil {
		log.Println("optimise balances:", err)
		respond(w, false, "Internal server error")
		return
	}

	//-------------------------------------------------------
	// 7. all good - commit!
	//-------------------------------------------------------
	if err = tx.Commit(); err != nil {
		log.Println("commit failed:", err) // Rollback in defer will be a no-op
		respond(w, false, "Internal server error")
		return
	}
	go func() {
		involvedMap := make(map[string]bool)
		for _, user := range involved {
			if user != username {
				involvedMap[user] = true
			}
		}
	
		if len(involvedMap) == 0 {
			return
		}
	
		usernames := make([]string, 0, len(involvedMap))
		for u := range involvedMap {
			usernames = append(usernames, u)
		}
	
		// Fetch emails
		rows, err := config.DB.Query(`
			SELECT username, email FROM users
			WHERE username = ANY($1)
		`, pq.Array(usernames))
		if err != nil {
			log.Println("fetch user emails for deletion notification:", err)
			return
		}
		defer rows.Close()
	
		subject := "Expense Deleted"
	
		for rows.Next() {
			var uname, email string
			if err := rows.Scan(&uname, &email); err != nil {
				log.Println("scan user email:", err)
				continue
			}
	
			split := userSplits[uname]
	
			body := fmt.Sprintf(
				"Hi %s,\n\n%s has deleted an expense (ID: %s) in one of your groups.\nYou had contributed: ₹%.2f\nYou had owed: ₹%.2f\n\nPlease check the app for updated balances.\n\nThanks,\nEvenup",
				uname, username, req.ExpenseID, split.Contributed, split.Owed,
			)
	
			if mailErr := services.SendMail([]string{email}, subject, body); mailErr != nil {
				log.Printf("Email to %s failed: %v\n", uname, mailErr)
			}
		}
	}()
	
	respond(w, true, "Expense deleted successfully")

	if WS != nil {
		payload, _ := json.Marshal(map[string]interface{}{
			"type":      "expense_deleted",
			"group_id":  groupID,
			"by":        username,
			"expense_id": req.ExpenseID,
		})
		pubsub.NotifyExpense(WS, payload)
	}
}

// -------------------- helpers --------------------

func respond(w http.ResponseWriter, status bool, msg string) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(deleteExpenseResponse{
		Status:  status,
		Message: msg,
	})
}



func intToTag(t int) string {
	switch t {
	case 0:
		return "food"
	case 1:
		return "transport"
	case 2:
		return "entertainment"
	case 3:
		return "shopping"
	case 4:
		return "bills"
	default:
		return "other"
	}
}

// --------------------------------------------------------------------
// GET /api/get_expense_details
type getExpenseDetailsReq struct {
	ExpenseID string `json:"expense_id"`
}

type getExpenseDetailsResp struct {
	Status       bool               `json:"status"`
	Description  string             `json:"description,omitempty"`
	Tag          string             `json:"tag,omitempty"`
	LastModified string             `json:"last_modified,omitempty"`
	PaidBy       map[string]float64 `json:"paid_by,omitempty"`
	OwedBy       map[string]float64 `json:"owed_by,omitempty"`
	Amount       float64            `json:"amount,omitempty"`
	Message      string             `json:"message,omitempty"` // only on failures
}


	
func GetExpenseDetails(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	//-----------------------------------------------------------------
	// 0.  auth  -------------------------------------------------------
	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		json.NewEncoder(w).Encode(getExpenseDetailsResp{
			Status:  false,
			Message: "User not authorized",
		})
		return
	}

	//-----------------------------------------------------------------
	// 1.  parse JSON body  -------------------------------------------
	var req getExpenseDetailsReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.ExpenseID == "" {
		json.NewEncoder(w).Encode(getExpenseDetailsResp{
			Status:  false,
			Message: "Malformed JSON body",
		})
		return
	}

	//-----------------------------------------------------------------
	// 2.  open tx (read-only)  ---------------------------------------
	tx, err := config.DB.Begin()
	if err != nil {
		log.Println("could not start tx:", err)
		json.NewEncoder(w).Encode(getExpenseDetailsResp{
			Status:  false,
			Message: "Internal server error",
		})
		return
	}
	defer tx.Rollback()

	//-----------------------------------------------------------------
	// 3.  fetch expense row  -----------------------------------------
	var (
		groupID           string
		description       string
		tagInt            int
		timestamp         time.Time
		totalAmount       float64
	)
	err = tx.QueryRow(`
		SELECT group_id, description, tag, timestamp, amount
		FROM expenses
		WHERE expense_id = $1
	`, req.ExpenseID).Scan(&groupID, &description, &tagInt, &timestamp, &totalAmount)

	switch {
	case errors.Is(err, sql.ErrNoRows):
		json.NewEncoder(w).Encode(getExpenseDetailsResp{
			Status:  false,
			Message: "Expense not found",
		})
		return
	case err != nil:
		log.Println("query expense:", err)
		json.NewEncoder(w).Encode(getExpenseDetailsResp{
			Status:  false,
			Message: "Internal server error",
		})
		return
	}

	//-----------------------------------------------------------------
	// 4.  ensure caller is still in that group -----------------------
	var inGroup bool
	if err = tx.QueryRow(`
		SELECT EXISTS (
			SELECT 1
			FROM group_participants
			WHERE group_id = $1 AND participant = $2
		)
	`, groupID, username).Scan(&inGroup); err != nil || !inGroup {
		json.NewEncoder(w).Encode(getExpenseDetailsResp{
			Status:  false,
			Message: "You are not a member of this group",
		})
		return
	}

	//-----------------------------------------------------------------
	// 5.  gather bill_split rows  ------------------------------------
	rows, err := tx.Query(`
		SELECT username, amount_contributed, amount_owed
		FROM bill_split
		WHERE expense_id = $1
	`, req.ExpenseID)
	if err != nil {
		log.Println("bill_split:", err)
		json.NewEncoder(w).Encode(getExpenseDetailsResp{
			Status:  false,
			Message: "Internal server error",
		})
		return
	}
	defer rows.Close()

	paidBy := make(map[string]float64)
	owedBy := make(map[string]float64)

	for rows.Next() {
		var u string
		var contrib, owed float64
		if err = rows.Scan(&u, &contrib, &owed); err != nil {
			log.Println("scan:", err)
			json.NewEncoder(w).Encode(getExpenseDetailsResp{
				Status:  false,
				Message: "Internal server error",
			})
			return
		}
		if contrib != 0 {
			paidBy[u] = contrib
		}
		if owed != 0 {
			owedBy[u] = owed
		}
	}
	if err = rows.Err(); err != nil {
		log.Println("rows err:", err)
		json.NewEncoder(w).Encode(getExpenseDetailsResp{
			Status:  false,
			Message: "Internal server error",
		})
		return
	}

	//-----------------------------------------------------------------
	// 6.  success  ----------------------------------------------------
	json.NewEncoder(w).Encode(getExpenseDetailsResp{
		Status:       true,
		Description:  description,
		Tag:          intToTag(tagInt),
		LastModified: timestamp.Format("02 Jan 2006 15:04"),
		PaidBy:       paidBy,
		OwedBy:       owedBy,
		Amount:       totalAmount,
	})
}
// Format("02 Jan 2006 15:04")



type Expense struct {
    ExpenseID    string             `json:"expense_id"`
    Description  string             `json:"description"`
    Tag          string             `json:"tag"`
    LastModified string             `json:"last_modified"` // added_by user
    PaidBy       map[string]float64 `json:"paid_by"`
    OwedBy       map[string]float64 `json:"owed_by"`
    Amount       float64            `json:"amount"`
}

type GetExpensesRequest struct {
    GroupID string `json:"group_id"`
}

type GetExpensesResponse struct {
    Status   bool      `json:"status"`
    Expenses []Expense `json:"expenses"`
    Message  string    `json:"message,omitempty"`
}


// GetExpenses returns the list of expenses for a group,
// filtering by the current user for grey‐type groups.
func GetExpenses(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")

    // 1) Auth
    username, ok := middleware.GetUsernameFromContext(r)
    if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
        return
    }

    // 2) Decode request
    var req GetExpensesRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        w.WriteHeader(http.StatusBadRequest)
        json.NewEncoder(w).Encode(GetExpensesResponse{
            Status:  false,
            Message: "Malformed request body",
        })
        return
    }

    // 3) Validate group_id
    groupUUID, err := uuid.Parse(req.GroupID)
    if err != nil {
        w.WriteHeader(http.StatusBadRequest)
        json.NewEncoder(w).Encode(GetExpensesResponse{
            Status:  false,
            Message: "Invalid group_id format",
        })
        return
    }

    // 4) Begin transaction
    tx, err := config.DB.Begin()
    if err != nil {
        log.Println("could not start tx:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }
    defer tx.Rollback()

    // 5) Fetch group_type
    var groupType int
    if err := tx.QueryRow(`
        SELECT group_type
        FROM groups
        WHERE group_id = $1
    `, groupUUID).Scan(&groupType); err != nil {
        if err == sql.ErrNoRows {
            json.NewEncoder(w).Encode(GetExpensesResponse{
                Status:  false,
                Message: "Group not found",
            })
            return
        }
        log.Println("query group_type:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    // 6) First pass: gather all expense metadata
    var metaRows *sql.Rows
    if groupType == 1 {
        // Grey group: only expenses this user touched
        metaRows, err = tx.Query(`
            SELECT e.expense_id, e.description, e.tag, e.added_by, e.amount
            FROM expenses e
            JOIN bill_split bs ON bs.expense_id = e.expense_id
            WHERE e.group_id = $1
              AND bs.username = $2
              AND (bs.amount_contributed <> 0 OR bs.amount_owed <> 0)
            ORDER BY e.timestamp DESC
        `, groupUUID, username)
    } else {
        // Others: all expenses
        metaRows, err = tx.Query(`
            SELECT expense_id, description, tag, added_by, amount
            FROM expenses
            WHERE group_id = $1
            ORDER BY timestamp DESC
        `, groupUUID)
    }
    if err != nil {
        log.Println("query expenses:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    // Read into a slice, then close rows
    var prelim []Expense
    for metaRows.Next() {
        var e Expense
        var tagInt int
        if err := metaRows.Scan(
            &e.ExpenseID,
            &e.Description,
            &tagInt,
            &e.LastModified,
            &e.Amount,
        ); err != nil {
            metaRows.Close()
            log.Println("scan expenses:", err)
            http.Error(w, "Server error", http.StatusInternalServerError)
            return
        }
        e.Tag = intToTag(tagInt)
        prelim = append(prelim, e)
    }
    if err := metaRows.Err(); err != nil {
        metaRows.Close()
        log.Println("iterate expenses:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }
    metaRows.Close()

    // 7) Second pass: for each expense, fetch its bill_split rows
    for i := range prelim {
        e := &prelim[i]
        splitRows, err := tx.Query(`
            SELECT username, amount_contributed, amount_owed
            FROM bill_split
            WHERE expense_id = $1
        `, e.ExpenseID)
        if err != nil {
            log.Println("query bill_split:", err)
            http.Error(w, "Server error", http.StatusInternalServerError)
            return
        }

        e.PaidBy = make(map[string]float64)
        e.OwedBy = make(map[string]float64)
        for splitRows.Next() {
            var user string
            var contrib, owed float64
            if err := splitRows.Scan(&user, &contrib, &owed); err != nil {
                splitRows.Close()
                log.Println("scan bill_split:", err)
                http.Error(w, "Server error", http.StatusInternalServerError)
                return
            }
            if contrib != 0 {
                e.PaidBy[user] = contrib
            }
            if owed != 0 {
                e.OwedBy[user] = owed
            }
        }
        splitRows.Close()
        if err := splitRows.Err(); err != nil {
            log.Println("iterate bill_split:", err)
            http.Error(w, "Server error", http.StatusInternalServerError)
            return
        }
    }

    // 8) Commit & reply
    if err := tx.Commit(); err != nil {
        log.Println("commit failed:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    json.NewEncoder(w).Encode(GetExpensesResponse{
        Status:   true,
        Expenses: prelim,
    })
}


func EditExpenseHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}

	var req struct {
		ExpenseID     string             `json:"expense_id"`
		Description   string             `json:"description"`
		Amount        float64            `json:"amount"`
		Tag           string             `json:"tag"`
		SplitBetween  map[string]float64 `json:"split_between"`
		PaidBy        map[string]float64 `json:"paid_by"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Malformed request body",
		})
		return
	}

	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// 1. Get group_id from expense
	var groupID string
	err = tx.QueryRow(`SELECT group_id FROM expenses WHERE expense_id = $1`, req.ExpenseID).Scan(&groupID)
	if err == sql.ErrNoRows {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Expense not found",
		})
		return
	} else if err != nil {
		log.Println("query group_id:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// 1.5: Check if the group is an OTS group and already confirmed
	var groupType int
	err = tx.QueryRow(`SELECT group_type FROM groups WHERE group_id = $1`, groupID).Scan(&groupType)
	if err != nil {
		log.Println("fetch group_type:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	if groupType == 0 {
		var confirmed bool
		err = tx.QueryRow(`SELECT confirmed FROM ots_group_participants WHERE group_id = $1 AND user_name=$2`, groupID, username).Scan(&confirmed)
		if err != nil {
			if err == sql.ErrNoRows {
				json.NewEncoder(w).Encode(map[string]interface{}{
					"status":  false,
					"message": "OTS group confirmation status not found",
				})
			} else {
				log.Println("fetch ots_groups.confirmed:", err)
				http.Error(w, "Server error", http.StatusInternalServerError)
			}
			return
		}

		if confirmed {
			json.NewEncoder(w).Encode(map[string]interface{}{
				"status":  false,
				"message": "Expenses cannot be edited anymore",
			})
			return
		}
	}

	// 2. Get all members currently in the group
	groupMembers := map[string]bool{}
	rows, err := tx.Query(`SELECT participant FROM group_participants WHERE group_id = $1`, groupID)
	if err != nil {
		log.Println("fetch group participants:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()
	for rows.Next() {
		var user string
		_ = rows.Scan(&user)
		groupMembers[user] = true
	}

	// 3. Check all users in bill split are still in group
	involved := make(map[string]bool)
	for u := range req.SplitBetween {
		involved[u] = true
	}
	for u := range req.PaidBy {
		involved[u] = true
	}
	for u := range involved {
		if !groupMembers[u] {
			json.NewEncoder(w).Encode(map[string]interface{}{
				"status":  false,
				"message": "User '" + u + "' is not part of the group anymore",
			})
			return
		}
	}

	// 4. Fetch old bill_split and calculate netChanges
	oldSplits := make(map[string]float64)
	rows, err = tx.Query(`
		SELECT username, amount_contributed, amount_owed
		FROM bill_split
		WHERE expense_id = $1
	`, req.ExpenseID)
	if err != nil {
		log.Println("fetch old bill_split:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	for rows.Next() {
		var user string
		var contrib, owed float64
		if err := rows.Scan(&user, &contrib, &owed); err != nil {
			log.Println("scan old bill_split:", err)
			http.Error(w, "Server error", http.StatusInternalServerError)
			return
		}
		oldSplits[user] = contrib - owed
	}

	// 5. Delete old bill_split
	_, err = tx.Exec(`DELETE FROM bill_split WHERE expense_id = $1`, req.ExpenseID)
	if err != nil {
		log.Println("delete old bill_split:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// 6. Insert new bill_split
	stmt, err := tx.Prepare(`
		INSERT INTO bill_split (expense_id, username, amount_contributed, amount_owed)
		VALUES ($1, $2, $3, $4)
	`)
	if err != nil {
		log.Println("prepare insert bill_split:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer stmt.Close()

	newSplits := make(map[string]float64)
	for user := range involved {
		contrib := req.PaidBy[user]
		owed := req.SplitBetween[user]
		_, err := stmt.Exec(req.ExpenseID, user, contrib, owed)
		if err != nil {
			log.Println("insert bill_split:", err)
			http.Error(w, "Server error", http.StatusInternalServerError)
			return
		}
		newSplits[user] = contrib - owed
	}

	// 7. Calculate net changes
	netChanges := make(map[string]float64)
	for user := range involved {
		netChanges[user] = newSplits[user] - oldSplits[user]
	}

	// 8. Update expense metadata
	tagInt := mapTagToInt(req.Tag)
	_, err = tx.Exec(`
		UPDATE expenses
		SET description = $1, tag = $2, amount = $3, added_by = $4, timestamp = CURRENT_TIMESTAMP
		WHERE expense_id = $5
	`, req.Description, tagInt, req.Amount, username, req.ExpenseID)
	if err != nil {
		log.Println("update expenses table:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// 9. Optimise balances
	if err := OptimiseBalances(tx, groupID, netChanges); err != nil {
		log.Println("optimise balances:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// 10. Commit
	if err := tx.Commit(); err != nil {
		log.Println("tx commit:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	go func() {
		type userSplit struct {
			Owed        float64
			Contributed float64
		}
	
		// Build involved map excluding editor
		involvedMap := make(map[string]userSplit)
		for user, contrib := range req.PaidBy {
			if user == username {
				continue
			}
			owed := req.SplitBetween[user]
			involvedMap[user] = userSplit{Contributed: contrib, Owed: owed}
		}
		for user, owed := range req.SplitBetween {
			if user == username {
				continue
			}
			if _, exists := involvedMap[user]; !exists {
				contrib := req.PaidBy[user]
				involvedMap[user] = userSplit{Contributed: contrib, Owed: owed}
			}
		}
	
		if len(involvedMap) == 0 {
			return
		}
	
		usernames := make([]string, 0, len(involvedMap))
		for u := range involvedMap {
			usernames = append(usernames, u)
		}
	
		rows, err := config.DB.Query(`
			SELECT username, email FROM users
			WHERE username = ANY($1)
		`, pq.Array(usernames))
		if err != nil {
			log.Println("fetch emails after edit:", err)
			return
		}
		defer rows.Close()
	
		subject := "Expense Updated"
	
		for rows.Next() {
			var uname, email string
			if err := rows.Scan(&uname, &email); err != nil {
				log.Println("scan email:", err)
				continue
			}
	
			split := involvedMap[uname]
			body := fmt.Sprintf(
				"Hi %s,\n\n%s has updated an expense: \"%s\" of ₹%.2f in your group.\nYou now owe: ₹%.2f\nYou contributed: ₹%.2f\n\nCheck the app for details.\n\nThanks,\nEvenup",
				uname, username, req.Description, req.Amount, split.Owed, split.Contributed,
			)
	
			if err := services.SendMail([]string{email}, subject, body); err != nil {
				log.Printf("Failed to send email to %s: %v\n", uname, err)
			}
		}
	}()
	
	if WS != nil {
		payload, _ := json.Marshal(map[string]interface{}{
			"type":      "expense_edited",
			"group_id":  groupID,
			"by":        username,
			"expense_id": req.ExpenseID,
			"amount":    req.Amount,
		})
		pubsub.NotifyExpense(WS, payload)
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"message": "Expense updated successfully",
	})
}
