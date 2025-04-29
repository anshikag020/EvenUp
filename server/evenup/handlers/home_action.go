package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"

	//"log"
	"github.com/anshikag020/EvenUp/server/evenup/config"
	"github.com/anshikag020/EvenUp/server/evenup/middleware"

	//"golang.org/x/crypto/bcrypt"

	"github.com/google/uuid"
	"log"
)

func GetUserDetails (w http.ResponseWriter, r *http.Request) {
    username, ok := middleware.GetUsernameFromContext(r)
    if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
        return
    }

	// Start a transaction
	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	var email, name string
	err = tx.QueryRow("SELECT email, name FROM users WHERE username=$1", username).Scan(&email, &name)
	if err != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	if err := tx.Commit(); err != nil {
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": true,
		"email":  email,
		"name":   name,
	})
}

func CreateGroup(w http.ResponseWriter, r *http.Request) {

// 	body, _ := io.ReadAll(r.Body)
// fmt.Println(string(body))
// r.Body = io.NopCloser(bytes.NewBuffer(body)) // Reset body so Decoder can read it again


	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}

	var req struct {
		GroupName       string `json:"group_name"`
		GroupDescription string `json:"group_description"`
		GroupType       string `json:"group_type"` // "OTS", "Grey Group", etc.
	}

	// Decode the request body
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "Invalid request format", http.StatusBadRequest)
		return
	}

	// Convert group_type to an integer value
	var groupType int
	switch req.GroupType {
	case "OTS Group":
		groupType = 0
	case "Grey Group":
		groupType = 1
	case "Normal Group":
		groupType = 2
	default:
		http.Error(w, "Invalid group type", http.StatusBadRequest)
		return
	}

    // Begin a transaction
	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Failed to begin transaction", http.StatusInternalServerError)
		return
	}

	// Insert the group into the database
	var groupID uuid.UUID
	err = tx.QueryRow(
		"INSERT INTO groups (group_name, group_description, group_type, admin_username) "+
			"VALUES ($1, $2, $3, $4) RETURNING group_id",
		req.GroupName, req.GroupDescription, groupType, username,
	).Scan(&groupID)
	if err != nil {
		tx.Rollback()
		http.Error(w, "Failed to create group", http.StatusInternalServerError)
		return
	}

	// If the group is OTS, insert the admin into the ots_group_participants table
	if groupType == 0 {
		_, err = tx.Exec(
			"INSERT INTO ots_group_participants (group_id, user_name) VALUES ($1, $2)",
			groupID, username,
		)
		if err != nil {
			tx.Rollback()
			log.Println("Error inserting into ots_group_participants:", err)
			http.Error(w, "Failed to add admin to OTS participants", http.StatusInternalServerError)
			return
		}
	}

	// Insert the admin into the group_participants table
	_, err = tx.Exec(
		"INSERT INTO group_participants (group_id, participant) VALUES ($1, $2)",
		groupID, username,
	)
	if err != nil {
		tx.Rollback()
		http.Error(w, "Failed to add admin to group participants", http.StatusInternalServerError)
		return
	}

	// Commit the transaction
	err = tx.Commit()
	if err != nil {
		http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
		return
	}

	// Return success response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"message": "Group created successfully",
	})
}


// TODO: if a private split already exists, return an error
// TODO: remove description from the request
func CreatePrivateSplit(w http.ResponseWriter, r *http.Request) {
	// Parse request body
	var req struct {
		Username2        string `json:"username_2"`
		// GroupDescription string `json:"group_description"`
	}
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	username, ok := middleware.GetUsernameFromContext(r)
    if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
        return
    }

    // Check if both usernames are the same
    if username == req.Username2 {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Cannot create private-split with yourself",
		})
		return
	}

	// Start transaction
	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Failed to start transaction", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback() // rollback on any failure

	var exists int

	// Check if both users exist
	for _, user := range []string{username, req.Username2} {
		err = tx.QueryRow("SELECT COUNT(*) FROM users WHERE username = $1", user).Scan(&exists)
		if err != nil || exists == 0 {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"status":  false,
				"message": fmt.Sprintf("User not found: %s", user),
			})
			return
		}
	}

	// Create group name
	groupName := fmt.Sprintf("%s-%s", username, req.Username2)

	// Insert into groups table
	var groupID uuid.UUID
	err = tx.QueryRow(`
		INSERT INTO groups (group_name, group_description, group_type, admin_username)
		VALUES ($1, $2, 3, $3) RETURNING group_id
	`, groupName, "This is a Private Split", username).Scan(&groupID)
	if err != nil {
		http.Error(w, "Failed to create group", http.StatusInternalServerError)
		return
	}

	// Insert participants
	for _, participant := range []string{username, req.Username2} {
		_, err = tx.Exec(`
			INSERT INTO group_participants (group_id, participant)
			VALUES ($1, $2)
		`, groupID, participant)
		if err != nil {
			http.Error(w, "Failed to add participants", http.StatusInternalServerError)
			return
		}
	}

	// Commit transaction
	if err = tx.Commit(); err != nil {
		http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
		return
	}

	// Send success response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"message": "Private-Split created successfully",
	})
}


