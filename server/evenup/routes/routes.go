package routes

import (
	//"net/http"
	"net/http"

	"github.com/anshikag020/EvenUp/server/evenup/handlers"
	"github.com/anshikag020/EvenUp/server/evenup/middleware"
	"github.com/gorilla/mux"
)

func RegisterRoutes(router *mux.Router) {
	// Authentication Routes
	router.HandleFunc("/api/signup", handlers.CreateUserAccount).Methods("POST")
	router.HandleFunc("/api/login", handlers.LoginUser).Methods("POST")
	router.HandleFunc("/api/logout", handlers.LogoutUser).Methods("POST")
	router.HandleFunc("/api/reset_password", handlers.ResetPassword).Methods("POST")
	router.Handle("/api/user/profile", middleware.AuthMiddleware(http.HandlerFunc(handlers.GetUserProfile)))

	// Home action Routes
	router.HandleFunc("/api/get_user_details", handlers.GetUserDetails).Methods("GET")
	router.HandleFunc("/api/create_group", handlers.CreateGroup).Methods("PUT")
	router.HandleFunc("/api/create_private_split", handlers.CreatePrivateSplit).Methods("PUT")
	router.HandleFunc("/api/join_group", handlers.JoinGroup).Methods("PUT")
	router.HandleFunc("/api/get_transaction_history", handlers.GetTransactionHistory).Methods("GET")
	
	// groups page actions
	router.HandleFunc("/api/get_groups", handlers.GetGroups).Methods("GET")
	router.HandleFunc("/api/get_group_details", handlers.GetGroupDetails).Methods("GET")
	router.HandleFunc("/api/get_members", handlers.GetMembers).Methods("GET")
	router.HandleFunc("/api/exit_group", handlers.ExitGroup).Methods("DELETE")
	router.HandleFunc("/api/select_another_admin", handlers.SelectAnotherAdmin).Methods("DELETE")
	router.HandleFunc("/api/delete_group", handlers.DeleteGroup).Methods("DELETE")


	// Expenses routes
	router.HandleFunc("/api/add_expense", handlers.AddExpenseHandler).Methods("PUT")
}