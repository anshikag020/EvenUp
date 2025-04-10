package main

import (
	"log"
	"net/http"					// for server
	"github.com/gorilla/mux"	// router
	"github.com/anshikag020/EvenUp/server/evenup/routes"					// routes folder
	"github.com/anshikag020/EvenUp/server/evenup/config"					// config folder
)

func main(){
	config.ConnectDB()			// load config
	router := mux.NewRouter()	// create new router
	routes.RegisterRoutes(router)	// register routes is a function in routes folder
	log.Println("Starting server on port 8080")	// log message
	log.Fatal(http.ListenAndServe(":8080", router))	// start server and keep listening for requests
}