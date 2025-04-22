package handlers

import (
    "net/http"
    "github.com/gorilla/websocket"
    "github.com/anshikag020/EvenUp/ws_server/hub"
)

var upgrader = websocket.Upgrader{
    ReadBufferSize:  1024,
    WriteBufferSize: 1024,
    CheckOrigin:     func(r *http.Request) bool { return true },
}

// ServeWS handles WebSocket requests from the client.
func ServeWS(h *hub.Hub, w http.ResponseWriter, r *http.Request) {
    conn, err := upgrader.Upgrade(w, r, nil)
    if err != nil { return }
    client := &hub.Client{hub: h, conn: conn, send: make(chan []byte, 256)}
    client.hub.register <- client

    go client.writePump()
    go client.readPump()
}
