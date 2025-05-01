module github.com/anshikag020/EvenUp/server

go 1.24.2

require (
	github.com/gorilla/mux v1.8.1
	github.com/lib/pq v1.10.9
)

require golang.org/x/crypto v0.37.0

require github.com/google/uuid v1.6.0

require (
	github.com/anshikag020/EvenUp/ws_server v0.0.0-00010101000000-000000000000
	github.com/redis/go-redis/v9 v9.8.0
)

require (
	github.com/cespare/xxhash/v2 v2.3.0 // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
)

require (
	github.com/golang-jwt/jwt/v5 v5.2.2 // direct
	github.com/gorilla/websocket v1.5.3 // indirect
	github.com/joho/godotenv v1.5.1 // direct
)

replace github.com/anshikag020/EvenUp/ws_server => ../ws_server
