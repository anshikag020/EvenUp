package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"time"
	"github.com/anshikag020/EvenUp/server/evenup/config"
	"github.com/anshikag020/EvenUp/server/evenup/middleware"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

func CreateUserAccount(w http.ResponseWriter, r *http.Request) {
	
	var req struct {
		Username string `json:"username"`
		Name     string `json:"name"`
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	// Decode the request body
	err := json.NewDecoder(r.Body).Decode(&req)
	// Check for errors in decoding
	if err != nil {
		http.Error(w, "Invalid request format", http.StatusBadRequest)
		return
	}

	// Starting an atomic task
	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Failed to start transaction", http.StatusInternalServerError)
		return
	}
	defer func() {
		if err != nil {
			_ = tx.Rollback()
		}
	}()
	

	// ------------------------------------------------------------------
	// 1. username uniqueness
	// ------------------------------------------------------------------
	var exists bool
	err = tx.QueryRow(`SELECT EXISTS (SELECT 1 FROM users WHERE username = $1)`, req.Username).Scan(&exists)
	if err != nil {
		log.Printf("Error checking username: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	if exists {
		_ = tx.Rollback()
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Username already used",
		})
		return
	}

	// ------------------------------------------------------------------
	// 2. e-mail uniqueness
	// ------------------------------------------------------------------
	err = tx.QueryRow(`SELECT EXISTS (SELECT 1 FROM users WHERE email = $1)`, req.Email).Scan(&exists)
	if err != nil {
		log.Printf("Error checking e-mail: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	if exists {
		_ = tx.Rollback()
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Email already used",
		})
		return
	}


	// Hash the password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		http.Error(w, "Failed to hash password", http.StatusInternalServerError)
		return
	}

	// Insert user into database
	_, err = tx.Exec("INSERT INTO users (username, name, email, password) VALUES ($1, $2, $3, $4)",
		req.Username, req.Name, req.Email, string(hashedPassword))
	if err != nil {
		log.Printf("Failed to insert user %q into users table: %v", req.Username, err)
		http.Error(w, "Failed to create user", http.StatusInternalServerError)
		return
	}
	// Commit the transaction
	// Check for errors in committing the transaction
	// If there was an error, rollback the transaction
	// If there was no error, commit the transaction
	err = tx.Commit()
	if err != nil {
		http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
		return
	}
	// Success response
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"message": "User created successfully",
	})
}


// TODO: make sure email is verified, will do it later
func LoginUser(w http.ResponseWriter, r *http.Request) {

	
	// Directly decode the request body into a map or just use a struct in-line
	var req struct {
        Username string `json:"username"`
	    Password string `json:"password"`
	}
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Failed to start transaction", http.StatusInternalServerError)
		return
	}
	defer func() {
		if err != nil {
			_ = tx.Rollback()
		}
	}()

	// Check if user exists by username
	var storedPassword string
	err = tx.QueryRow("SELECT password FROM users WHERE username=$1", req.Username).Scan(&storedPassword)
	if err != nil {
		if err.Error() == "sql: no rows in result set" {
			// User not found
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{
				"status":  false,
				"message": "Invalid username",
			})
			return
		}
		log.Println("Error querying the database:", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Compare the password
	err = bcrypt.CompareHashAndPassword([]byte(storedPassword), []byte(req.Password))
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Invalid password",
		})
		return
	}

	// ---------------- JWT ----------------
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
        "username": req.Username,
        "exp":      time.Now().Add(time.Hour).Unix(), // 1-hour expiry
    })
    tokenString, err := token.SignedString(config.JwtSecretKey)
    if err != nil {
        http.Error(w, "Could not generate token", http.StatusInternalServerError)
        return
    }

    // optional: expose token as header as well
    w.Header().Set("Authorization", "Bearer "+tokenString)
	
	err = tx.Commit()
	if err != nil {
		http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
		return
	}


	// Success response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"token":  tokenString,
		"message": "User logged in successfully",
	})
}

func LogoutUser(w http.ResponseWriter, r *http.Request) {
    username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
        return
    }
    _ = username // you’ll invalidate the token/server-side session here


	// TODO: Invalidate the session or token here

	// Respond with success
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": true,
	})
}


func ResetPassword(w http.ResponseWriter, r *http.Request){
	// Parse the incoming request
	var req struct {
		OldPassword string `json:"old_password"`
		NewPassword string `json:"new_password"`
	}
	// Decode the JSON body into the req struct
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	tx, err := config.DB.Begin()
	if err != nil {
		http.Error(w, "Failed to start transaction", http.StatusInternalServerError)
		return
	}
	defer func() {
		if err != nil {
			_ = tx.Rollback()
		}
	}()

	// authenticated user
    username, ok := middleware.GetUsernameFromContext(r)
    if !ok {
        http.Error(w, "User not authorized", http.StatusUnauthorized)
        return
    }

    // Retrieve the hashed password
    var hashedPassword string
    err = tx.QueryRow("SELECT password FROM users WHERE username=$1", username).Scan(&hashedPassword)


	if err != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}
	// Compare the old password with the stored hashed password
	err = bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(req.OldPassword))
	if err != nil {
		http.Error(w, "Incorrect old password", http.StatusUnauthorized)
		return
	}

	// Hash the new password
	newHashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		http.Error(w, "Error hashing new password", http.StatusInternalServerError)
		return
	}

	// Update the user's password in the database
	_, err = tx.Exec("UPDATE users SET password=$1 WHERE username=$2", newHashedPassword, username)
	if err != nil {
		http.Error(w, "Error updating password", http.StatusInternalServerError)
		return
	}

	err = tx.Commit()
	if err != nil {
		http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
		return
	}

	// Send the success response
	w.Header().Set("Content-Type", "application/json")
	response := map[string]interface{}{
		"status":  true,
		"message": "Password reset successfully",
	}

	// Write the response
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}



func GetUserProfile(w http.ResponseWriter, r *http.Request) {
	username, ok := middleware.GetUsernameFromContext(r)
	if !ok {
		http.Error(w, "User not authorized", http.StatusUnauthorized)
		return
	}

	// Fetch user details from DB
	var name, email string
	var darkMode bool
	err := config.DB.QueryRow(
		"SELECT username, email, dark_mode FROM users WHERE username=$1",
		username,
	).Scan(&name, &email, &darkMode)

	if err != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	// Send the user details
	response := map[string]interface{}{
		"username":  username,
		"name":      name,
		"email":     email,
		"dark_mode": darkMode,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

