package handlers

import(
	"encoding/json"
	"net/http"
	//"log"
	"github.com/anshikag020/EvenUp/server/evenup/config"
	//"golang.org/x/crypto/bcrypt"
	"github.com/google/uuid"
)

func GetUserDetails (w http.ResponseWriter, r *http.Request) {
	username := r.URL.Query().Get("username")
	if username == "" {
		http.Error(w, "Username is required", http.StatusBadRequest)
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
	var req struct {
		Username        string `json:"username"`
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
	case "OTS":
		groupType = 0
	case "Grey Group":
		groupType = 1
	case "Normal Group":
		groupType = 2
	default:
		http.Error(w, "Invalid group type", http.StatusBadRequest)
		return
	}

	// Insert the group into the database
	var groupID uuid.UUID
	err = config.DB.QueryRow(
		"INSERT INTO groups (group_name, group_description, group_type, admin_username) "+
			"VALUES ($1, $2, $3, $4) RETURNING group_id",
		req.GroupName, req.GroupDescription, groupType, req.Username,
	).Scan(&groupID)
	if err != nil {
		http.Error(w, "Failed to create group", http.StatusInternalServerError)
		return
	}

	// If the group is OTS, insert the admin into the ots_group_participants table
	if groupType == 0 {
		_, err = config.DB.Exec(
			"INSERT INTO ots_group_participants (group_id, user_name) VALUES ($1, $2)",
			groupID, req.Username, true,
		)
		if err != nil {
			http.Error(w, "Failed to add admin to OTS participants", http.StatusInternalServerError)
			return
		}
	}

	// Insert the admin into the group_participants table
	_, err = config.DB.Exec(
		"INSERT INTO group_participants (group_id, participant) VALUES ($1, $2)",
		groupID, req.Username,
	)
	if err != nil {
		http.Error(w, "Failed to add admin to group participants", http.StatusInternalServerError)
		return
	}

	// Return success response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"message": "Group created successfully",
	})
}