func JoinGroup(w http.ResponseWriter, r *http.Request) {
	// Parse request body

	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}


	var req struct {
		InviteCode string `json:"invite_code"`
	}
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	
	// Start transaction
	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Failed to start transaction", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	var groupID uuid.UUID
	var groupType int

	// Check if invite code exists and get group info
	err = tx.QueryRow(`
		SELECT group_id, group_type FROM groups WHERE invite_code = $1
	`, req.InviteCode).Scan(&groupID, &groupType)

	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Invalid invite code",
		})
		return
	}

	// Disallow joining private-split groups
	if groupType == 3 {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Cannot join Private-Split group",
		})
		return
	}

	// Check if user is already a participant in group_participants
	var exists int
	err = tx.QueryRow(`
		SELECT COUNT(*) FROM group_participants WHERE group_id = $1 AND participant = $2
	`, groupID, username).Scan(&exists)
	if err != nil {
		http.Error(w, "Failed to check existing membership", http.StatusInternalServerError)
		return
	}
	if exists > 0 {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "User already part of the group",
		})
		return
	}

	// Add to group_participants
	_, err = tx.Exec(`
		INSERT INTO group_participants (group_id, participant)
		VALUES ($1, $2)
	`, groupID, username)
	if err != nil {
		log.Println("Error inserting into group_participants:", err)
		http.Error(w, "Failed to add to group_participants", http.StatusInternalServerError)
		return
	}

	// If OTS group, add to ots_group_participants
	if groupType == 0 {
		_, err = tx.Exec(`
			INSERT INTO ots_group_participants (group_id, user_name)
			VALUES ($1, $2)
		`, groupID, username)
		if err != nil {
			http.Error(w, "Failed to add to ots_group_participants", http.StatusInternalServerError)
			return
		}
	}

	// Commit transaction
	if err = tx.Commit(); err != nil {
		http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
		return
	}

	// Success response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"message": "Group joined successfully",
	})
}


func GetTransactionHistory(w http.ResponseWriter, r *http.Request) {
    // Parse request body
    username, ok := middleware.GetUsernameFromContext(r)
    if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
        return
    }

    // Query the transaction history for the user
    rows, err := config.DB.Query(`
        SELECT 
            transaction_id, 
            CASE 
                WHEN sender = $1 THEN receiver 
                WHEN receiver = $1 THEN sender
            END AS other_user,
            CASE 
                WHEN sender = $1 THEN TRUE 
                WHEN receiver = $1 THEN FALSE
            END AS is_sender,
            amount,
            timestamp
        FROM completed_transactions
        WHERE sender = $1 OR receiver = $1;
    `, username)
    if err != nil {
        http.Error(w, "Failed to fetch transaction history", http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    // Prepare the transactions slice
    var transactions []map[string]interface{}
    
    for rows.Next() {
        var transactionID uuid.UUID
        var otherUser string
        var isSender bool
        var amount float64
        var timestamp string // Add a timestamp field to capture the transaction timestamp

        err := rows.Scan(&transactionID, &otherUser, &isSender, &amount, &timestamp)
        if err != nil {
            http.Error(w, "Failed to scan transaction", http.StatusInternalServerError)
            return
        }

        transactions = append(transactions, map[string]interface{}{
            "transaction_id": transactionID.String(),
            "other_user":     otherUser,
            "is_sender":      isSender,
            "amount":         amount,
            "timestamp":      timestamp, // Include the timestamp in the response
        })
    }

    if err = rows.Err(); err != nil {
        http.Error(w, "Error occurred while fetching rows", http.StatusInternalServerError)
        return
    }

    // Send the response
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "status":      true,
        "transactions": transactions,
    })
}
