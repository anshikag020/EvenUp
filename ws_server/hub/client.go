package hub

import (
    "time"
    "github.com/gorilla/websocket"
)

const (
    writeWait  = 10 * time.Second
    pongWait   = 60 * time.Second
    pingPeriod = (pongWait * 9) / 10
    maxMsgSize = 512
)

// Client represents a single WebSocket connection.
type Client struct {
    Hub  *Hub
    Conn *websocket.Conn
    Send chan []byte
}

// NewClient builds and returns a *Client.
func NewClient(h *Hub, conn *websocket.Conn) *Client {
    return &Client{
        Hub:  h,
        Conn: conn,
        Send: make(chan []byte, 256),
    }
}

// ReadPump reads messages from the WebSocket.
// We don’t expect inbound messages, so it just discards them.
func (c *Client) ReadPump() {
    defer func() {
        c.Hub.unregister <- c
        c.Conn.Close()
    }()
    c.Conn.SetReadLimit(maxMsgSize)
    c.Conn.SetReadDeadline(time.Now().Add(pongWait))
    c.Conn.SetPongHandler(func(string) error {
        c.Conn.SetReadDeadline(time.Now().Add(pongWait))
        return nil
    })
    for {
        if _, _, err := c.Conn.NextReader(); err != nil {
            break
        }
    }
}

// WritePump writes messages from c.Send to the WebSocket.
func (c *Client) WritePump() {
    ticker := time.NewTicker(pingPeriod)
    defer func() {
        ticker.Stop()
        c.Conn.Close()
    }()
    for {
        select {
        case msg, ok := <-c.Send:
            c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
            if !ok {
                // The hub closed the channel.
                c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
                return
            }
            w, err := c.Conn.NextWriter(websocket.TextMessage)
            if err != nil {
                return
            }
            w.Write(msg)
            if err := w.Close(); err != nil {
                return
            }
        case <-ticker.C:
            c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
            if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
                return
            }
        }
    }
}
