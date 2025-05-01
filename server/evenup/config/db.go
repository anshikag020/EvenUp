package config

import (
	"database/sql"
	"log"
	"fmt"

	_ "github.com/lib/pq"
)

var DB *sql.DB

func ConnectDB() {
	var err error
															// TODO: change the database name
															// TODO: make sure everyones password is same
															// TODO: sslmode?
	// connStr := "Enter your db connection link here" 
	connStr := "postgresql://postgres:123456@localhost/evenup_trial"

	DB, err = sql.Open("postgres", connStr)

	if err != nil {
		log.Fatal("Error while connecting to DB: ", err)
	}

	err = DB.Ping()
	if err != nil {
		log.Fatal("Cannot reach DB: ", err)
	}

	fmt.Println("Connected to PostgreSQL Database successfully!")
}
