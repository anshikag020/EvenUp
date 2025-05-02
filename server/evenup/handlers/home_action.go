package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	//"log"
	"github.com/anshikag020/EvenUp/server/evenup/config"
	"github.com/anshikag020/EvenUp/server/evenup/middleware"

	//"golang.org/x/crypto/bcrypt"
	"github.com/lib/pq"
	"log"
	"strconv"
	"strings"
	"github.com/google/uuid"
	"github.com/anshikag020/EvenUp/server/evenup/services"
)

func GetUserDetails (w http.ResponseWriter, r *http.Request) {
    username, ok := middleware.GetUsernameFromContext(r)
    if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
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

// 	body, _ := io.ReadAll(r.Body)
// fmt.Println(string(body))
// r.Body = io.NopCloser(bytes.NewBuffer(body)) // Reset body so Decoder can read it again


	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}

	var req struct {
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
	case "OTS Group":
		groupType = 0
	case "Grey Group":
		groupType = 1
	case "Normal Group":
		groupType = 2
	default:
		http.Error(w, "Invalid group type", http.StatusBadRequest)
		return
	}

    // Begin a transaction
	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Failed to begin transaction", http.StatusInternalServerError)
		return
	}

	// Insert the group into the database
	var groupID uuid.UUID
	err = tx.QueryRow(
		"INSERT INTO groups (group_name, group_description, group_type, admin_username) "+
			"VALUES ($1, $2, $3, $4) RETURNING group_id",
		req.GroupName, req.GroupDescription, groupType, username,
	).Scan(&groupID)
	if err != nil {
		tx.Rollback()
		http.Error(w, "Failed to create group", http.StatusInternalServerError)
		return
	}

	// If the group is OTS, insert the admin into the ots_group_participants table
	// and insert an entry into ots_groups with confirmed = false
	if groupType == 0 {
		_, err = tx.Exec(`
			INSERT INTO ots_group_participants (group_id, user_name, confirmed)
			VALUES ($1, $2, FALSE)
		`, groupID, username)
		if err != nil {
			tx.Rollback()
			log.Println("Error inserting into ots_group_participants:", err)
			http.Error(w, "Failed to add admin to OTS participants", http.StatusInternalServerError)
			return
		}

		_, err = tx.Exec(`
			INSERT INTO ots_groups (group_id, confirmed)
			VALUES ($1, FALSE)
		`, groupID)
		if err != nil {
			tx.Rollback()
			log.Println("Error inserting into ots_groups:", err)
			http.Error(w, "Failed to initialize OTS group confirmation", http.StatusInternalServerError)
			return
		}
	}


	// Insert the admin into the group_participants table
	_, err = tx.Exec(
		"INSERT INTO group_participants (group_id, participant) VALUES ($1, $2)",
		groupID, username,
	)
	if err != nil {
		tx.Rollback()
		http.Error(w, "Failed to add admin to group participants", http.StatusInternalServerError)
		return
	}

	// Commit the transaction
	err = tx.Commit()
	if err != nil {
		http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
		return
	}

	// Return success response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"message": "Group created successfully",
	})
}


func CreatePrivateSplit(w http.ResponseWriter, r *http.Request) {
	// Parse request body
	var req struct {
		Username2        string `json:"username_2"`
		// GroupDescription string `json:"group_description"`
	}
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	username, ok := middleware.GetUsernameFromContext(r)
    if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
        return
    }

    // Check if both usernames are the same
    if username == req.Username2 {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Cannot create private-split with yourself",
		})
		return
	}

	// Start transaction
	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Failed to start transaction", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback() // rollback on any failure

	var exists int

	// Check if both users exist
	for _, user := range []string{username, req.Username2} {
		err = tx.QueryRow("SELECT COUNT(*) FROM users WHERE username = $1", user).Scan(&exists)
		if err != nil || exists == 0 {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"status":  false,
				"message": fmt.Sprintf("User not found: %s", user),
			})
			return
		}
	}

	// Create group name
	groupName := fmt.Sprintf("%s-%s", username, req.Username2)

	// Insert into groups table
	var groupID uuid.UUID
	err = tx.QueryRow(`
		INSERT INTO groups (group_name, group_description, group_type, admin_username)
		VALUES ($1, $2, 3, $3) RETURNING group_id
	`, groupName, "This is a Private Split", username).Scan(&groupID)
	if err != nil {
		http.Error(w, "Failed to create group", http.StatusInternalServerError)
		return
	}

	// Insert participants
	for _, participant := range []string{username, req.Username2} {
		_, err = tx.Exec(`
			INSERT INTO group_participants (group_id, participant)
			VALUES ($1, $2)
		`, groupID, participant)
		if err != nil {
			http.Error(w, "Failed to add participants", http.StatusInternalServerError)
			return
		}
	}

	// Commit transaction
	if err = tx.Commit(); err != nil {
		http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
		return
	}
	/* ---------- notify the second participant --------------------------- */
	go func() {
		// 1) fetch names + email
		var (
			creatorName   string
			otherName     string
			otherEmail    string
		)
		if err := config.DB.QueryRow(`
				SELECT name FROM users WHERE username = $1
		`, username).Scan(&creatorName); err != nil {
			log.Println("mail: fetch creator name:", err)
			return
		}
		if err := config.DB.QueryRow(`
				SELECT name, email FROM users WHERE username = $1
		`, req.Username2).Scan(&otherName, &otherEmail); err != nil {
			log.Println("mail: fetch other user:", err)
			return
		}

		// 2) build & send message
		subject := "New Private-Split created"
		body := fmt.Sprintf(
			"Hi %s,\n\n%s has created a new Private-Split with you on Evenup.\n"+
				"You can start adding expenses in the group “%s”.\n\nThanks,\nEvenup Team",
			otherName, creatorName, fmt.Sprintf("%s-%s", username, req.Username2),
		)

		if err := services.SendMail([]string{otherEmail}, subject, body); err != nil {
			log.Println("mail: send failed:", err)
		}
	}()


	// Send success response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"message": "Private-Split created successfully",
	})
}


