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
                close(c.send)
            }
        case msg := <-h.broadcast:
            for c := range h.clients {
                select {
                case c.send <- msg:
                default:
                    close(c.send)
                    delete(h.clients, c)
                }
            }
        }
    }
}
