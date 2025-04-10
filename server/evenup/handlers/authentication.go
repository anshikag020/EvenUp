package handlers

import(
	"net/http"
)

func RegisterUser(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("User Registered"))
}

func LoginUser(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("User Logged In"))
}

func GetUserProfile(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("User Profile Fetched"))
}