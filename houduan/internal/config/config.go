package config

import (
	"bufio"
	"os"
	"strconv"
	"strings"
)

// Config is the process configuration. Values come from the environment.
// A local .env file fills in keys that are not already set.
type Config struct {
	Port             int
	Host             string
	DataDir          string
	DatabasePath     string
	PublicBaseURL    string
	AdminToken       string
	TrialBytes       int64
	TrialDays        int64
	SessionTTLMs     int64
	NodeOfflineMs    int64
	AcceptAppTraffic bool
}

func Load() Config {
	loadDotEnv(".env")
	dataDir := env("DATA_DIR", "./data")
	return Config{
		Port:             int(numberEnv("PORT", 8787)),
		Host:             env("HOST", "0.0.0.0"),
		DataDir:          dataDir,
		DatabasePath:     env("DATABASE_PATH", dataDir+"/xvay.sqlite"),
		PublicBaseURL:    strings.TrimRight(env("PUBLIC_BASE_URL", "http://127.0.0.1:8787"), "/"),
		AdminToken:       os.Getenv("ADMIN_TOKEN"),
		TrialBytes:       numberEnv("TRIAL_BYTES", 10*1024*1024*1024),
		TrialDays:        numberEnv("TRIAL_DAYS", 7),
		SessionTTLMs:     numberEnv("SESSION_TTL_MS", 30*24*3600*1000),
		NodeOfflineMs:    numberEnv("NODE_OFFLINE_MS", 180_000),
		AcceptAppTraffic: os.Getenv("ACCEPT_APP_TRAFFIC") == "1",
	}
}

func env(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func numberEnv(key string, fallback int64) int64 {
	raw := os.Getenv(key)
	if raw == "" {
		return fallback
	}
	n, err := strconv.ParseInt(raw, 10, 64)
	if err != nil {
		return fallback
	}
	return n
}

// loadDotEnv reads KEY=VALUE lines and does not override existing variables.
func loadDotEnv(path string) {
	file, err := os.Open(path)
	if err != nil {
		return
	}
	defer file.Close()
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		key, value, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		key = strings.TrimSpace(key)
		value = strings.Trim(strings.TrimSpace(value), `"'`)
		if key == "" || os.Getenv(key) != "" {
			continue
		}
		_ = os.Setenv(key, value)
	}
}
