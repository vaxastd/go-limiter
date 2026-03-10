package limiter

import (
	"log"
	"net/http"
	"time"
)

func (rl *RateLimiter) Middleware(limit int, window time.Duration, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		key := "rate_limit:" + r.RemoteAddr
		allowed, err := rl.Allow(r.Context(), key, limit)
		if err != nil {
			log.Printf("Rate limiter error: %v", err)
			next.ServeHTTP(w, r)
			return
		}

		if !allowed {
			log.Printf("Rate limit exceeded for IP: %s", r.RemoteAddr)
			w.WriteHeader(http.StatusTooManyRequests)
			w.Write([]byte("Rate limit exceeded. Please try again later.\n"))
			return
		}

		log.Printf("Request allowed for IP: %s", r.RemoteAddr)
		next.ServeHTTP(w, r)
	}
}