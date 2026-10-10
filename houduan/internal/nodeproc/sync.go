package nodeproc

import (
	"context"
	"log"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"time"

	"xvay/houduan/internal/config"
	"xvay/houduan/internal/protocol"
	"xvay/houduan/internal/render"
	"xvay/houduan/internal/store"
	"xvay/houduan/internal/subscription"
)

// EnsureDefault creates the public node when the database has none.
// Loopback addresses are skipped so local tests stay empty until they create a node.
func EnsureDefault(db *store.Store, cfg config.Config) error {
	count, err := db.CountNodes()
	if err != nil || count > 0 {
		return err
	}
	parsed, err := url.Parse(cfg.PublicBaseURL)
	if err != nil {
		return nil
	}
	host := parsed.Hostname()
	if host == "" || host == "127.0.0.1" || host == "localhost" {
		return nil
	}
	shortID, err := protocol.GenerateShortID()
	if err != nil {
		return err
	}
	_, err = db.CreateNode(store.NodeInput{
		Name: "新加坡", Region: "新加坡", CountryCode: "SG", Host: host,
		Enabled: true, Remark: "默认节点",
		XrayEnabled: true, XrayPort: 443, XrayAPIPort: 10085,
		RealityShortIDs: []string{shortID},
		RealitySNI:      "www.microsoft.com", RealityDest: "www.microsoft.com:443",
		RealitySpiderX: "/", RealityFingerprint: "chrome", RealityFlow: "xtls-rprx-vision",
		Hy2Enabled: true, Hy2Port: 8443, Hy2SNI: "www.microsoft.com", Hy2Insecure: true,
		Hy2UpMbps: 100, Hy2DownMbps: 100,
	})
	return err
}

// Sync writes Xray and Hysteria configs for every enabled node and restarts the local units.
func Sync(db *store.Store, cfg config.Config) error {
	if os.Getenv("XVAY_SKIP_NODE_SYNC") == "1" {
		log.Printf("skip node sync")
		return nil
	}
	if err := ensureUnits(cfg.DataDir); err != nil {
		log.Printf("node units: %v", err)
	}
	nodes, err := db.ListNodes()
	if err != nil {
		return err
	}
	for _, node := range nodes {
		if !node.Enabled {
			continue
		}
		if err := ensureHy2Cert(cfg, node); err != nil {
			log.Printf("hy2 cert node %d: %v", node.ID, err)
		}
		bundle, err := subscription.NodeBundle(db, cfg, node)
		if err != nil {
			return err
		}
		if _, err := render.WriteBundle(cfg, bundle); err != nil {
			return err
		}
		if _, err := db.TouchNode(node.ID, true); err != nil {
			log.Printf("touch node %d: %v", node.ID, err)
		}
		id := strconv.FormatInt(node.ID, 10)
		if node.XrayEnabled {
			tryRestart("xvay-xray@" + id)
		}
		if node.Hy2Enabled {
			tryRestart("xvay-hy2@" + id)
		}
	}
	return nil
}

func ensureHy2Cert(cfg config.Config, node store.Node) error {
	if !node.Hy2Enabled {
		return nil
	}
	if _, err := exec.LookPath("openssl"); err != nil {
		return nil
	}
	paths := subscription.HysteriaPaths(cfg, node)
	if _, err := os.Stat(paths.Cert); err == nil {
		return nil
	}
	if err := os.MkdirAll(filepath.Dir(paths.Cert), 0o755); err != nil {
		return err
	}
	cmd := exec.Command(
		"openssl", "req", "-x509", "-nodes", "-newkey", "ec",
		"-pkeyopt", "ec_paramgen_curve:prime256v1",
		"-keyout", paths.Key, "-out", paths.Cert,
		"-subj", "/CN="+node.Hy2SNI, "-days", "3650",
	)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return err
	}
	_ = os.Chmod(paths.Key, 0o600)
	return nil
}

func tryRestart(unit string) {
	if _, err := exec.LookPath("systemctl"); err != nil {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, "systemctl", "restart", unit)
	if out, err := cmd.CombinedOutput(); err != nil {
		log.Printf("restart %s: %v %s", unit, err, out)
	}
}
