package api

import (
	"encoding/json"
	"errors"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"xvay/houduan/internal/errs"
	"xvay/houduan/internal/store"
	"xvay/houduan/internal/subscription"
)

var deviceIDPattern = regexp.MustCompile(`^[A-Za-z0-9_.:-]{8,64}$`)

func (s *Server) appConnect(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	deviceID, err := parseDeviceID(body["deviceId"])
	if err != nil {
		return err
	}
	nodeID, err := parseOptionalID(body["nodeId"])
	if err != nil {
		return err
	}
	region, _ := body["region"].(string)
	region = strings.TrimSpace(region)
	if len(region) > 64 {
		return badRequest("线路名称过长")
	}

	nodes, err := s.db.ListNodes()
	if err != nil {
		return err
	}
	now := time.Now().UnixMilli()
	node, err := subscription.PickNode(nodes, nodeID, region, now, s.cfg.NodeOfflineMs)
	if err != nil {
		return err
	}
	profile, protocolName, err := subscription.ClientProfile(user, node)
	if err != nil {
		return err
	}
	if err := s.db.BeginConnect(user.ID, deviceID, node.ID, protocolName, now, user.DeviceLimit); err != nil {
		if errors.Is(err, store.ErrDeviceLimit) {
			return forbidden("同时在线设备已达上限")
		}
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{
		"node":        publicNode(node, now, s.cfg.NodeOfflineMs),
		"protocol":    protocolName,
		"profile":     profile,
		"connectedAt": now,
	})
	return nil
}

func (s *Server) appDisconnect(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	deviceID, err := parseDeviceID(body["deviceId"])
	if err != nil {
		return err
	}
	if err := s.db.EndConnect(user.ID, deviceID, time.Now().UnixMilli()); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"disconnected": true})
	return nil
}

func parseDeviceID(value any) (string, error) {
	text, _ := value.(string)
	text = strings.TrimSpace(text)
	if !deviceIDPattern.MatchString(text) {
		return "", errs.New(http.StatusBadRequest, "VALIDATION", "设备标识不正确")
	}
	return text, nil
}

func parseOptionalID(value any) (int64, error) {
	if value == nil {
		return 0, nil
	}
	if text, ok := value.(string); ok && strings.TrimSpace(text) == "" {
		return 0, nil
	}
	var raw string
	switch n := value.(type) {
	case json.Number:
		raw = n.String()
	case string:
		raw = strings.TrimSpace(n)
	case float64:
		raw = strconv.FormatInt(int64(n), 10)
	case int:
		raw = strconv.Itoa(n)
	case int64:
		raw = strconv.FormatInt(n, 10)
	default:
		return 0, badRequest("节点编号不正确")
	}
	id, err := strconv.ParseInt(raw, 10, 64)
	if err != nil || id < 0 {
		return 0, badRequest("节点编号不正确")
	}
	return id, nil
}
