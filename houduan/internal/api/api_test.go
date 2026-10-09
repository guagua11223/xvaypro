package api_test

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"testing"

	"xvay/houduan/internal/api"
	"xvay/houduan/internal/config"
	"xvay/houduan/internal/protocol"
	"xvay/houduan/internal/store"
)

func TestRealityKeyRoundTrip(t *testing.T) {
	keys, err := protocol.GenerateRealityKeys()
	if err != nil {
		t.Fatal(err)
	}
	public, err := protocol.PublicKeyFromPrivate(keys.PrivateKey)
	if err != nil {
		t.Fatal(err)
	}
	if public != keys.PublicKey {
		t.Fatalf("public key mismatch: %s != %s", public, keys.PublicKey)
	}
}

func TestAppAndNodeFlow(t *testing.T) {
	cfg := config.Config{
		DataDir:          t.TempDir(),
		DatabasePath:     ":memory:",
		PublicBaseURL:    "http://127.0.0.1:8787",
		AdminToken:       "admin-token",
		TrialBytes:       1024,
		TrialDays:        7,
		SessionTTLMs:     3_600_000,
		NodeOfflineMs:    180_000,
		AcceptAppTraffic: true,
	}
	db, err := store.Open(cfg)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { db.Close() })
	handler := api.New(cfg, db)

	reg := call(t, handler, http.MethodPost, "/api/app/register", "", map[string]any{
		"email": "user@example.com", "password": "password1",
	})
	if reg.Status != http.StatusCreated {
		t.Fatalf("register status %d body %s", reg.Status, reg.Raw)
	}
	token := reg.Data["token"].(string)
	user := reg.Data["user"].(map[string]any)
	if user["subscriptionProtocol"] != "anyportal-rest" {
		t.Fatalf("subscription protocol: %v", user["subscriptionProtocol"])
	}
	subURL := user["subscriptionUrl"].(string)
	if !strings.Contains(subURL, "/api/sub/") {
		t.Fatalf("subscription url: %s", subURL)
	}

	bad := call(t, handler, http.MethodPost, "/api/app/login", "", map[string]any{
		"email": "user@example.com", "password": "wrong-password",
	})
	if bad.Status != http.StatusUnauthorized {
		t.Fatalf("login status %d", bad.Status)
	}

	me := call(t, handler, http.MethodGet, "/api/app/me", token, nil)
	if me.Status != http.StatusOK || me.Data["email"] != "user@example.com" {
		t.Fatalf("me: %d %s", me.Status, me.Raw)
	}

	created := call(t, handler, http.MethodPost, "/api/admin/nodes", "admin-token", map[string]any{
		"name": "东京", "host": "edge.example.com", "region": "东京", "countryCode": "jp",
	})
	if created.Status != http.StatusCreated {
		t.Fatalf("create node %d %s", created.Status, created.Raw)
	}
	nodeID := int64(created.Data["id"].(float64))
	secret := created.Data["secret"].(string)
	xray := created.Data["xray"].(map[string]any)
	if xray["publicKey"] == "" || xray["privateKey"] == "" {
		t.Fatal("missing reality keys")
	}
	protocols := created.Data["protocols"].([]any)
	if len(protocols) != 2 || protocols[0] != "reality" || protocols[1] != "hysteria2" {
		t.Fatalf("protocols: %v", protocols)
	}

	nodes := call(t, handler, http.MethodGet, "/api/app/nodes", token, nil)
	list := nodes.Data["nodes"].([]any)
	if len(list) != 1 {
		t.Fatalf("nodes: %s", nodes.Raw)
	}

	subPath := subURL[strings.Index(subURL, "/api/sub/"):]
	sub := call(t, handler, http.MethodGet, subPath, "", nil)
	if sub.Status != http.StatusOK {
		t.Fatalf("sub %d %s", sub.Status, sub.Raw)
	}
	profiles := sub.Body["profiles"].([]any)
	if len(profiles) != 2 {
		t.Fatalf("profiles: %s", sub.Raw)
	}
	reality := profiles[0].(map[string]any)
	if reality["coreType"] != "xray" {
		t.Fatalf("core: %v", reality["coreType"])
	}
	core := reality["coreConfig"].(map[string]any)
	outbound := core["outbounds"].([]any)[0].(map[string]any)
	stream := outbound["streamSettings"].(map[string]any)
	if stream["security"] != "reality" {
		t.Fatalf("security: %v", stream["security"])
	}
	hy2 := profiles[1].(map[string]any)
	if hy2["coreType"] != "hysteria2" {
		t.Fatalf("hy2 core: %v", hy2["coreType"])
	}

	links := callRaw(t, handler, http.MethodGet, subPath+"?format=v2ray", "", nil)
	if links.Code != http.StatusOK || !strings.Contains(links.Body, "vless://") || !strings.Contains(links.Body, "hysteria2://") {
		t.Fatalf("links %d %s", links.Code, links.Body)
	}

	nodePath := "/api/node/" + strconv.FormatInt(nodeID, 10)
	xrayCfg := callRaw(t, handler, http.MethodGet, nodePath+"/xray", "", map[string]string{"X-Node-Secret": secret})
	if xrayCfg.Code != http.StatusOK || !strings.Contains(xrayCfg.Body, `"security":"reality"`) && !strings.Contains(xrayCfg.Body, `"security": "reality"`) {
		t.Fatalf("xray config %d %s", xrayCfg.Code, xrayCfg.Body)
	}
	if !strings.Contains(xrayCfg.Body, "vless") {
		t.Fatalf("xray config missing vless: %s", xrayCfg.Body)
	}
	hy2Cfg := callRaw(t, handler, http.MethodGet, nodePath+"/hysteria2", "", map[string]string{"X-Node-Secret": secret})
	if hy2Cfg.Code != http.StatusOK || !strings.Contains(hy2Cfg.Body, "userpass") {
		t.Fatalf("hysteria config %d %s", hy2Cfg.Code, hy2Cfg.Body)
	}

	beat := callWith(t, handler, http.MethodPost, nodePath+"/heartbeat", "", map[string]string{"X-Node-Secret": secret}, map[string]any{"online": true})
	if beat.Status != http.StatusOK || beat.Data["online"] != true {
		t.Fatalf("heartbeat %s", beat.Raw)
	}
	onlineNodes := call(t, handler, http.MethodGet, "/api/app/nodes", token, nil)
	if onlineNodes.Data["nodes"].([]any)[0].(map[string]any)["online"] != true {
		t.Fatalf("node offline after heartbeat: %s", onlineNodes.Raw)
	}

	reported := callWith(t, handler, http.MethodPost, nodePath+"/traffic", "", map[string]string{"X-Node-Secret": secret}, map[string]any{
		"mode": "absolute",
		"xray": map[string]any{
			"stat": []any{
				map[string]any{"name": "user>>>u1>>>traffic>>>uplink", "value": 100},
				map[string]any{"name": "user>>>u1>>>traffic>>>downlink", "value": 250},
			},
		},
	})
	if reported.Status != http.StatusOK {
		t.Fatalf("traffic %d %s", reported.Status, reported.Raw)
	}
	updated := reported.Data["updated"].([]any)[0].(map[string]any)
	if updated["upload"] != float64(100) || updated["download"] != float64(250) {
		t.Fatalf("counters: %v", updated)
	}
	again := callWith(t, handler, http.MethodPost, nodePath+"/traffic", "", map[string]string{"X-Node-Secret": secret}, map[string]any{
		"mode": "absolute",
		"users": []any{
			map[string]any{"email": "u1", "upload": 140, "download": 250},
		},
	})
	row := again.Data["updated"].([]any)[0].(map[string]any)
	if row["upload"] != float64(140) || row["download"] != float64(250) {
		t.Fatalf("delta counters: %v", row)
	}
}