func JoinGroup(w http.ResponseWriter, r *http.Request) {
	// Parse request body

	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}


	var req struct {
		InviteCode string `json:"invite_code"`
	}
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	
	// Start transaction
	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Failed to start transaction", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	var groupID uuid.UUID
	var groupType int

	// Check if invite code exists and get group info
	err = tx.QueryRow(`
		SELECT group_id, group_type FROM groups WHERE invite_code = $1
	`, req.InviteCode).Scan(&groupID, &groupType)

	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Invalid invite code",
		})
		return
	}

	// Disallow joining private-split groups
	if groupType == 3 {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Cannot join Private-Split group",
		})
		return
	}

	// Check if user is already a participant in group_participants
	var exists int
	err = tx.QueryRow(`
		SELECT COUNT(*) FROM group_participants WHERE group_id = $1 AND participant = $2
	`, groupID, username).Scan(&exists)
	if err != nil {
		http.Error(w, "Failed to check existing membership", http.StatusInternalServerError)
		return
	}
	if exists > 0 {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "User already part of the group",
		})
		return
	}

	// Add to group_participants
	_, err = tx.Exec(`
		INSERT INTO group_participants (group_id, participant)
		VALUES ($1, $2)
	`, groupID, username)
	if err != nil {
		log.Println("Error inserting into group_participants:", err)
		http.Error(w, "Failed to add to group_participants", http.StatusInternalServerError)
		return
	}

	// If OTS group, add to ots_group_participants
	if groupType == 0 {
		_, err = tx.Exec(`
			INSERT INTO ots_group_participants (group_id, user_name)
			VALUES ($1, $2)
		`, groupID, username)
		if err != nil {
			http.Error(w, "Failed to add to ots_group_participants", http.StatusInternalServerError)
			return
		}
	}

	// Commit transaction
	if err = tx.Commit(); err != nil {
		http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
		return
	}

	// Success response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"message": "Group joined successfully",
	})
}

// (redundant)
func GetTransactionHistory(w http.ResponseWriter, r *http.Request) {
    // Parse request body
    username, ok := middleware.GetUsernameFromContext(r)
    if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
        return
    }

    // Query the transaction history for the user
    rows, err := config.DB.Query(`
        SELECT 
			ct.transaction_id, 
			g.group_name, 
			CASE 
				WHEN ct.sender = $1 THEN ct.receiver 
				WHEN ct.receiver = $1 THEN ct.sender
			END AS other_user,
			CASE 
				WHEN ct.sender = $1 THEN TRUE 
				WHEN ct.receiver = $1 THEN FALSE
			END AS is_sender,
			ct.amount,
			ct.timestamp
		FROM completed_transactions ct
		JOIN groups g ON ct.group_id = g.group_id
		WHERE ct.sender = $1 OR ct.receiver = $1;

    `, username)
    if err != nil {
        http.Error(w, "Failed to fetch transaction history", http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    // Prepare the transactions slice
    var transactions []map[string]interface{}
    
    for rows.Next() {
        var transactionID uuid.UUID
		var group_name string
        var otherUser string
        var isSender bool
        var amount float64
        var timestamp time.Time // Add a timestamp field to capture the transaction timestamp

        err := rows.Scan(&transactionID, &group_name, &otherUser, &isSender, &amount, &timestamp)
        if err != nil {
            http.Error(w, "Failed to scan transaction", http.StatusInternalServerError)
            return
        }

        transactions = append(transactions, map[string]interface{}{
            "transaction_id": transactionID.String(),
            "other_user":     otherUser,
			"group_name":     group_name, 
            "is_sender":      isSender,
            "amount":         amount,
            "timestamp":      timestamp.Format("02 Jan 2006 15:04"), // Include the timestamp in the response
        })
    }

    if err = rows.Err(); err != nil {
        http.Error(w, "Error occurred while fetching rows", http.StatusInternalServerError)
        return
    }

    // Send the response
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "status":      true,
        "transactions": transactions,
    })
}



