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

type Client struct {
    hub  *Hub
    conn *websocket.Conn
    send chan []byte
}

// readPump pumps messages from the WebSocket connection.
// We don’t expect clients to send anything, so we just read and discard.
func (c *Client) readPump() {
    defer func() {
        c.hub.unregister <- c
        c.conn.Close()
    }()
    c.conn.SetReadLimit(maxMsgSize)
    c.conn.SetReadDeadline(time.Now().Add(pongWait))
    c.conn.SetPongHandler(func(string) error { 
        c.conn.SetReadDeadline(time.Now().Add(pongWait)); return nil 
    })
    for {
        if _, _, err := c.conn.NextReader(); err != nil {
            break
        }
    }
}

// writePump sends queued messages to the WebSocket connection.
func (c *Client) writePump() {
    ticker := time.NewTicker(pingPeriod)
    defer func() {
        ticker.Stop()
        c.conn.Close()
    }()
    for {
        select {
        case msg, ok := <-c.send:
            c.conn.SetWriteDeadline(time.Now().Add(writeWait))
            if !ok {
                // hub closed the channel
                c.conn.WriteMessage(websocket.CloseMessage, []byte{})
                return
            }
            w, err := c.conn.NextWriter(websocket.TextMessage)
            if err != nil { return }
            w.Write(msg)
            if err := w.Close(); err != nil { return }
        case <-ticker.C:
            c.conn.SetWriteDeadline(time.Now().Add(writeWait))
            if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
                return
            }
        }
    }
}