func TestConnectButtonPicksNode(t *testing.T) {
	cfg := config.Config{
		DataDir:       t.TempDir(),
		DatabasePath:  ":memory:",
		PublicBaseURL: "http://127.0.0.1:8787",
		AdminToken:    "admin-token",
		TrialBytes:    1024,
		TrialDays:     7,
		SessionTTLMs:  3_600_000,
		NodeOfflineMs: 180_000,
	}
	db, err := store.Open(cfg)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { db.Close() })
	handler := api.New(cfg, db)

	reg := call(t, handler, http.MethodPost, "/api/app/register", "", map[string]any{
		"email": "tap@example.com", "password": "password1",
	})
	token := reg.Data["token"].(string)
	userID := int64(reg.Data["user"].(map[string]any)["id"].(float64))

	empty := call(t, handler, http.MethodPost, "/api/app/connect", token, map[string]any{
		"region": "auto", "deviceId": "device-one",
	})
	if empty.Status != http.StatusNotFound {
		t.Fatalf("empty connect %d %s", empty.Status, empty.Raw)
	}

	tokyo := call(t, handler, http.MethodPost, "/api/admin/nodes", "admin-token", map[string]any{
		"name": "东京", "host": "tyo.example.com", "region": "东京", "countryCode": "jp", "sortOrder": 2,
	})
	singapore := call(t, handler, http.MethodPost, "/api/admin/nodes", "admin-token", map[string]any{
		"name": "新加坡", "host": "sin.example.com", "region": "新加坡", "countryCode": "sg", "sortOrder": 1,
	})
	tokyoID := int64(tokyo.Data["id"].(float64))
	singaporeID := int64(singapore.Data["id"].(float64))
	callWith(t, handler, http.MethodPost, "/api/node/"+strconv.FormatInt(singaporeID, 10)+"/heartbeat", "", map[string]string{
		"X-Node-Secret": singapore.Data["secret"].(string),
	}, map[string]any{"online": false})

	auto := call(t, handler, http.MethodPost, "/api/app/connect", token, map[string]any{
		"region": "auto", "deviceId": "device-one",
	})
	if auto.Status != http.StatusOK {
		t.Fatalf("auto connect %d %s", auto.Status, auto.Raw)
	}
	if auto.Data["protocol"] != "reality" {
		t.Fatalf("protocol: %v", auto.Data["protocol"])
	}
	picked := auto.Data["node"].(map[string]any)
	if int64(picked["id"].(float64)) != tokyoID || picked["online"] != true {
		t.Fatalf("expected online tokyo, got %v", picked)
	}
	profile := auto.Data["profile"].(map[string]any)
	if profile["coreType"] != "xray" || profile["key"] != "n"+strconv.FormatInt(tokyoID, 10)+"-reality" {
		t.Fatalf("profile: %v", profile)
	}
	core := profile["coreConfig"].(map[string]any)
	outbound := core["outbounds"].([]any)[0].(map[string]any)
	if outbound["protocol"] != "vless" {
		t.Fatalf("outbound: %v", outbound["protocol"])
	}
	realityPrivate := tokyo.Data["xray"].(map[string]any)["privateKey"].(string)
	if strings.Contains(auto.Raw, realityPrivate) {
		t.Fatal("connect response leaked the reality private key")
	}
	keys := auto.Data["keys"].(map[string]any)
	if keys["publicKey"] == "" || keys["hash32"] == "" || keys["privateKey"] == "" {
		t.Fatalf("vless keys: %v", keys)
	}
	vnext := outbound["settings"].(map[string]any)["vnext"].([]any)[0].(map[string]any)
	account := vnext["users"].([]any)[0].(map[string]any)
	if account["encryption"] != "none" {
		t.Fatalf("encryption: %v", account["encryption"])
	}

	byRegion := call(t, handler, http.MethodPost, "/api/app/connect", token, map[string]any{
		"region": "sg", "deviceId": "device-one",
	})
	got := byRegion.Data["node"].(map[string]any)
	if int64(got["id"].(float64)) != singaporeID {
		t.Fatalf("region pick: %v", got)
	}

	byID := call(t, handler, http.MethodPost, "/api/app/connect", token, map[string]any{
		"nodeId": tokyoID, "deviceId": "device-one",
	})
	if int64(byID.Data["node"].(map[string]any)["id"].(float64)) != tokyoID {
		t.Fatalf("node id pick: %s", byID.Raw)
	}

	missing := call(t, handler, http.MethodPost, "/api/app/connect", token, map[string]any{
		"region": "frankfurt", "deviceId": "device-one",
	})
	if missing.Status != http.StatusNotFound {
		t.Fatalf("missing region %d", missing.Status)
	}

	patched := call(t, handler, http.MethodPatch, "/api/admin/users/"+strconv.FormatInt(userID, 10), "admin-token", map[string]any{
		"deviceLimit": 1,
	})
	if patched.Status != http.StatusOK {
		t.Fatalf("patch limit %d %s", patched.Status, patched.Raw)
	}
	second := call(t, handler, http.MethodPost, "/api/app/connect", token, map[string]any{
		"region": "auto", "deviceId": "device-two",
	})
	if second.Status != http.StatusForbidden {
		t.Fatalf("device limit %d %s", second.Status, second.Raw)
	}
	off := call(t, handler, http.MethodPost, "/api/app/disconnect", token, map[string]any{
		"deviceId": "device-one",
	})
	if off.Status != http.StatusOK || off.Data["disconnected"] != true {
		t.Fatalf("disconnect %s", off.Raw)
	}
	again := call(t, handler, http.MethodPost, "/api/app/connect", token, map[string]any{
		"region": "auto", "deviceId": "device-two",
	})
	if again.Status != http.StatusOK {
		t.Fatalf("connect after disconnect %d %s", again.Status, again.Raw)
	}
}

