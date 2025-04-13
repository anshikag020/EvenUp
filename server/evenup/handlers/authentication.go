package handlers

import(
	"encoding/json"
	"net/http"
	"github.com/anshikag020/EvenUp/server/evenup/config"
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
	// Check if username already exists
	var exists bool
	err = config.DB.QueryRow("SELECT EXISTS (SELECT 1 FROM users WHERE username=$1)", req.Username).Scan(&exists)
	// Check for errors in the query
	if err != nil {
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	if exists {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  false,
			"message": "Username already used",
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
	_, err = config.DB.Exec("INSERT INTO users (username, name, email, password) VALUES ($1, $2, $3, $4)",
		req.Username, req.Name, req.Email, string(hashedPassword))
	if err != nil {
		http.Error(w, "Failed to create user", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  true,
		"message": "User created successfully",
	})
}

func LoginUser(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("User Logged In"))
}

func GetUserProfile(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("User Profile Fetched"))
}