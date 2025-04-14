package routes

import (
	//"net/http"
	"github.com/gorilla/mux"
	"github.com/anshikag020/EvenUp/server/evenup/handlers"
)

func RegisterRoutes(router *mux.Router) {
	// Authentication Routes
	router.HandleFunc("/api/signup", handlers.CreateUserAccount).Methods("POST")
	router.HandleFunc("/api/login", handlers.LoginUser).Methods("POST")
	router.HandleFunc("/api/logout", handlers.LogoutUser).Methods("POST")
	router.HandleFunc("/api/reset_password", handlers.ResetPassword).Methods("POST")

	// Home action Routes
	router.HandleFunc("/api/get_user_details", handlers.GetUserDetails).Methods("GET")
	router.HandleFunc("/api/create_group", handlers.CreateGroup).Methods("PUT")	

}