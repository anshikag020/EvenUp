package handlers
import (
	"database/sql"
	"encoding/json"
	"net/http"
	"log"
	"github.com/anshikag020/EvenUp/server/evenup/config"
	"github.com/anshikag020/EvenUp/server/evenup/middleware"
	"time"
)

func GetInTransitTransactions(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Step 1: Authenticate user
	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}

	// Step 2: Start DB transaction
	tx, err := config.DB.Begin()
	if err != nil {
		log.Println("tx begin:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Step 3: Query intermediate transactions involving the user
	rows, err := tx.Query(`
		SELECT it.transaction_id, it.group_id, it.sender, it.receiver, it.amount, g.group_name
		FROM intermediate_transactions it
		JOIN groups g ON it.group_id = g.group_id
		WHERE it.sender = $1 OR it.receiver = $1
	`, username)
	if err != nil {
		log.Println("query intermediate_transactions:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Step 4: Construct response
	type TransitTx struct {
		TransactionID string  `json:"transaction_id"`
		OtherMember   string  `json:"other_member"`
		IsSender      bool    `json:"is_sender"`
		Amount        float64 `json:"amount"`
		GroupName     string  `json:"group_name"`
	}

	var transactions []TransitTx
	for rows.Next() {
		var txID, groupID, sender, receiver, groupName string
		var amount float64

		if err := rows.Scan(&txID, &groupID, &sender, &receiver, &amount, &groupName); err != nil {
			log.Println("scan error:", err)
			http.Error(w, "Server error", http.StatusInternalServerError)
			return
		}

		isSender := sender == username
		other := receiver
		if !isSender {
			other = sender
		}

		transactions = append(transactions, TransitTx{
			TransactionID: txID,
			OtherMember:   other,
			IsSender:      isSender,
			Amount:        amount,
			GroupName:     groupName,
		})
	}

	if err := tx.Commit(); err != nil {
		log.Println("tx commit:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Step 5: Send response
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":       true,
		"transactions": transactions,
	})
}


func InTransitAcceptHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Step 1: Authenticate user
	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}

	// Step 2: Decode request body
	var req struct {
		TransactionID string `json:"transaction_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.TransactionID == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Invalid request body",
		})
		return
	}

	// Step 3: Begin transaction
	tx, err := config.DB.Begin()
	if err != nil {
		log.Println("tx begin:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Step 4: Fetch transaction from intermediate_transactions
	var groupID, sender, receiver string
	var amount float64
	err = tx.QueryRow(`
		SELECT group_id, sender, receiver, amount
		FROM intermediate_transactions
		WHERE transaction_id = $1
	`, req.TransactionID).Scan(&groupID, &sender, &receiver, &amount)

	if err == sql.ErrNoRows {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Transaction not found",
		})
		return
	} else if err != nil {
		log.Println("query intermediate_transactions:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Make sure current user is the receiver
	if receiver != username {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Only the receiver can accept the transaction",
		})
		return
	}

	// Step 5: Delete from intermediate_transactions
	_, err = tx.Exec(`
		DELETE FROM intermediate_transactions
		WHERE transaction_id = $1
	`, req.TransactionID)
	if err != nil {
		log.Println("delete intermediate:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Step 6: Insert into completed_transactions
	_, err = tx.Exec(`
		INSERT INTO completed_transactions (transaction_id, group_id, sender, receiver, amount)
		VALUES ($1, $2, $3, $4, $5)
	`, req.TransactionID, groupID, sender, receiver, amount)
	if err != nil {
		log.Println("insert completed:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Step 7: Commit transaction
	if err := tx.Commit(); err != nil {
		log.Println("commit:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Step 8: Success response
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"message": "Transaction accepted successfully",
	})
}


func InTransitRejectHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Step 1: Auth
	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}

	// Step 2: Parse request
	var req struct {
		TransactionID string `json:"transaction_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.TransactionID == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Invalid request body",
		})
		return
	}

	// Step 3: Begin transaction
	tx, err := config.DB.Begin()
	if err != nil {
		log.Println("tx begin:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Step 4: Retrieve transaction from intermediate_transactions
	var groupID, sender, receiver string
	var amount float64
	err = tx.QueryRow(`
		SELECT group_id, sender, receiver, amount
		FROM intermediate_transactions
		WHERE transaction_id = $1
	`, req.TransactionID).Scan(&groupID, &sender, &receiver, &amount)

	if err == sql.ErrNoRows {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Transaction not found",
		})
		return
	} else if err != nil {
		log.Println("query intermediate_transactions:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Only receiver is allowed to reject
	if receiver != username {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Only the receiver can reject the transaction",
		})
		return
	}

	// Step 5: Delete from intermediate_transactions
	_, err = tx.Exec(`
		DELETE FROM intermediate_transactions
		WHERE transaction_id = $1
	`, req.TransactionID)
	if err != nil {
		log.Println("delete intermediate_transactions:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Step 6: Restore to balances
	_, err = tx.Exec(`
		INSERT INTO balances (group_id, sender, receiver, amount)
		VALUES ($1, $2, $3, $4)
	`, groupID, sender, receiver, amount)
	if err != nil {
		log.Println("restore to balances:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Step 7: Commit
	if err := tx.Commit(); err != nil {
		log.Println("commit:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Step 8: Success response
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"message": "Transaction rejected successfully",
	})
}

func GetCompletedTransactionsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Step 1: Auth
	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}

	// Step 2: Query completed_transactions
	rows, err := config.DB.Query(`
		SELECT 
			ct.transaction_id, 
			g.group_name,   
			ct.sender, 
			ct.receiver, 
			ct.amount, 
			ct.timestamp
		FROM completed_transactions ct
		JOIN groups g ON ct.group_id = g.group_id
		WHERE ct.sender = $1 OR ct.receiver = $1
		ORDER BY ct.timestamp DESC;

	`, username)
	if err != nil {
		log.Println("query completed_transactions:", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Step 3: Build response
	type Transaction struct {
		TransactionID string    `json:"transaction_id"`
		GroupName       string    `json:"group_name"`
		Sender        string    `json:"sender"`
		Receiver      string    `json:"receiver"`
		Amount        float64   `json:"amount"`
		Timestamp     time.Time `json:"timestamp"`
	}

	var transactions []Transaction
	for rows.Next() {
		var t Transaction
		err := rows.Scan(&t.TransactionID, &t.GroupName, &t.Sender, &t.Receiver, &t.Amount, &t.Timestamp)
		if err != nil {
			log.Println("scan row:", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
		transactions = append(transactions, t)
	}

	if err := rows.Err(); err != nil {
		log.Println("iterate rows:", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Step 4: Return response
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":       true,
		"transactions": transactions,
	})
}

