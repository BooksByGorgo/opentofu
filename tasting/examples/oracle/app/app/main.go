package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
	_ "time/tzdata" // zone database, since a scratch image has none

	_ "github.com/go-sql-driver/mysql"
)

var db *sql.DB

// saying looks up the message for the current second of the hour.
func saying(w http.ResponseWriter, r *http.Request) {
	now := time.Now()
	key := now.Minute()*60 + now.Second()
	var text string
	err := db.QueryRow("SELECT saying FROM sayings WHERE id = ?", key).Scan(&text)
	if err != nil {
		log.Printf("lookup %d: %v", key, err)
		http.Error(w, "no saying right now, try again", http.StatusServiceUnavailable)
		return
	}
	fmt.Fprintf(w, "[%s] %s\n", now.Format("15:04:05"), text)
}

func main() {
	addr := ":8080"
	if port := os.Getenv("PORT"); port != "" {
		addr = ":" + port
	}
	var err error
	db, err = sql.Open("mysql", os.Getenv("DB_DSN")) // connects lazily
	if err != nil {
		log.Fatal(err)
	}
	db.SetConnMaxLifetime(3 * time.Minute)
	http.HandleFunc("/", saying)
	log.Printf("listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
