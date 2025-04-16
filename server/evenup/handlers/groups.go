package handlers

import(
	"net/http"
	"encoding/json"
	"github.com/anshikag020/EvenUp/server/evenup/config"
	"github.com/google/uuid"
	"fmt"
	"log"
	"database/sql"
)

func GetGroups(w http.ResponseWriter, r *http.Request) {
	// Parse request body
	var req struct {
		Username string `json:"username"`
	}
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Query to get all groups the user is a part of
	rows, err := config.DB.Query(`
		SELECT g.group_name, COUNT(gp.participant) AS members, g.group_id
		FROM groups g
		JOIN group_participants gp ON g.group_id = gp.group_id
		WHERE gp.participant = $1
		GROUP BY g.group_name, g.group_id
	`, req.Username)
	if err != nil {
		http.Error(w, "Failed to retrieve groups", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Prepare the response
	var groups []map[string]interface{}
	for rows.Next() {
		var groupName, groupID string
		var members int
		if err := rows.Scan(&groupName, &members, &groupID); err != nil {
			http.Error(w, "Failed to scan group data", http.StatusInternalServerError)
			return
		}
		groups = append(groups, map[string]interface{}{
			"group_name": groupName,
			"members":    members,
			"group_id":   groupID,
		})
	}

	// Check for errors in fetching rows
	if err := rows.Err(); err != nil {
		http.Error(w, "Error in fetching group data", http.StatusInternalServerError)
		return
	}

	// Send success response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": true,
		"groups": groups,
	})
}


func GetGroupDetails(w http.ResponseWriter, r *http.Request) {
	// Extract group_id from URL query parameters
	groupIDStr := r.URL.Query().Get("group_id")
	if groupIDStr == "" {
		http.Error(w, "Missing group_id", http.StatusBadRequest)
		return
	}

	// Validate and convert to UUID
	groupID, err := uuid.Parse(groupIDStr)
	if err != nil {
		http.Error(w, "Invalid group_id format", http.StatusBadRequest)
		return
	}


	// Query group info
	var description, inviteCode string
	var groupType int
	err = config.DB.QueryRow(`
		SELECT group_description, group_type, invite_code
		FROM groups
		WHERE group_id = $1
	`, groupID).Scan(&description, &groupType, &inviteCode)

	// Check if the group was found
	if err != nil {
		// Log the error for debugging purposes
		if err.Error() == "no rows in result set" {
			fmt.Println("Group not found, no rows returned for group_id:", groupID)
		} else {
			fmt.Printf("Error executing query: %v\n", err)
		}
		http.Error(w, "Group not found", http.StatusNotFound)
		return
	}


	// Determine group type name
	var groupTypeStr string
	switch groupType {
	case 1:
		groupTypeStr = "OTS"
	case 2:
		groupTypeStr = "Grey Group"
	case 3:
		groupTypeStr = "Private-Split"
	case 4:
		groupTypeStr = "Normal Group"
	default:
		groupTypeStr = "Unknown"
	}

	// Hide invite code if Private-Split
	if groupType == 3 {
		inviteCode = ""
	}

	// Send response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": true,
		"group_details": map[string]interface{}{
			"group_description": description,
			"group_type":        groupTypeStr,
			"invite_code":       inviteCode,
		},
	})
}




func GetMembers(w http.ResponseWriter, r *http.Request) {
	// Extract group_id from URL query parameters
	groupID := r.URL.Query().Get("group_id")
	if groupID == "" {
		http.Error(w, "Group ID is required", http.StatusBadRequest)
		return
	}

	// Convert group_id to UUID
	parsedGroupID, err := uuid.Parse(groupID)
	if err != nil {
		http.Error(w, "Invalid Group ID format", http.StatusBadRequest)
		return
	}

	// Query to get members of the group using config.DB
	rows, err := config.DB.Query(`
		SELECT u.username, u.name
		FROM users u
		INNER JOIN group_participants gp ON u.username = gp.participant
		WHERE gp.group_id = $1
	`, parsedGroupID)
	if err != nil {
		http.Error(w, "Error querying members", http.StatusInternalServerError)
		log.Println("Error executing query: ", err)
		return
	}
	defer rows.Close()

	// Collecting member details
	var members []map[string]interface{}
	for rows.Next() {
		var username, name string
		err := rows.Scan(&username, &name)
		if err != nil {
			http.Error(w, "Error reading member data", http.StatusInternalServerError)
			log.Println("Error reading data: ", err)
			return
		}
		member := map[string]interface{}{
			"username": username,
			"name":     name,
		}
		members = append(members, member)
	}

	// Check if any members were found
	if len(members) == 0 {
		http.Error(w, "No members found for this group", http.StatusNotFound)
		return
	}

	// Respond with member data
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"members": members,
	})
}

