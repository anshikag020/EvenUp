package main

import (
	"log"
	"net/http"					// for server
	"github.com/gorilla/mux"	// router
	"github.com/anshikag020/EvenUp/server/evenup/routes"					// routes folder
	"github.com/anshikag020/EvenUp/server/evenup/config"					// config folder
	"github.com/anshikag020/EvenUp/ws_server/hub"
	wshdl "github.com/anshikag020/EvenUp/ws_server/handlers"
	srvhdl "github.com/anshikag020/EvenUp/server/evenup/handlers"	// server handlers
	"github.com/joho/godotenv"
)

func main(){
	config.ConnectDB()			// load config
	router := mux.NewRouter()	// create new router
	routes.RegisterRoutes(router)	// register routes is a function in routes folder

	wsHub := hub.NewHub()	// create new hub
	go wsHub.Run()	// run the hub in a goroutine
	srvhdl.WS = wsHub	// assign the hub to the server handler

	 // Load .env file. Handle the error if it occurs.
	 err := godotenv.Load() // Assumes .env is in the current working directory
	 if err != nil {
		 log.Println("Warning: Could not load .env file. Relying on system environment variables.")
		 // Depending on your setup, you might want to log.Fatal here if the .env is critical
	 }

	router.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		wshdl.ServeWS(wsHub, w, r)	// handle websocket connection
	})

	log.Println("Starting server on port 8080")	// log message
	log.Fatal(http.ListenAndServe(":8080", router))	// start server and keep listening for requests
}