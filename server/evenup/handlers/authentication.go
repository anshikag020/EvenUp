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
	"github.com/google/uuid"
	"fmt"
	"github.com/anshikag020/EvenUp/server/evenup/services"
	"crypto/rand"
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

	verificationToken := uuid.New().String()

	_, err = tx.Exec(`
		UPDATE users SET email_verification_token = $1 WHERE email = $2
	`, verificationToken, req.Email)
	if err != nil {
		log.Println("Failed to store verification token:", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	verificationLink := fmt.Sprintf("http://localhost:8080/api/verify_email?token=%s", verificationToken)
	subject := "Verify your Evenup account"
	body := fmt.Sprintf("Hi %s,\n\nThanks for signing up!\nPlease verify your email:\n\n%s\n\nThanks,\nEvenup Team", req.Name, verificationLink)

	go func() {
		if mailErr := services.SendMail([]string{req.Email}, subject, body); mailErr != nil {
			log.Println("Email sending failed:", mailErr)
		}
	}()



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


func VerifyEmailHandler(w http.ResponseWriter, r *http.Request) {
	// print something
	// log.Println("Verifying email...")
	token := r.URL.Query().Get("token")
	if token == "" {
		http.Error(w, "Token is required", http.StatusBadRequest)
		return
	}

	result, err := config.DB.Exec(`
		UPDATE users SET email_verified = true
		WHERE email_verification_token = $1
	`, token)

	rowsAffected, _ := result.RowsAffected()
	if err != nil || rowsAffected == 0 {
		http.Error(w, "Invalid or already used token", http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "text/html")
	fmt.Fprintf(w, `
		<!DOCTYPE html>
		<html>
		<head>
			<title>Email Verified</title>
			<style>
				body {
					font-family: sans-serif;
					text-align: center;
					margin-top: 100px;
					color:rgb(23, 130, 169);
				}
				h1 {
					font-size: 2em;
				}
			</style>
		</head>
		<body>
			<h1>Your email has been verified successfully!</h1>
			<p>You can now log in and use your account.</p>
			<small>You can close the tab now.</small>
		</body>
		</html>
	`)


}


// ──────────────────────────────── HELPERS ────────────────────────────────
func randomDigits(n int) (string, error) {
	bytes := make([]byte, n)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	for i := 0; i < n; i++ {
		bytes[i] = '0' + (bytes[i] % 10)
	}
	return string(bytes), nil
}

// redis keys helper
func otpKey(email string) string  { return "fp:otp:" + email }
func rstKey(email string) string  { return "fp:rset:" + email } // token after OTP verified


// ──────────────────────────────── 1) /api/forgot_password ────────────────────────────────
func ForgotPasswordHandler(w http.ResponseWriter, r *http.Request) {
	var req struct{ Email string `json:"email"` }
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Email == "" {
		http.Error(w, "Invalid email", http.StatusBadRequest); return
	}

	// verify email exists
	var exists bool
	if err := config.DB.QueryRow(`SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)`, req.Email).
		Scan(&exists); err != nil || !exists {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status": false, "message": "Invalid email",
		}); return
	}

	otp, _ := randomDigits(6)
	services.SetTemp(otpKey(req.Email), otp, 15*time.Minute) // auto-expire

	// send email
	subject := "Your Evenup OTP"
	body := fmt.Sprintf("Your OTP is %s. It’s valid for 15 minutes.", otp)
	go services.SendMail([]string{req.Email}, subject, body)

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": true, "message": "OTP sent to email",
	})
}


// ──────────────────────────────── 2) /api/confirm_otp ────────────────────────────────
func ConfirmOtpHandler(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email string `json:"email"`
		Otp   string `json:"otp"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil ||
		req.Email == "" || req.Otp == "" {
		http.Error(w, "Invalid", http.StatusBadRequest); return
	}

	stored, err := services.GetTemp(otpKey(req.Email))
	if err != nil || stored != req.Otp {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status": false, "message": "Invalid OTP",
		}); return
	}

	// OTP correct → create short-lived reset token
	token, _ := randomDigits(32)
	services.SetTemp(rstKey(req.Email), token, 30*time.Minute)
	services.Del(otpKey(req.Email)) // burn OTP

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": true, "message": "OTP verified successfully", "reset_token": token,
	})
}

func ForgotResetPasswordHandler(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Email       string `json:"email"`
		ResetToken  string `json:"reset_token"`
		NewPassword string `json:"new_password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil ||
		req.Email == "" || req.ResetToken == "" || len(req.NewPassword) < 8 {
		http.Error(w, "Invalid", http.StatusBadRequest); return
	}

	tokenStored, err := services.GetTemp(rstKey(req.Email))
	if err != nil || tokenStored != req.ResetToken {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status": false, "message": "Invalid or expired token",
		}); return
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	_, err = config.DB.Exec(`UPDATE users SET password=$1 WHERE email=$2`, string(hash), req.Email)
	if err != nil {
		log.Println("reset pwd DB:", err)
		http.Error(w, "Server error", http.StatusInternalServerError); return
	}

	services.Del(rstKey(req.Email)) // burn token
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": true, "message": "Password reset successfully",
	})
}