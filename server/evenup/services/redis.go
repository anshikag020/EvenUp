package services

import (
	"context"
	"os"
	"time"

	"github.com/redis/go-redis/v9"
)

var (
	Rdb *redis.Client
	Ctx = context.Background()
)

func InitRedis() {
	Rdb = redis.NewClient(&redis.Options{
		Addr:     os.Getenv("REDIS_ADDR"), // e.g. "localhost:6379"
		Password: os.Getenv("REDIS_PASS"),
		DB:       0,
	})
}

func SetTemp(key, value string, ttl time.Duration) error {
	return Rdb.Set(Ctx, key, value, ttl).Err()
}

func GetTemp(key string) (string, error) {
	return Rdb.Get(Ctx, key).Result()
}

func Del(key string) {
	Rdb.Del(Ctx, key)
}
