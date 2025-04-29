package handlers

import (
    "database/sql"
    "encoding/json"
    "net/http"

    "github.com/google/uuid"
    "github.com/anshikag020/EvenUp/server/evenup/config"
    "github.com/anshikag020/EvenUp/server/evenup/middleware"
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
