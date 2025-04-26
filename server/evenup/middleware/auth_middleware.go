package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/anshikag020/EvenUp/server/evenup/config"
)

type contextKey string

const userContextKey = contextKey("username")

func AuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "Authorization header missing", http.StatusUnauthorized)
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			http.Error(w, "Bearer token missing", http.StatusUnauthorized)
			return
		}

		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			return config.JwtSecretKey, nil
		})

		if err != nil || !token.Valid {
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			http.Error(w, "Invalid token claims", http.StatusUnauthorized)
			return
		}

		username, ok := claims["username"].(string)
		if !ok {
			http.Error(w, "Invalid token username", http.StatusUnauthorized)
			return
		}

		// Put username into context
		ctx := context.WithValue(r.Context(), userContextKey, username)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// Helper function to get username from request
func GetUsernameFromContext(r *http.Request) (string, bool) {
	username, ok := r.Context().Value(userContextKey).(string)
	return username, ok
}