type result struct {
	Status int
	Raw    string
	Body   map[string]any
	Data   map[string]any
}

type rawResult struct {
	Code int
	Body string
}

func call(t *testing.T, handler http.Handler, method, path, token string, body map[string]any) result {
	t.Helper()
	return callWith(t, handler, method, path, token, nil, body)
}

func callWith(t *testing.T, handler http.Handler, method, path, token string, headers map[string]string, body map[string]any) result {
	t.Helper()
	raw := callRaw(t, handler, method, path, token, headers, body)
	var payload map[string]any
	if err := json.Unmarshal([]byte(raw.Body), &payload); err != nil {
		t.Fatalf("json %s: %v", raw.Body, err)
	}
	data, _ := payload["data"].(map[string]any)
	if payload["data"] != nil && data == nil {
		// subscription document is the body itself
		data = payload
	}
	return result{Status: raw.Code, Raw: raw.Body, Body: payload, Data: data}
}

func callRaw(t *testing.T, handler http.Handler, method, path, token string, extra ...any) rawResult {
	t.Helper()
	var headers map[string]string
	var body map[string]any
	if len(extra) > 0 {
		headers, _ = extra[0].(map[string]string)
	}
	if len(extra) > 1 {
		body, _ = extra[1].(map[string]any)
	}
	var reader io.Reader
	if body != nil {
		raw, err := json.Marshal(body)
		if err != nil {
			t.Fatal(err)
		}
		reader = bytes.NewReader(raw)
	}
	req := httptest.NewRequest(method, path, reader)
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	for key, value := range headers {
		req.Header.Set(key, value)
	}
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)
	return rawResult{Code: rec.Code, Body: rec.Body.String()}
}
