package routes

import (
	//"net/http"
	"github.com/gorilla/mux"
	"github.com/anshikag020/EvenUp/server/evenup/handlers"
)

func RegisterRoutes(router *mux.Router) {
	// User Routes
	router.HandleFunc("/api/signup", handlers.CreateUserAccount).Methods("POST")
	router.HandleFunc("/users/login", handlers.LoginUser).Methods("POST")
	router.HandleFunc("/users/profile/{username}", handlers.GetUserProfile).Methods("GET")

}