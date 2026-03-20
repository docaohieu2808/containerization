// Simple Go HTTP server — used as test app across all containerization examples
// Exposes GET / (hello JSON) and GET /health (healthcheck endpoint)
// Build: go build -o http-server http-hello-world-server.go
package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
)

type Response struct {
	Message  string `json:"message"`
	Hostname string `json:"hostname"`
	PID      int    `json:"pid"`
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		hostname, _ := os.Hostname()
		resp := Response{
			Message:  "Hello from Go container!",
			Hostname: hostname,
			PID:      os.Getpid(),
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintln(w, `{"status":"ok"}`)
	})

	fmt.Printf("Server listening on port %s\n", port)
	http.ListenAndServe("0.0.0.0:"+port, nil)
}
