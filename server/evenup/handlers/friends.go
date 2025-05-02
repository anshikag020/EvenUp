// server/evenup/handlers/friends.go
package handlers

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/anshikag020/EvenUp/server/evenup/config"
	"github.com/anshikag020/EvenUp/server/evenup/middleware"
	"github.com/anshikag020/EvenUp/server/evenup/services"
	// "github.com/google/uuid"
    // "github.com/lib/pq"
     "github.com/shopspring/decimal"
	"github.com/anshikag020/EvenUp/ws_server/pubsub"
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
// (sender = me, receiver = friend) into intermediate_transactions.
func SettleUpFriendsPage(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	/* ─── 1. Auth ──────────────────────────────────────────────── */
	me, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}

	/* ─── 2. Parse body ───────────────────────────────────────── */
	var req struct {
		FriendName string `json:"friend_name"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Malformed request body", http.StatusBadRequest)
		return
	}
	if req.FriendName == "" || req.FriendName == me {
		http.Error(w, "Invalid friend name", http.StatusBadRequest)
		return
	}

	/* ─── 3. Begin transaction ───────────────────────────────── */
	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	/* ─── 4. Move + sum in one CTE ────────────────────────────── */
	var total decimal.Decimal
	err = tx.QueryRow(`
		WITH moved AS (
			DELETE FROM balances
			WHERE sender = $1 AND receiver = $2
			RETURNING group_id, sender, receiver, amount
		)
		INSERT INTO intermediate_transactions
		    (group_id, sender, receiver, amount)
		SELECT  group_id, sender, receiver, amount
		FROM moved
		RETURNING COALESCE(SUM(amount), 0)
	`, me, req.FriendName).Scan(&total)
	if err != nil {
        // Log the full error for debugging
        log.Printf(
            "Error moving balances into intermediate_transactions for %s→%s: %v",
            me, req.FriendName, err,
        )
        // Return the exact error message in the response body
        http.Error(w, fmt.Sprintf("Database error: %v", err), http.StatusInternalServerError)
        return
    }
    if total.IsZero() {
        http.Error(w, "No outstanding balance with that user", http.StatusConflict)
        return
    }

	// /* ─── 5. Look up names / email ───────────────────────────── */
	// var senderName, receiverName, receiverEmail string
	// if err := tx.QueryRow(`SELECT name FROM users WHERE username = $1`, me).
	// 	Scan(&senderName); err != nil {
	// 	http.Error(w, "DB error", http.StatusInternalServerError)
	// 	return
	// }
	// if err := tx.QueryRow(`
	// 	SELECT name, email FROM users WHERE username = $1`, req.FriendName).
	// 	Scan(&receiverName, &receiverEmail); err != nil {
	// 	http.Error(w, "DB error", http.StatusInternalServerError)
	// 	return
	// }

	/* ─── 6. Commit ──────────────────────────────────────────── */
	if err := tx.Commit(); err != nil {
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	/* ─── 7. Send email (async) ──────────────────────────────── */
// 	go func() {
// 		if receiverEmail == "" {
// 			return
// 		}
// 		subject := "Settlement initiated"
// 		body := fmt.Sprintf(`Hi %s,

// %s has initiated a settlement with you on Evenup.
// Total amount of money: ₹%s.

// Please open the app to review and confirm.

// Thanks,
// Evenup Team`,
// 			receiverName, senderName, total.StringFixed(2))

// 		if err := services.SendMail([]string{receiverEmail}, subject, body); err != nil {
// 			log.Println("mail send failed:", err)
// 		}
// 	}()

	/* ─── 8. Tell clients to refresh ─────────────────────────── */
	if WS != nil {
		pubsub.NotifyRefresh(WS, "friends")
	}

	/* ─── 9. Respond ─────────────────────────────────────────── */
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":       true,
		"message":      "Settle up initiated",
		"total_amount": total.StringFixed(2),
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
