package main

import (
    "log"
    "net/http"
    "os"
    "github.com/gorilla/mux"
    "github.com/anshikag040/EvenUp/ws_server/config"
    "github.com/anshikag040/EvenUp/ws_server/hub"
    "github.com/anshikag040/EvenUp/ws_server/handlers"
)

func main() {
    cfg := config.Load() // read WS_PORT from env or default
    h := hub.NewHub()
    go h.Run()

    r := mux.NewRouter()
    r.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
        handlers.ServeWS(h, w, r)
    })

    log.Printf("WebSocket server starting on :%s\n", cfg.WSPort)
    if err := http.ListenAndServe(":"+cfg.WSPort, r); err != nil {
        log.Fatal("ListenAndServe:", err)
    }
}
