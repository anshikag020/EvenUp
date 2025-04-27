package handlers

import (
    "database/sql"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/anshikag020/EvenUp/server/evenup/config"
	"github.com/anshikag020/EvenUp/server/evenup/services"
	"github.com/google/uuid"
)

func SendGroupReminder(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    var req struct {
        Username string `json:"username"`   // who’s owing
        GroupID  string `json:"group_id"`
    }
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request body", http.StatusBadRequest)
        return
    }
    // validate UUID
    gid, err := uuid.Parse(req.GroupID)
    if err != nil {
        http.Error(w, "Invalid group_id", http.StatusBadRequest)
        return
    }

    var groupName string
    err = config.DB.QueryRow(`SELECT group_name FROM groups WHERE group_id = $1`, gid).Scan(&groupName)
    if err != nil {
        if err == sql.ErrNoRows {
            http.Error(w, "Group not found", http.StatusNotFound)
        } else {
            http.Error(w, "DB error fetching group name", http.StatusInternalServerError)
        }
        return
    }

    // fetch all other participant emails
    rows, err := config.DB.Query(`
        SELECT u.email 
        FROM users u
        JOIN balances b ON u.username = b.sender
        WHERE b.group_id = $1 AND b.receiver = $2 AND b.amount > 0
    `, gid, req.Username)
    if err != nil {
        http.Error(w, "DB error", http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    var to []string
    for rows.Next() {
        var email string
        if err := rows.Scan(&email); err == nil {
            to = append(to, email)
        } else {
            // Log scan error, but continue processing other rows
            fmt.Printf("Error scanning email for group %s, user %s: %v\n", gid.String(), req.Username, err)
        }
    }
    if len(to) == 0 {
        http.Error(w, "No recipients found", http.StatusNotFound)
        return
    }

    // compose reminder
    subject := fmt.Sprintf("Reminder: Settle your balance in group %s", groupName)
    body := fmt.Sprintf("Hi there,\n\nThis is a reminder to settle your outstanding balance in group %s with %s.\nPlease log in to EvenUp to settle up.\n\nThanks!", groupName, req.Username)

    // send asynchronously so HTTP isn’t blocked
    go func() {
        if err := services.SendMail(to, subject, body); err != nil {
            // log internally
            fmt.Println("Reminder email failed:", err)
        }
    }()

    // respond immediately
    json.NewEncoder(w).Encode(map[string]interface{}{
        "status":  true,
        "message": "Reminder sent",
    })
}
