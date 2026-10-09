package main

import (
	"context"
	"log"
	"net"
	"net/http"
	"strconv"
	"time"

	"xvay/houduan/internal/api"
	"xvay/houduan/internal/config"
	"xvay/houduan/internal/nodeproc"
	"xvay/houduan/internal/store"
)

func main() {
	cfg := config.Load()
	db, err := store.Open(cfg)
	if err != nil {
		log.Fatalf("open database: %v", err)
	}
	defer db.Close()

	if err := db.SeedDemo(); err != nil {
		log.Printf("seed demo: %v", err)
	}
	if err := nodeproc.EnsureDefault(db, cfg); err != nil {
		log.Printf("default node: %v", err)
	}
	if err := nodeproc.Sync(db, cfg); err != nil {
		log.Printf("sync nodes: %v", err)
	}
	if err := db.KeepDemoOnline(); err != nil {
		log.Printf("demo nodes: %v", err)
	}
	go nodeproc.Run(context.Background(), db)

	addr := net.JoinHostPort(cfg.Host, strconv.Itoa(cfg.Port))
	server := &http.Server{
		Addr:              addr,
		Handler:           api.New(cfg, db),
		ReadHeaderTimeout: 10 * time.Second,
	}
	log.Printf("xvay listening on %s", addr)
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}
