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

	connStr := "postgres://postgres:123456@localhost:5432/evenup?sslmode=disable"

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
