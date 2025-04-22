package hub

// Hub maintains the set of active clients and broadcasts messages.
type Hub struct {
    // Registered clients.
    clients map[*Client]bool

    // Inbound messages to broadcast.
    broadcast chan []byte

    // Register requests from clients.
    register chan *Client

    // Unregister requests from clients.
    unregister chan *Client
}

// NewHub creates a new Hub.
func NewHub() *Hub {
    return &Hub{
        broadcast:  make(chan []byte),
        register:   make(chan *Client),
        unregister: make(chan *Client),
        clients:    make(map[*Client]bool),
    }
}

// Run starts the hub’s loop.
func (h *Hub) Run() {
    for {
        select {
        case c := <-h.register:
            h.clients[c] = true
        case c := <-h.unregister:
            if _, ok := h.clients[c]; ok {
                delete(h.clients, c)
                close(c.Send)
            }
        case msg := <-h.broadcast:
            for c := range h.clients {
                select {
                case c.Send <- msg:
                default:
                    close(c.Send)
                    delete(h.clients, c)
                }
            }
        }
    }
}

// Register adds a client to the hub.
func (h *Hub) Register(c *Client) {
    h.register <- c
}

// Unregister removes a client from the hub.
func (h *Hub) Unregister(c *Client) {
    h.unregister <- c
}

// Broadcast sends a message to all clients.
func (h *Hub) Broadcast(msg []byte) {
    h.broadcast <- msg
}
