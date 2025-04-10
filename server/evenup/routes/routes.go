package routes

import (
	"net/http"
	"github.com/gorilla/mux"
)

func RegisterRoutes(router *mux.Router) {
	// Example Route
	router.HandleFunc("/ping", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("pong"))
	}).Methods("GET")

	// Later you can add more routes like:
	// router.HandleFunc("/users", controllers.GetUsers).Methods("GET")
}
