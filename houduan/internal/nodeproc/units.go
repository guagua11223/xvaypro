package nodeproc

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const xrayUnit = `[Unit]
Description=飞连 Xray node %i
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=__XRAY__ run -c __DATA__/nodes/%i/xray.json
Restart=on-failure
RestartSec=2
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
`

const hy2Unit = `[Unit]
Description=飞连 Hysteria2 node %i
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=__HY2__ server -c __DATA__/nodes/%i/hysteria2.json
Restart=on-failure
RestartSec=2
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
`

func ensureUnits(dataDir string) error {
	if _, err := exec.LookPath("systemctl"); err != nil {
		return nil
	}
	xrayBin := binPath("xray", "/usr/local/bin/xray")
	hy2Bin := binPath("hysteria", "/usr/local/bin/hysteria")
	if xrayBin == "" || hy2Bin == "" {
		return nil
	}
	dir, err := filepath.Abs(dataDir)
	if err != nil {
		return err
	}
	xrayText := strings.ReplaceAll(strings.ReplaceAll(xrayUnit, "__XRAY__", xrayBin), "__DATA__", dir)
	hy2Text := strings.ReplaceAll(strings.ReplaceAll(hy2Unit, "__HY2__", hy2Bin), "__DATA__", dir)
	changed, err := writeIfChanged("/etc/systemd/system/xvay-xray@.service", xrayText)
	if err != nil {
		return err
	}
	hy2Changed, err := writeIfChanged("/etc/systemd/system/xvay-hy2@.service", hy2Text)
	if err != nil {
		return err
	}
	if changed || hy2Changed {
		if out, err := exec.Command("systemctl", "daemon-reload").CombinedOutput(); err != nil {
			return wrap(err, out)
		}
	}
	return nil
}

func binPath(name, fallback string) string {
	if path, err := exec.LookPath(name); err == nil {
		return path
	}
	if _, err := os.Stat(fallback); err == nil {
		return fallback
	}
	return ""
}

func writeIfChanged(path, text string) (bool, error) {
	current, err := os.ReadFile(path)
	if err == nil && string(current) == text {
		return false, nil
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return false, err
	}
	return true, os.WriteFile(path, []byte(text), 0o644)
}

func wrap(err error, out []byte) error {
	if len(out) == 0 {
		return err
	}
	return &cmdError{err: err, out: strings.TrimSpace(string(out))}
}

type cmdError struct {
	err error
	out string
}

func (e *cmdError) Error() string { return e.err.Error() + ": " + e.out }
