// Tiny HTTP service shared by every container example in this repo.
//
//	GET /        JSON greeting (hostname, pid)
//	GET /health  {"status":"ok"}
//
// `-healthcheck` probes /health on this same binary and exits 0/1. A scratch
// image has no wget or curl, so the binary doubles as its own HEALTHCHECK
// command instead of starting a second server.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net/http"
	"os"
	"time"
)

func port() string {
	if p := os.Getenv("PORT"); p != "" {
		return p
	}
	return "8080"
}

func probe() int {
	client := http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://127.0.0.1:" + port() + "/health")
	if err != nil {
		return 1
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return 1
	}
	return 0
}

func main() {
	healthcheck := flag.Bool("healthcheck", false, "probe /health and exit 0 (healthy) or 1")
	flag.Parse()
	if *healthcheck {
		os.Exit(probe())
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", func(w http.ResponseWriter, _ *http.Request) {
		hostname, _ := os.Hostname()
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"message":  "Hello from Go container!",
			"hostname": hostname,
			"pid":      os.Getpid(),
		})
	})
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintln(w, `{"status":"ok"}`)
	})

	srv := &http.Server{Addr: "0.0.0.0:" + port(), Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	fmt.Println("listening on", srv.Addr)
	if err := srv.ListenAndServe(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
