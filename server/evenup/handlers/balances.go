package handlers

import (
    "database/sql"
    "encoding/json"
    "net/http"
	"log"
    "github.com/google/uuid"
    "github.com/anshikag020/EvenUp/server/evenup/config"
    "github.com/anshikag020/EvenUp/server/evenup/middleware"
    "fmt"
    "github.com/anshikag020/EvenUp/server/evenup/services"
    "github.com/anshikag020/EvenUp/ws_server/pubsub"
)

type BalanceEntry struct {
    Sender   string  `json:"sender"`
    Receiver string  `json:"receiver"`
    Amount   float64 `json:"amount"`
}

type GetBalancesRequest struct {
    GroupID string `json:"group_id"`
}

type GetBalancesResponse struct {
    Status   bool           `json:"status"`
    Balances []BalanceEntry `json:"balances"`
    Message  string         `json:"message,omitempty"`
}

func GetBalances(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")

    // 1) Auth
    username, ok := middleware.GetUsernameFromContext(r)
    if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
        return
    }

    // 2) Decode request
    var req GetBalancesRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        w.WriteHeader(http.StatusBadRequest)
        json.NewEncoder(w).Encode(GetBalancesResponse{
            Status:  false,
            Message: "Malformed request body",
        })
        return
    }

    // 3) Validate UUID
    groupUUID, err := uuid.Parse(req.GroupID)
    if err != nil {
        w.WriteHeader(http.StatusBadRequest)
        json.NewEncoder(w).Encode(GetBalancesResponse{
            Status:  false,
            Message: "Invalid group_id format",
        })
        return
    }

    // 4) Begin transaction
    tx, err := config.DB.Begin()
    if err != nil {
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }
    defer tx.Rollback()

    // 5) Fetch group type
    var groupType int
    err = tx.QueryRow(`
        SELECT group_type
        FROM groups
        WHERE group_id = $1
    `, groupUUID).Scan(&groupType)
    if err == sql.ErrNoRows {
        json.NewEncoder(w).Encode(GetBalancesResponse{
            Status:  false,
            Message: "Group not found",
        })
        return
    } else if err != nil {
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    // 6) Query balances
    var rows *sql.Rows
    if groupType == 1 {
        // Grey group: only rows involving this user
        rows, err = tx.Query(`
            SELECT sender, receiver, amount
            FROM balances
            WHERE group_id = $1
              AND (sender = $2 OR receiver = $2)
        `, groupUUID, username)
    } else {
        // Other groups: all balances
        rows, err = tx.Query(`
            SELECT sender, receiver, amount
            FROM balances
            WHERE group_id = $1
        `, groupUUID)
    }
    if err != nil {
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    // 7) Collect results
    var bals []BalanceEntry
    for rows.Next() {
        var b BalanceEntry
        if err := rows.Scan(&b.Sender, &b.Receiver, &b.Amount); err != nil {
            http.Error(w, "Server error", http.StatusInternalServerError)
            return
        }
        bals = append(bals, b)
    }
    if err := rows.Err(); err != nil {
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    // 8) Commit and respond
    if err := tx.Commit(); err != nil {
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    json.NewEncoder(w).Encode(GetBalancesResponse{
        Status:   true,
        Balances: bals,
    })
}






func SettleBalanceHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")

    // Step 1: Auth
    username, ok := middleware.GetUsernameFromContext(r)
    if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
        return
    }

    // Step 2: Parse request
    var req struct {
        Receiver string `json:"receiver"`
        GroupID  string `json:"group_id"`
    }
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        w.WriteHeader(http.StatusBadRequest)
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status":  false,
            "message": "Invalid request body",
        })
        return
    }

    // Step 3: Validate UUID
    groupUUID, err := uuid.Parse(req.GroupID)
    if err != nil {
        w.WriteHeader(http.StatusBadRequest)
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status":  false,
            "message": "Invalid group_id format",
        })
        return
    }

    // Step 4: Begin transaction
    tx, err := config.DB.Begin()
    if err != nil {
        log.Println("tx begin:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }
    defer tx.Rollback()

    // Check if this is an OTS group and whether all users confirmed
    var groupType int
    err = tx.QueryRow(`
        SELECT group_type FROM groups WHERE group_id = $1
    `, groupUUID).Scan(&groupType)

    if err != nil {
        log.Println("fetch group_type:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    if groupType == 0 {
        var confirmed bool
        err = tx.QueryRow(`
            SELECT confirmed FROM ots_groups WHERE group_id = $1
        `, groupUUID).Scan(&confirmed)

        if err != nil {
            if err == sql.ErrNoRows {
                json.NewEncoder(w).Encode(map[string]interface{}{
                    "status":  false,
                    "message": "OTS group status not found",
                })
                return
            }
            log.Println("fetch ots confirmation:", err)
            http.Error(w, "Server error", http.StatusInternalServerError)
            return
        }

        if !confirmed {
            json.NewEncoder(w).Encode(map[string]interface{}{
                "status":  false,
                "message": "All members have not confirmed in this OTS group",
            })
            return
        }
    }

    // Step 5: Get the balance
    var amount float64
    err = tx.QueryRow(`
        SELECT amount FROM balances
        WHERE group_id = $1 AND sender = $2 AND receiver = $3
    `, groupUUID, username, req.Receiver).Scan(&amount)

    if err == sql.ErrNoRows {
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status":  false,
            "message": "No balance to settle with this user",
        })
        return
    } else if err != nil {
        log.Println("query balances:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    // Step 6: Delete the balance row
    _, err = tx.Exec(`
        DELETE FROM balances
        WHERE group_id = $1 AND sender = $2 AND receiver = $3
    `, groupUUID, username, req.Receiver)
    if err != nil {
        log.Println("delete balance:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    // Step 7: Add to intermediate_transactions
    _, err = tx.Exec(`
        INSERT INTO intermediate_transactions (group_id, sender, receiver, amount)
        VALUES ($1, $2, $3, $4)
    `, groupUUID, username, req.Receiver, amount)
    if err != nil {
        log.Println("insert intermediate tx:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    // Send email notification to the receiver
    // fetch the email of the receiver
    // Step 7.5: Fetch the email of the receiver
    var receiverEmail, receiverName string
    err = tx.QueryRow(`
        SELECT email, name FROM users WHERE username = $1
    `, req.Receiver).Scan(&receiverEmail, &receiverName)

    if err != nil {
        log.Println("fetch receiver email:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }
    
    // Step 7.6: Send the email notification
    var senderName, groupName string
    err = tx.QueryRow(`
        SELECT name FROM users WHERE username = $1
    `, username).Scan(&senderName)
    if err != nil {
        log.Println("fetch sender name:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    err = tx.QueryRow(`
        SELECT group_name FROM groups WHERE group_id = $1
    `, groupUUID).Scan(&groupName)
    if err != nil {
        log.Println("fetch group name:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    subject := "Balance Settlement Initiated"
    body := fmt.Sprintf(
        "Hi %s,\n\n%s has settled a balance of ₹%.2f with you in group \"%s\".\nPlease open the app and confirm the transaction.\n\nThanks,\nEvenup",
        receiverName, senderName, amount, groupName,
    )


    go func() {
        if mailErr := services.SendMail([]string{receiverEmail}, subject, body); mailErr != nil {
            log.Println("email sending failed:", mailErr)
        }
    }()

    // Step 8: Commit
    if err := tx.Commit(); err != nil {
        log.Println("tx commit:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    if WS != nil {
        payload, _ := json.Marshal(map[string]interface{}{
            "type":      "balance_settled",
            "group_id":  req.GroupID,
            "by":        username,
            "with":      req.Receiver,
            "amount":    amount,
        })
        pubsub.NotifySettle(WS, payload)
    }

    // Step 9: Respond
    json.NewEncoder(w).Encode(map[string]interface{}{
        "status":  true,
        "message": "Balance settled successfully",
    })
}

// RemindUserHandler sends an email reminder to a user who owes money.
func RemindUserHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")

    // 1. Auth: Get the sender's username (the one sending the reminder)
    senderUsername, ok := middleware.GetUsernameFromContext(r)
    if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
        return
    }

    // 2. Parse request body
    var req struct {
        ReceiverUsername string `json:"receiver_username"` // The user who owes money and will receive the reminder
        GroupID          string `json:"group_id"`
    }
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        w.WriteHeader(http.StatusBadRequest)
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status":  false,
            "message": "Invalid request body",
        })
        return
    }

    // 3. Validate Group ID format
    groupUUID, err := uuid.Parse(req.GroupID)
    if err != nil {
        w.WriteHeader(http.StatusBadRequest)
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status":  false,
            "message": "Invalid group_id format",
        })
        return
    }

    // 4. Begin Transaction
    tx, err := config.DB.Begin()
    if err != nil {
        log.Printf("RemindUserHandler: Failed to begin transaction: %v", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }
    defer tx.Rollback() // Rollback if any error occurs before commit

    // 5. Verify the balance exists (Receiver owes Sender) and get amount
    var amount float64
    // Note: In the balances table, 'sender' is who owes, 'receiver' is who is owed.
    // So, for a reminder, the request's 'receiver_username' is the 'sender' in the balance table,
    // and the authenticated user ('senderUsername') is the 'receiver' in the balance table.
    err = tx.QueryRow(`
        SELECT amount FROM balances
        WHERE group_id = $1 AND sender = $2 AND receiver = $3
    `, groupUUID, req.ReceiverUsername, senderUsername).Scan(&amount)

    if err == sql.ErrNoRows {
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status":  false,
            "message": fmt.Sprintf("No outstanding balance found where %s owes you in this group.", req.ReceiverUsername),
        })
        return
    } else if err != nil {
        log.Printf("RemindUserHandler: Error querying balance for reminder: %v", err)
        http.Error(w, "Server error checking balance", http.StatusInternalServerError)
        return
    }

    // 6. Fetch receiver's details (email, name)
    var receiverEmail, receiverName string
    err = tx.QueryRow(`
        SELECT email, name FROM users WHERE username = $1
    `, req.ReceiverUsername).Scan(&receiverEmail, &receiverName)
    if err != nil {
        log.Printf("RemindUserHandler: Error fetching receiver details for %s: %v", req.ReceiverUsername, err)
        // Don't expose specific error, could be user not found or db error
        http.Error(w, "Server error fetching user details", http.StatusInternalServerError)
        return
    }

    // 7. Fetch sender's name
    var senderName string
    err = tx.QueryRow(`
        SELECT name FROM users WHERE username = $1
    `, senderUsername).Scan(&senderName)
    if err != nil {
        log.Printf("RemindUserHandler: Error fetching sender name for %s: %v", senderUsername, err)
        http.Error(w, "Server error fetching user details", http.StatusInternalServerError)
        return
    }

    // 8. Fetch group name
    var groupName string
    err = tx.QueryRow(`
        SELECT group_name FROM groups WHERE group_id = $1
    `, groupUUID).Scan(&groupName)
    if err != nil {
        log.Printf("RemindUserHandler: Error fetching group name for %s: %v", groupUUID, err)
        http.Error(w, "Server error fetching group details", http.StatusInternalServerError)
        return
    }

    // 9. Prepare and send email in a goroutine
    subject := fmt.Sprintf("Reminder to settle your balance in EvenUp group '%s'", groupName)
    body := fmt.Sprintf(
        "Hi %s,\n\nThis is a friendly reminder from %s regarding the EvenUp group \"%s\".\n\nYou currently owe ₹%.2f.\nPlease settle this balance at your earliest convenience.\n\nThanks,\nEvenup",
        receiverName, senderName, groupName, amount,
    )

    go func(recipientEmail, mailSubject, mailBody string) {
        if mailErr := services.SendMail([]string{recipientEmail}, mailSubject, mailBody); mailErr != nil {
            // Log the error, but don't fail the HTTP request just because email failed
            log.Printf("RemindUserHandler: Email sending failed to %s: %v", recipientEmail, mailErr)
        } else {
            log.Printf("RemindUserHandler: Reminder email sent successfully to %s", recipientEmail)
        }
    }(receiverEmail, subject, body) // Pass variables to goroutine

    // 10. Commit Transaction (even though we only read, it's good practice)
    if err := tx.Commit(); err != nil {
        log.Printf("RemindUserHandler: Failed to commit transaction: %v", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    // 11. Respond Success
    json.NewEncoder(w).Encode(map[string]interface{}{
        "status":  true,
        "message": fmt.Sprintf("Reminder sent successfully to %s.", req.ReceiverUsername),
    })
}