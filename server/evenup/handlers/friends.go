// server/evenup/handlers/friends.go
package handlers

import (
    "encoding/json"
    "log"
    "net/http"

    "github.com/anshikag020/EvenUp/server/evenup/config"
    "github.com/anshikag020/EvenUp/server/evenup/middleware"
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
