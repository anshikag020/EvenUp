package routes

import (
	//"net/http"
	"net/http"

	"github.com/anshikag020/EvenUp/server/evenup/handlers"
	"github.com/anshikag020/EvenUp/server/evenup/middleware"
	"github.com/gorilla/mux"
)

func RegisterRoutes(router *mux.Router) {
	// Public (no auth)
	router.HandleFunc("/api/signup", handlers.CreateUserAccount).Methods("POST")
	router.HandleFunc("/api/login",  handlers.LoginUser).Methods("POST")

	// Protected (requires JWT)
	router.Handle("/api/logout",
		middleware.AuthMiddleware(http.HandlerFunc(handlers.LogoutUser)),
	).Methods("POST")

	router.Handle("/api/reset_password",
		middleware.AuthMiddleware(http.HandlerFunc(handlers.ResetPassword)),
	).Methods("POST")

	router.Handle("/api/user/profile",
		middleware.AuthMiddleware(http.HandlerFunc(handlers.GetUserProfile)),
	).Methods("GET")


	// Protected routes (require JWT auth)
	router.Handle(
		"/api/get_user_details",
		middleware.AuthMiddleware(http.HandlerFunc(handlers.GetUserDetails)),
	).Methods("GET")

	router.Handle(
		"/api/create_group",
		middleware.AuthMiddleware(http.HandlerFunc(handlers.CreateGroup)),
	).Methods("POST")

	router.Handle(
		"/api/create_private_split",
		middleware.AuthMiddleware(http.HandlerFunc(handlers.CreatePrivateSplit)),
	).Methods("POST")

	router.Handle(
		"/api/join_group",
		middleware.AuthMiddleware(http.HandlerFunc(handlers.JoinGroup)),
	).Methods("POST")

	router.Handle(
		"/api/get_transaction_history",
		middleware.AuthMiddleware(http.HandlerFunc(handlers.GetTransactionHistory)),
	).Methods("GET")


	// Groups page actions (all require a valid JWT)
router.Handle(
    "/api/get_groups",
    middleware.AuthMiddleware(http.HandlerFunc(handlers.GetGroups)),
).Methods("GET")

router.Handle(
    "/api/get_group_details",
    middleware.AuthMiddleware(http.HandlerFunc(handlers.GetGroupDetails)),
).Methods("GET")

router.Handle(
    "/api/get_members",
    middleware.AuthMiddleware(http.HandlerFunc(handlers.GetMembers)),
).Methods("GET")

router.Handle(
    "/api/exit_group",
    middleware.AuthMiddleware(http.HandlerFunc(handlers.ExitGroup)),
).Methods("DELETE")

router.Handle(
    "/api/select_another_admin",
    middleware.AuthMiddleware(http.HandlerFunc(handlers.SelectAnotherAdmin)),
).Methods("PUT")

router.Handle(
    "/api/delete_group",
    middleware.AuthMiddleware(http.HandlerFunc(handlers.DeleteGroup)),
).Methods("DELETE")



// Expenses routes (all protected; use POST to create)
router.Handle(
    "/api/add_expense",
    middleware.AuthMiddleware(http.HandlerFunc(handlers.AddExpenseHandler)),
).Methods("POST")

router.Handle(
    "/api/send_reminder",
    middleware.AuthMiddleware(http.HandlerFunc(handlers.SendGroupReminder)),
).Methods("POST")

router.Handle(
    "/api/get_expenses",
    middleware.AuthMiddleware(http.HandlerFunc(handlers.GetExpenses)),
).Methods("POST")

router.Handle(
	"/api/edit_expense",
	middleware.AuthMiddleware(http.HandlerFunc(handlers.EditExpenseHandler)),
).Methods("PUT")





// Balances routes
router.Handle(
    "/api/get_balances",
    middleware.AuthMiddleware(http.HandlerFunc(handlers.GetBalances)),
).Methods("POST")

router.Handle(
	"/api/settle_balance",
	middleware.AuthMiddleware(http.HandlerFunc(handlers.SettleBalanceHandler)),
).Methods("PUT")

}

