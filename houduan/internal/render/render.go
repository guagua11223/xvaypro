package render

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strconv"

	"xvay/houduan/internal/config"
	"xvay/houduan/internal/subscription"
)

func WriteBundle(cfg config.Config, bundle subscription.Bundle) (map[string]string, error) {
	dir := filepath.Join(cfg.DataDir, "nodes", strconv.FormatInt(bundle.Meta.NodeID, 10))
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return nil, err
	}
	files := map[string]string{"meta": filepath.Join(dir, "meta.json")}
	if bundle.Xray != nil {
		files["xray"] = filepath.Join(dir, "xray.json")
		if err := writeJSON(files["xray"], bundle.Xray); err != nil {
			return nil, err
		}
	}
	if bundle.Hysteria2 != nil {
		files["hysteria2"] = filepath.Join(dir, "hysteria2.json")
		if err := writeJSON(files["hysteria2"], bundle.Hysteria2); err != nil {
			return nil, err
		}
	}
	if err := writeJSON(files["meta"], bundle.Meta); err != nil {
		return nil, err
	}
	return files, nil
}

func writeJSON(path string, value any) error {
	raw, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		return err
	}
	raw = append(raw, '\n')
	return os.WriteFile(path, raw, 0o644)
}
