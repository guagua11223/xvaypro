package nodeproc

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"log"
	"net"
	"net/http"
	"os/exec"
	"strconv"
	"time"

	"xvay/houduan/internal/protocol"
	"xvay/houduan/internal/stats"
	"xvay/houduan/internal/store"
)

// Collect pulls Xray and Hysteria counters into the user table and marks the node online.
func Collect(db *store.Store) {
	nodes, err := db.ListNodes()
	if err != nil {
		log.Printf("collect nodes: %v", err)
		return
	}
	for _, node := range nodes {
		if !node.Enabled {
			continue
		}
		online := false
		if node.XrayEnabled && collectXray(db, node) {
			online = true
		}
		if node.Hy2Enabled && collectHysteria(db, node) {
			online = true
		}
		if _, err := db.TouchNode(node.ID, online); err != nil {
			log.Printf("touch node %d: %v", node.ID, err)
		}
	}
}

// Run collects on a fixed interval until ctx is canceled.
func Run(ctx context.Context, db *store.Store) {
	Collect(db)
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			Collect(db)
		}
	}
}

func collectXray(db *store.Store, node store.Node) bool {
	if !portOpen(node.XrayPort) {
		return false
	}
	bin := binPath("xray", "/usr/local/bin/xray")
	if bin == "" {
		return true
	}
	ctx, cancel := context.WithTimeout(context.Background(), 8*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, bin, "api", "statsquery",
		"--server=127.0.0.1:"+strconv.Itoa(node.XrayAPIPort),
		"-pattern", "user>>>",
	)
	out, err := cmd.Output()
	if err != nil || len(out) == 0 {
		return true
	}
	var payload any
	dec := json.NewDecoder(bytes.NewReader(out))
	dec.UseNumber()
	if err := dec.Decode(&payload); err != nil {
		log.Printf("xray stats node %d: %v", node.ID, err)
		return true
	}
	apply(db, node.ID, stats.ParseXrayStats(payload))
	return true
}

func collectHysteria(db *store.Store, node store.Node) bool {
	listen := protocol.Hy2StatsListen(node.ID)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://"+listen+"/traffic", nil)
	if err != nil {
		return false
	}
	if node.Hy2StatsSecret != "" {
		req.Header.Set("Authorization", node.Hy2StatsSecret)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return false
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		return false
	}
	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return true
	}
	var payload map[string]any
	dec := json.NewDecoder(bytes.NewReader(body))
	dec.UseNumber()
	if err := dec.Decode(&payload); err != nil {
		log.Printf("hy2 stats node %d: %v", node.ID, err)
		return true
	}
	delete(payload, "_")
	apply(db, node.ID, stats.ParseHysteriaTraffic(payload, "upload"))
	return true
}

func apply(db *store.Store, nodeID int64, rows []map[string]any) {
	if len(rows) == 0 {
		return
	}
	entries := make([]store.TrafficEntry, 0, len(rows))
	for _, row := range rows {
		email, _ := row["email"].(string)
		if email == "" || email == "_" {
			continue
		}
		upload, _ := row["upload"].(int64)
		download, _ := row["download"].(int64)
		entries = append(entries, store.TrafficEntry{Email: email, Upload: upload, Download: download})
	}
	if len(entries) == 0 {
		return
	}
	if _, err := db.ApplyTraffic(nodeID, entries, "absolute"); err != nil {
		log.Printf("apply traffic node %d: %v", nodeID, err)
	}
}

func portOpen(port int) bool {
	conn, err := net.DialTimeout("tcp", "127.0.0.1:"+strconv.Itoa(port), 500*time.Millisecond)
	if err != nil {
		return false
	}
	conn.Close()
	return true
}