// tag ↔ int mapping used in your schema
var tagStrToInt = map[string]int{
	"food":       0,
	"transport":  1,
	"entertainment": 2,
	"shopping":   3,
	"bills":      4,
	"other":      5,
}
var tagIntToStr = func() map[int]string {
	m := make(map[int]string)
	for k, v := range tagStrToInt {
		m[v] = k
	}
	return m
}()

func rangeToSince(ts string) *time.Time {
	now := time.Now()
	switch strings.ToLower(strings.TrimSpace(ts)) {
	case "1 week":
		t := now.AddDate(0, 0, -7); return &t
	case "1 month":
		t := now.AddDate(0, -1, 0); return &t
	case "3 months":
		t := now.AddDate(0, -3, 0); return &t
	case "6 months":
		t := now.AddDate(0, -6, 0); return &t
	case "1 year":
		t := now.AddDate(-1, 0, 0); return &t
	default: // "all time" or unknown
		return nil
	}
}

// ---------- request / response  -----------------------------------------

type analysisRequest struct {
	GroupIDs   []string `json:"group_ids"`
	Categories []string `json:"categories"`
	TimeRange  string   `json:"time_range"`
}

type analysisResponse struct {
	Status               bool               `json:"status"`
	TotalAmountSpent     float64            `json:"total_amount_spent"`
	PerGroupBreakdown    map[string]float64 `json:"per_group_breakdown"`
	PerCategoryBreakdown map[string]float64 `json:"per_category_breakdown"`
}

// ---------- main handler -----------------------------------------------

func GetAnalysis(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// -------- 0) auth ----------------------------------------------------
	user, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}

	// -------- 1) parse body ---------------------------------------------
	var req analysisRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

    if len(req.GroupIDs) == 0 {
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status":  false,
            "message": "No groups selected",
        })
        return
    }
    if len(req.Categories) == 0 {
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status":  false,
            "message": "No categories selected",
        })
        return
    }
	  
	// -------- 2) build dynamic WHERE ------------------------------------
	var whereParts []string
	var args []interface{}
	add := func(v interface{}) string {
		args = append(args, v)
		return "$" + strconv.Itoa(len(args))
	}

	// mandatory: this user’s share only
	whereParts = append(whereParts, "bs.username = "+add(user))

	if len(req.GroupIDs) != 0 {
		whereParts = append(whereParts, "e.group_id = ANY("+add(pq.Array(req.GroupIDs))+")")
	}
	if len(req.Categories) != 0 {
		var tagInts []int
		for _, c := range req.Categories {
			if t, ok := tagStrToInt[strings.ToLower(c)]; ok {
				tagInts = append(tagInts, t)
			}
		}
		if len(tagInts) > 0 {
			whereParts = append(whereParts, "e.tag = ANY("+add(pq.Array(tagInts))+")")
		}
	}
	if since := rangeToSince(req.TimeRange); since != nil {
		whereParts = append(whereParts, "e.timestamp >= "+add(*since))
	}

	whereSQL := strings.Join(whereParts, " AND ")

	// -------- 3) run query ----------------------------------------------
	/*
	   We sum bs.amount_owed (the user’s share) per group+tag.
	*/
	q := fmt.Sprintf(`
		SELECT e.group_id, e.tag, SUM(bs.amount_owed)
		FROM   expenses      e
		JOIN   bill_split    bs ON bs.expense_id = e.expense_id
		WHERE  %s
		GROUP  BY e.group_id, e.tag
	`, whereSQL)

	rows, err := config.DB.Query(q, args...)
	if err != nil {
		log.Println("analysis query:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	total := 0.0
	perGroup    := map[string]float64{}
	perCategory := map[string]float64{}

	for rows.Next() {
		var gid string
		var tag int
		var owed float64
		if err := rows.Scan(&gid, &tag, &owed); err != nil {
			log.Println("scan row:", err)
			continue
		}
		total += owed
		perGroup[gid] += owed
		perCategory[tagIntToStr[tag]] += owed
	}
	if err := rows.Err(); err != nil {
		log.Println("row err:", err)
	}

	// for _, c := range req.Categories {
    //     key := strings.ToLower(c)
    //     if _, exists := perCategory[key]; !exists {
    //         perCategory[key] = 0
    //     }
    // }

	// -------- 4) respond -----------------------------------------------
	json.NewEncoder(w).Encode(analysisResponse{
		Status:               true,
		TotalAmountSpent:     total,
		PerGroupBreakdown:    perGroup,
		PerCategoryBreakdown: perCategory,
	})
}