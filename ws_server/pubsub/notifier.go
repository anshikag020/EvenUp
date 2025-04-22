package pubsub

import "github.com/anshikag020/EvenUp/ws_server/hub"

// NotifyExpense broadcasts a new‐expense event.
func NotifyExpense(h *hub.Hub, payload []byte) {
    h.Broadcast(payload)
}

// NotifySettle broadcasts a settle‐up event.
func NotifySettle(h *hub.Hub, payload []byte) {
    h.Broadcast(payload)
}
