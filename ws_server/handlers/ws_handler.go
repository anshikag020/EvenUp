package handlers

import (
    "net/http"
    "github.com/gorilla/websocket"
    "github.com/anshikag020/EvenUp/ws_server/hub"      // adjust import path!
)

var upgrader = websocket.Upgrader{
    ReadBufferSize:  1024,
    WriteBufferSize: 1024,
    CheckOrigin:     func(r *http.Request) bool { return true },
}

func ServeWS(h *hub.Hub, w http.ResponseWriter, r *http.Request) {
    conn, err := upgrader.Upgrade(w, r, nil)
    if err != nil {
        return
    }
    client := hub.NewClient(h, conn)

    // register via the exported method
    h.Register(client)

    go client.WritePump()
    go client.ReadPump()
}