func ExitGroupProcedure(tx *sql.Tx, username string, groupID uuid.UUID) (bool, string) {
	// 1. Check if group exists
	var temp string
	err := tx.QueryRow(`SELECT group_id FROM groups WHERE group_id = $1`, groupID).Scan(&temp)
	if err == sql.ErrNoRows {
		return false, "Group not found"
	} else if err != nil {
		return false, "Database error while checking group existence"
	}

	// 2. Check if user is part of the group
	err = tx.QueryRow(`
		SELECT participant FROM group_participants 
		WHERE group_id = $1 AND participant = $2
	`, groupID, username).Scan(&temp)
	if err == sql.ErrNoRows {
		return false, "User not part of the group"
	} else if err != nil {
		return false, "Database error while checking group participation"
	}

	// 3. Check for outstanding balances
	row := tx.QueryRow(`
		SELECT sender, receiver, amount FROM balances
		WHERE group_id = $1 AND amount <> 0 AND (sender = $2 OR receiver = $2)
		LIMIT 1
	`, groupID, username)

	var sender, receiver string
	var amount float64
	err = row.Scan(&sender, &receiver, &amount)
	if err != sql.ErrNoRows && err != nil {
		return false, "Database error while checking balances"
	}
	if err != sql.ErrNoRows {
		return false, "Cannot exit group! All balances not settled"
	}

	// 4. Check for incomplete intermediate transactions
	row = tx.QueryRow(`
		SELECT sender, receiver, amount FROM intermediate_transactions
		WHERE group_id = $1 AND amount <> 0 AND confirmed = FALSE 
		AND (sender = $2 OR receiver = $2)
		LIMIT 1
	`, groupID, username)

	err = row.Scan(&sender, &receiver, &amount)
	if err != sql.ErrNoRows && err != nil {
		return false, "Database error while checking transactions"
	}
	if err != sql.ErrNoRows {
	var other string
	if sender == username {
		other = receiver
	} else {
		other = sender
	}
	return false, fmt.Sprintf("Transactions not completely settled with %s", other)
	}



	// 5. Everything OK, remove from group_participants
	_, err = tx.Exec(`
		DELETE FROM group_participants
		WHERE group_id = $1 AND participant = $2
	`, groupID, username)
	if err != nil {
		return false, "Failed to remove user from group"
	}


	return true, "Group exited successfully"
}




