package handlers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/anshikag020/EvenUp/server/evenup/config"
	"github.com/anshikag020/EvenUp/server/evenup/middleware"
	"github.com/google/uuid"
	"strings"
	"github.com/anshikag020/EvenUp/server/evenup/services"
)

func GetGroups(w http.ResponseWriter, r *http.Request) {
	// authenticated user
	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}

	// var req struct {
	// 	Username string `json:"username"`
	// }
	// err := json.NewDecoder(r.Body).Decode(&req)
	// if err != nil {
	// 	http.Error(w, "Invalid request body", http.StatusBadRequest)
	// 	return
	// }

	// Query to get all groups the user is a part of
	rows, err := config.DB.Query(`
		SELECT g.group_name,
       g.group_id,
       g.group_description,
       g.invite_code,
       g.group_type,
       (SELECT COUNT(*) FROM group_participants WHERE group_id = g.group_id) AS members
FROM groups g
WHERE g.group_id IN (
    SELECT group_id FROM group_participants WHERE participant = $1
)
	`, username)

	if err != nil {
		http.Error(w, "Failed to retrieve groups", http.StatusInternalServerError)
		return
	}
	defer rows.Close()


	// Prepare the response
	var groups []map[string]interface{}
	for rows.Next() {
		var (
			groupName,  description  		string
			groupID					       string
			inviteCode                      sql.NullString
			groupType,members                                  int
		)
		if err := rows.Scan(&groupName, &groupID, &description, &inviteCode, &groupType, &members); err != nil {
			// Log the error for debugging purposes
			log.Println("Error scanning group data:", err)
			http.Error(w, "Failed to scan group data", http.StatusInternalServerError)
			return
		}
		typeMap := map[int]string{
			0: "OTS",
			1: "Grey Group",
			2: "Normal Group",
			3: "Private-Split",
		}
		groups = append(groups, map[string]interface{}{
			"name":        groupName,
			"size":        members,
			"groupID":     groupID,
			"description": description,
			"inviteCode":  inviteCode.String,
			"groupType":   typeMap[groupType],
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
		WHERE group_id = $1 AND amount <> 0
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
	var req struct {
		GroupID string `json:"group_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}
	groupIDStr := req.GroupID

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
			"admin": false,
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
		_, err = tx.Exec(`
			DELETE FROM groups WHERE group_id = $1
		`, groupID)
		if err != nil {
			fmt.Println("Error deleting group:", err)
			http.Error(w, "Failed to delete group", http.StatusInternalServerError)
			return
		}

		// Commit the transaction
		if err := tx.Commit(); err != nil {
			log.Println("Transaction commit error after group deletion:", err)
			http.Error(w, "Transaction failed", http.StatusInternalServerError)
			return
		}

		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  true,
			"message": "Group exited successfully",
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

	if err := tx.Commit(); err != nil {
		log.Println("Transaction commit error:", err)
		http.Error(w, "Transaction failed", http.StatusInternalServerError)
		return
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
	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}
	groupIDStr, ok2 := req["group_id"].(string)
	newAdmin, ok3 := req["new_admin"].(string)

	if !ok2 || !ok3 {
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
			"message": "The selected new user is not a member of the group",
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
	// ───────── gather details for e-mail BEFORE committing ─────────
	var (
		groupName          string
		newAdminName       string
		newAdminEmail      string
		previousAdminName  string
	)

	// group name
	_ = tx.QueryRow(`
			SELECT group_name FROM groups WHERE group_id = $1
	`, groupID).Scan(&groupName)

	// new admin’s name + email
	_ = tx.QueryRow(`
			SELECT name, email FROM users WHERE username = $1
	`, newAdmin).Scan(&newAdminName, &newAdminEmail)

	// old admin’s name (the one making the request)
	_ = tx.QueryRow(`
			SELECT name FROM users WHERE username = $1
	`, username).Scan(&previousAdminName)

	if err := tx.Commit(); err != nil {
		http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
		return
	}
	
	// ───────── send notification asynchronously ─────────
	go func() {
		if newAdminEmail == "" { return } // safety
	
		subject := "You are now the admin of “" + groupName + "”"
		body := fmt.Sprintf(
	`Hi %s,
	
	%s has transferred admin rights to you for the group “%s”.
	
	You can now manage members and settings for this group in Evenup.
	
	Thanks,
	Evenup Team`, newAdminName, previousAdminName, groupName)
	
		if err := services.SendMail([]string{newAdminEmail}, subject, body); err != nil {
			log.Println("mail-notify admin change:", err)
		}
	}()
	

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  status,
		"message": message,
	})
}


func DeleteGroup(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Parse request body
	var req struct {
		GroupID string `json:"group_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	groupUUID, err := uuid.Parse(req.GroupID)
	if err != nil {
		http.Error(w, "Invalid group_id format", http.StatusBadRequest)
		return
	}

	// Begin transaction
	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Failed to begin transaction", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Check if group exists
	var adminUser string
	err = tx.QueryRow(`SELECT admin_username FROM groups WHERE group_id = $1`, groupUUID).Scan(&adminUser)
	if err == sql.ErrNoRows {
		json.NewEncoder(w).Encode(map[string]interface{}{ 
			"status": false,
			"message": "Group not found",
		})
		return
	} else if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}


	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}
	// Only admin can delete
	if adminUser != username {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status": false,
			"message": "You are not admin",
		})
		if err := tx.Commit(); err != nil {
			http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
			return
		}
		
		return
	}

	// check all balances are settled up
	var amt float64
	err = tx.QueryRow(`
		SELECT amount FROM balances 
		WHERE group_id = $1 AND amount <> 0 LIMIT 1
	`, groupUUID).Scan(&amt)
	if err != sql.ErrNoRows {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status": false,
			"message": "All balances must be settled",
		})
		if err := tx.Commit(); err != nil {
			http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
			return
		}
		
		return
	}

	// Ensure no pending intermediate transactions
	err = tx.QueryRow(`
		SELECT amount FROM intermediate_transactions
		WHERE group_id = $1 AND amount <> 0 LIMIT 1
	`, groupUUID).Scan(&amt)
	if err != sql.ErrNoRows {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status": false,
			"message": "Pending transactions must be completed",
		})
		if err := tx.Commit(); err != nil {
			http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
			return
		}
		
		return
	}

	// ─────────  Summary BEFORE destructive deletes ─────────
	var groupName string
	if err := tx.QueryRow(`SELECT group_name FROM groups WHERE group_id=$1`, groupUUID).
		Scan(&groupName); err != nil {
		http.Error(w, "Failed to fetch group name", http.StatusInternalServerError)
		return
	}

	// grand total for the group
	var grandTotal float64
	_ = tx.QueryRow(`SELECT COALESCE(SUM(amount),0) FROM expenses WHERE group_id=$1`,
		groupUUID).Scan(&grandTotal)

	// per-user totals
	perUser := map[string]float64{}
	rows, err := tx.Query(`
		SELECT bs.username, SUM(bs.amount_owed)
		FROM bill_split bs
		JOIN expenses e ON e.expense_id = bs.expense_id
		WHERE e.group_id = $1
		GROUP BY bs.username
	`, groupUUID)
	if err == nil {
		for rows.Next() {
			var u string; var amt float64
			_ = rows.Scan(&u, &amt)
			perUser[u] = amt
		}
		rows.Close()
	}

	// member names & emails
	type member struct{ name, email string }
	members := map[string]member{}
	rows, err = tx.Query(`
		SELECT u.username, u.name, u.email
		FROM users u
		JOIN group_participants gp ON gp.participant = u.username
		WHERE gp.group_id = $1
	`, groupUUID)
	if err == nil {
		for rows.Next() {
			var uname, nm, mail string
			_ = rows.Scan(&uname, &nm, &mail)
			members[uname] = member{nm, mail}
		}
		rows.Close()
	}


	// Delete participants
	if _, err := tx.Exec(`DELETE FROM group_participants WHERE group_id = $1`, groupUUID); err != nil {
		http.Error(w, "Failed to remove participants", http.StatusInternalServerError)
		return
	}

	// Delete the group record
	if _, err := tx.Exec(`DELETE FROM groups WHERE group_id = $1`, groupUUID); err != nil {
		http.Error(w, "Failed to delete group", http.StatusInternalServerError)
		return
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
		return
	}
	// ─────────  Send summary e-mails asynchronously ─────────
	go func() {
		if len(members) == 0 { return }

		// craft a per-user line list once
		var perUserLines []string
		for u, amt := range perUser {
			perUserLines = append(perUserLines,
				fmt.Sprintf("%s : ₹%.2f", members[u].name, amt))
		}
		perUserBlock := strings.Join(perUserLines, "\n")

		subject := fmt.Sprintf("Summary for deleted group “%s”", groupName)

		for uname, m := range members {
			body := fmt.Sprintf(
	`Hi %s,

	The group “%s” has been deleted.

	Total amount spent: ₹%.2f

	Breakdown by member:
	%s

	Thanks for using Evenup.`, m.name, groupName, grandTotal, perUserBlock)

			if err := services.SendMail([]string{m.email}, subject, body); err != nil {
				log.Printf("email to %s failed: %v\n", uname, err)
			}
		}
	}()


	// Success response
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"message": "Group deleted successfully",
	})
}



func ConfirmOtsParticipationHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}

	var req struct {
		GroupID string `json:"group_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	tx, err := config.DB.Begin()
	if err != nil {
		log.Println("begin tx:", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Step 1: Check group exists
	var groupExists bool
	err = tx.QueryRow(`
		SELECT EXISTS (
			SELECT 1 FROM groups WHERE group_id = $1
		)
	`, req.GroupID).Scan(&groupExists)
	if err != nil {
		log.Println("check group existence:", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	if !groupExists {
		http.Error(w, "Group not found", http.StatusNotFound)
		return
	}

	// Step 2: Check user is in group
	var isParticipant bool
	err = tx.QueryRow(`
		SELECT EXISTS (
			SELECT 1 FROM group_participants
			WHERE group_id = $1 AND participant = $2
		)
	`, req.GroupID, username).Scan(&isParticipant)
	if err != nil {
		log.Println("check participant:", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	if !isParticipant {
		http.Error(w, "You are not a participant in this group", http.StatusForbidden)
		return
	}

	// Step 3: Check current confirmation status
	var confirmed bool
	err = tx.QueryRow(`
		SELECT confirmed FROM ots_group_participants
		WHERE group_id = $1 AND user_name = $2
	`, req.GroupID, username).Scan(&confirmed)

	if err == sql.ErrNoRows {
		// No row exists — insert it with TRUE
		_, err = tx.Exec(`
			INSERT INTO ots_group_participants (group_id, user_name, confirmed)
			VALUES ($1, $2, TRUE)
		`, req.GroupID, username)
		if err != nil {
			log.Println("insert confirmation:", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
	} else if err != nil {
		log.Println("fetch confirmation:", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	} else if confirmed {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  true,
			"message": "Already confirmed",
		})
		return
	} else {
		// Update to TRUE
		_, err = tx.Exec(`
			UPDATE ots_group_participants
			SET confirmed = TRUE
			WHERE group_id = $1 AND user_name = $2
		`, req.GroupID, username)
		if err != nil {
			log.Println("update confirmation:", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
	}

	// Step 4: Check if ALL participants have confirmed
	var allConfirmed bool
	err = tx.QueryRow(`
		SELECT NOT EXISTS (
			SELECT 1 FROM ots_group_participants
			WHERE group_id = $1 AND confirmed = FALSE
		)
	`, req.GroupID).Scan(&allConfirmed)
	if err != nil {
		log.Println("check all confirmations:", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if allConfirmed {
		_, err = tx.Exec(`
			UPDATE ots_groups SET confirmed = TRUE WHERE group_id = $1
		`, req.GroupID)
		if err != nil {
			log.Println("update ots_groups confirmed:", err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}
	}
	var groupName string
	var members []struct{ name, email string }

	if allConfirmed {
		// fetch group name
		_ = tx.QueryRow(`SELECT group_name FROM groups WHERE group_id=$1`,
			req.GroupID).Scan(&groupName)

		// fetch every participant’s name + e-mail
		rows, err2 := tx.Query(`
			SELECT u.name, u.email
			FROM users u
			JOIN group_participants gp ON gp.participant = u.username
			WHERE gp.group_id = $1
		`, req.GroupID)
		if err2 == nil {
			for rows.Next() {
				var n, e string
				_ = rows.Scan(&n, &e)
				members = append(members, struct{ name, email string }{n, e})
			}
			rows.Close()
		}
	}


	if err := tx.Commit(); err != nil {
		log.Println("tx commit:", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	if err := tx.Commit(); err != nil {
		log.Println("tx commit:", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	
	// ───── email everyone only if allConfirmed was true ─────
	if allConfirmed && len(members) > 0 {
		go func() {
			subject := fmt.Sprintf("All members confirmed in “%s”", groupName)
			for _, m := range members {
				body := fmt.Sprintf(
	`Hi %s,
	
	Everyone in the OTS group “%s” has now confirmed their expenses.
	
	You can proceed to settle balances whenever you’re ready.
	
	Thanks,
	Evenup Team`, m.name, groupName)
	
				if err := services.SendMail([]string{m.email}, subject, body); err != nil {
					log.Println("email send failed to", m.email, ":", err)
				}
			}
		}()
	}
	

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"message": "TRUE",
	})
}
