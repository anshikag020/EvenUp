package handlers

import(
	"net/http"
	"encoding/json"
	"github.com/anshikag020/EvenUp/server/evenup/config"
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
	// Parse request body
	var req struct {
		GroupID string `json:"group_id"`
	}
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Query group info
	var description, inviteCode string
	var groupType int
	err = config.DB.QueryRow(`
		SELECT group_description, group_type, invite_code
		FROM groups
		WHERE group_id = $1
	`, req.GroupID).Scan(&description, &groupType, &inviteCode)

	if err != nil {
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
