package handlers

import(
	"net/http"
	"encoding/json"
	"github.com/anshikag020/EvenUp/server/evenup/config"
	"github.com/google/uuid"
	"fmt"
	"log"
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
