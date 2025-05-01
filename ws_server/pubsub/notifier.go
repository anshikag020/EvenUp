package pubsub

import (
    "github.com/anshikag020/EvenUp/ws_server/hub"
    "encoding/json"
)

// NotifyExpense broadcasts a new‐expense event.
func NotifyExpense(h *hub.Hub, payload []byte) {
    h.Broadcast(payload)
}

// NotifySettle broadcasts a settle‐up event.
func NotifySettle(h *hub.Hub, payload []byte) {
    h.Broadcast(payload)
}

func NotifyRefresh(h *hub.Hub, page string) {
    msg := map[string]string{"type":"refresh_page","page":page}
    b, _ := json.Marshal(msg)
    h.Broadcast(b)
}