func ExitGroup(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	username, ok1 := req["username"].(string)
	groupIDStr, ok2 := req["group_id"].(string)

	if !ok1 || !ok2 {
		http.Error(w, "Missing or invalid username/group_id", http.StatusBadRequest)
		return
	}

	groupID, err := uuid.Parse(groupIDStr)
	if err != nil {
		http.Error(w, "Invalid group_id format", http.StatusBadRequest)
		return
	}


	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Failed to begin transaction", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()


	// Check if user is part of the group
	var participant string
	err = tx.QueryRow(`
		SELECT participant FROM group_participants
		WHERE group_id = $1 AND participant = $2
	`, groupID, username).Scan(&participant)
	if err == sql.ErrNoRows {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "User not part of the group",
		})
		return
	} else if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	// Check if user is the last member of the group
	var count int
	err = tx.QueryRow(`
		SELECT COUNT(*) FROM group_participants
		WHERE group_id = $1
	`, groupID).Scan(&count)
	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}
	if count == 1 {
		// If the user is the last member, delete the group
		// print yes
		fmt.Println("Deleting group as user is the last member")
		// print groupID
		fmt.Println("Group ID:", groupID)
		_, err = tx.Exec(`
			DELETE FROM groups WHERE group_id = $1
		`, groupID)
		if err != nil {
			fmt.Println("Error deleting group:", err)
			http.Error(w, "Failed to delete group", http.StatusInternalServerError)
			return
		}
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  true,
			"message": "Group deleted successfully",
		})
		return
	}

	// Check if the user is the admin of the group
	var adminUsername string
	err = tx.QueryRow(`
		SELECT admin_username FROM groups WHERE group_id = $1
	`, groupID).Scan(&adminUsername)

	if err != nil {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"is_admin":     false,
			"status":       false,
			"message":      "Group not found",
			"members_list": []map[string]interface{}{},
		})
		return
	}

	if adminUsername != username {
		// Not admin – call ExitGroupProcedure
		status, message := ExitGroupProcedure(tx, username, groupID)

		if status {
			if err := tx.Commit(); err != nil {
				log.Println("Transaction commit error:", err)
				http.Error(w, "Transaction failed", http.StatusInternalServerError)
				return
			}
		}
	
		
		json.NewEncoder(w).Encode(map[string]interface{}{
			"is_admin":     false,
			"status":       status,
			"message":      message,
			"members_list": []map[string]interface{}{},
		})
		return
	}

	// User is admin – get other members
	rows, err := tx.Query(`
		SELECT u.username, u.name
		FROM group_participants gp
		JOIN users u ON gp.participant = u.username
		WHERE gp.group_id = $1 AND gp.participant != $2
	`, groupID, username)
	if err != nil {
		log.Println("Error fetching members:", err)
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var members []map[string]interface{}
	for rows.Next() {
		var uname, name string
		if err := rows.Scan(&uname, &name); err != nil {
			log.Println("Row scan error:", err)
			continue
		}
		members = append(members, map[string]interface{}{
			"username": uname,
			"name":     name,
		})
	}

	

	json.NewEncoder(w).Encode(map[string]interface{}{
		"is_admin":     true,
		"status":       false,
		"message":      "Admin!",
		"members_list": members,
	})
}


func SelectAnotherAdmin(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var req map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	username, ok1 := req["username"].(string)
	groupIDStr, ok2 := req["group_id"].(string)
	newAdmin, ok3 := req["new_admin"].(string)

	if !ok1 || !ok2 || !ok3 {
		http.Error(w, "Missing or invalid parameters", http.StatusBadRequest)
		return
	}

	groupID, err := uuid.Parse(groupIDStr)
	if err != nil {
		http.Error(w, "Invalid group_id format", http.StatusBadRequest)
		return
	}

	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Failed to begin transaction", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Check if group exists
	var dummy string
	err = tx.QueryRow(`SELECT group_id FROM groups WHERE group_id = $1`, groupID).Scan(&dummy)
	if err == sql.ErrNoRows {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Group not found",
		})
		return
	} else if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	// Check if newAdmin is a participant in the group
	var exists string
	err = tx.QueryRow(`
		SELECT participant FROM group_participants 
		WHERE group_id = $1 AND participant = $2
	`, groupID, newAdmin).Scan(&exists)

	if err == sql.ErrNoRows {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "The selected new admin is not a member of the group",
		})
		return
	} else if err != nil {
		http.Error(w, "Database error during participant check", http.StatusInternalServerError)
		return
	}


	// Call ExitGroupProcedure
	status, message := ExitGroupProcedure(tx, username, groupID)

	if status {
		// Update admin only if ExitGroupProcedure succeeded
		_, err := tx.Exec(`
			UPDATE groups SET admin_username = $1 WHERE group_id = $2
		`, newAdmin, groupID)
		if err != nil {
			http.Error(w, "Failed to update admin", http.StatusInternalServerError)
			return
		}
	}

	if err := tx.Commit(); err != nil {
		http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  status,
		"message": message,
	})
}


