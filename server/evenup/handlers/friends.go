// server/evenup/handlers/friends.go
package handlers

import (
    "encoding/json"
    "log"
	"fmt"
    "net/http"

    "github.com/anshikag020/EvenUp/server/evenup/config"
    "github.com/anshikag020/EvenUp/server/evenup/middleware"
	"github.com/anshikag020/EvenUp/server/evenup/services"
)

type FriendRecord struct {
    Sender   string  `json:"sender"`
    Receiver string  `json:"receiver"`
    Name     string  `json:"name"`
    Balance  float64 `json:"balance"`
}

type GetFriendsPageResponse struct {
    Status  bool           `json:"status"`
    Friends []FriendRecord `json:"friends"`
}

// GetFriendsPageRecords returns one aggregated balance per “friend”,
// summing across all groups where you and they have an unsettled balance.
func GetFriendsPageRecords(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")

    // 1) auth
    me, ok := middleware.GetUsernameFromContext(r)
    if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
        return
    }

    // 2) query balances table, grouping by (sender,receiver) pairs
	rows, err := config.DB.Query(`
        SELECT 
            b.sender,
            b.receiver,
            u.name,
            SUM(b.amount) AS balance
        FROM balances b
        JOIN groups g  ON b.group_id = g.group_id
        LEFT JOIN ots_groups og ON g.group_id = og.group_id
        JOIN users u   ON 
             (b.sender = $1 AND u.username = b.receiver)
          OR (b.receiver = $1 AND u.username = b.sender)
        WHERE
             (g.group_type != 0 OR og.confirmed IS TRUE)
         AND (b.sender = $1 OR b.receiver = $1)
        GROUP BY b.sender, b.receiver, u.name
    `, me)
    if err != nil {
        log.Println("GetFriendsPageRecords query error:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    // 3) build response
    var out []FriendRecord
    for rows.Next() {
        var fr FriendRecord
        if err := rows.Scan(&fr.Sender, &fr.Receiver, &fr.Name, &fr.Balance); err != nil {
            log.Println("scan friends row:", err)
            continue
        }
        out = append(out, fr)
    }
    if err := rows.Err(); err != nil {
        log.Println("rows iteration error:", err)
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    // 4) return
    json.NewEncoder(w).Encode(GetFriendsPageResponse{
        Status:  true,
        Friends: out,
    })
}

// SettleUpFriendsPage moves *all* outstanding balances
// between the current user and friend into intermediate_transactions.
func SettleUpFriendsPage(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")

    // 1) auth
    me, ok := middleware.GetUsernameFromContext(r)
    if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
        return
    }

    // 2) parse friend name
    var req struct{ FriendName string `json:"friend_name"` }
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Malformed request body", http.StatusBadRequest)
        return
    }

    // 3) move each balance row into intermediate_transactions
    tx, err := config.DB.Begin()
    if err != nil {
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }
    defer tx.Rollback()

    rows, err := tx.Query(`
        SELECT group_id, amount
        FROM balances
        WHERE sender = $1 AND receiver = $2
    `, me, req.FriendName)
    if err != nil {
        http.Error(w, "DB error", http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    for rows.Next() {
        var gid string
        var amt float64
        if err := rows.Scan(&gid, &amt); err != nil {
            continue
        }
        // insert into in‐transit
        _, _ = tx.Exec(`
            INSERT INTO intermediate_transactions
                (transaction_id, group_id, sender, receiver, amount)
            VALUES
                (gen_random_uuid(), $1, $2, $3, $4)
        `, gid, me, req.FriendName, amt)
    }

    // then delete the settled balances
    _, _ = tx.Exec(`
        DELETE FROM balances
        WHERE sender = $1 AND receiver = $2
    `, me, req.FriendName)

    if err := tx.Commit(); err != nil {
        http.Error(w, "Server error", http.StatusInternalServerError)
        return
    }

    json.NewEncoder(w).Encode(map[string]interface{}{
        "status":  true,
        "message": "Settle up initiated",
    })
}

// RemindFriendsPage sends a one‐off email reminder to your friend
// for any outstanding balance they owe you.
func RemindFriendsPage(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")

    // 1) auth
    me, ok := middleware.GetUsernameFromContext(r)
    if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
        return
    }

    // 2) parse friend name
    var req struct{ FriendName string `json:"friend_name"` }
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Malformed request body", http.StatusBadRequest)
        return
    }

    // 3) find all groups where they owe you something
    rows, err := config.DB.Query(`
        SELECT g.group_name, u.email
        FROM balances b
        JOIN groups g ON b.group_id = g.group_id
        JOIN users u  ON u.username = b.sender
        WHERE b.sender = $1 AND b.receiver = $2
    `, req.FriendName, me)
    if err != nil {
        http.Error(w, "DB error", http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    // 4) blast off one email per group
    for rows.Next() {
        var groupName, email string
        if err := rows.Scan(&groupName, &email); err != nil {
            continue
        }
        subject := fmt.Sprintf("Reminder to settle up in %s", groupName)
        body := fmt.Sprintf(
            "Hi %s,\n\n%s is reminding you to settle your outstanding balance in \"%s\".\n\nThanks,\nEvenUp",
            req.FriendName, me, groupName,
        )
        go services.SendMail([]string{email}, subject, body)
    }

    json.NewEncoder(w).Encode(map[string]interface{}{
        "status":  true,
        "message": "Remind initiated",
    })
}
