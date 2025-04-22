package config
import "os"

type Config struct { WSPort string }

func Load() *Config {
    p := os.Getenv("WS_PORT")
    if p == "" { p = "8090" }
    return &Config{WSPort: p}
}
