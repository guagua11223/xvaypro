package api

import (
	"net/http"

	"xvay/houduan/internal/stats"
	"xvay/houduan/internal/store"
	"xvay/houduan/internal/subscription"
	"xvay/houduan/internal/validate"
)

func (s *Server) nodeHeartbeat(w http.ResponseWriter, r *http.Request) error {
	id, err := idParam(r)
	if err != nil {
		return err
	}
	node, err := s.requireNode(r, id)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	online := true
	if value, ok := body["online"]; ok && value != nil {
		online, _ = value.(bool)
	}
	if _, err := s.db.TouchNode(node.ID, online); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": node.ID, "online": online})
	return nil
}

func (s *Server) nodeTraffic(w http.ResponseWriter, r *http.Request) error {
	id, err := idParam(r)
	if err != nil {
		return err
	}
	if _, err := s.requireNode(r, id); err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	mode := "delta"
	if value, ok := body["mode"]; ok && value != nil {
		text, _ := value.(string)
		if text != "" {
			mode = text
		}
	}
	if mode != "delta" && mode != "absolute" {
		return badRequest("mode 只能是 delta 或 absolute")
	}
	entries, err := trafficEntries(body)
	if err != nil {
		return err
	}
	result, err := s.db.ApplyTraffic(id, entries, mode)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, result)
	return nil
}

func (s *Server) nodeXray(w http.ResponseWriter, r *http.Request) error {
	bundle, err := s.nodeBundle(r)
	if err != nil {
		return err
	}
	if bundle.Xray == nil {
		return notFound("节点未启用 Reality")
	}
	writeJSON(w, http.StatusOK, bundle.Xray)
	return nil
}

func (s *Server) nodeHysteria(w http.ResponseWriter, r *http.Request) error {
	bundle, err := s.nodeBundle(r)
	if err != nil {
		return err
	}
	if bundle.Hysteria2 == nil {
		return notFound("节点未启用 Hysteria2")
	}
	writeJSON(w, http.StatusOK, bundle.Hysteria2)
	return nil
}

func (s *Server) nodeBundleRoute(w http.ResponseWriter, r *http.Request) error {
	bundle, err := s.nodeBundle(r)
	if err != nil {
		return err
	}
	writeJSON(w, http.StatusOK, bundle)
	return nil
}

func (s *Server) nodeBundle(r *http.Request) (subscription.Bundle, error) {
	id, err := idParam(r)
	if err != nil {
		return subscription.Bundle{}, err
	}
	node, err := s.requireNode(r, id)
	if err != nil {
		return subscription.Bundle{}, err
	}
	return subscription.NodeBundle(s.db, s.cfg, node)
}

func trafficEntries(body map[string]any) ([]store.TrafficEntry, error) {
	if raw, ok := body["users"]; ok && raw != nil {
		list, ok := raw.([]any)
		if !ok {
			return nil, badRequest("缺少 users、xray 或 hysteria2 流量数据")
		}
		entries := make([]store.TrafficEntry, 0, len(list))
		for _, item := range list {
			obj, ok := item.(map[string]any)
			if !ok {
				return nil, badRequest("流量计数必须是非负整数")
			}
			entry, err := entryFromMap(obj)
			if err != nil {
				return nil, err
			}
			entries = append(entries, entry)
		}
		return entries, nil
	}
	if raw, ok := body["xray"]; ok && raw != nil {
		return mapsToEntries(stats.ParseXrayStats(raw))
	}
	if raw, ok := body["hysteria2"]; ok && raw != nil {
		txIs, _ := body["txIs"].(string)
		return mapsToEntries(stats.ParseHysteriaTraffic(raw, txIs))
	}
	return nil, badRequest("缺少 users、xray 或 hysteria2 流量数据")
}

func mapsToEntries(rows []map[string]any) ([]store.TrafficEntry, error) {
	entries := make([]store.TrafficEntry, 0, len(rows))
	for _, row := range rows {
		entry, err := entryFromMap(row)
		if err != nil {
			return nil, err
		}
		entries = append(entries, entry)
	}
	return entries, nil
}

func entryFromMap(obj map[string]any) (store.TrafficEntry, error) {
	zero := int64(0)
	upload, err := validate.ParseBytes(obj["upload"], &zero)
	if err != nil {
		return store.TrafficEntry{}, err
	}
	download, err := validate.ParseBytes(obj["download"], &zero)
	if err != nil {
		return store.TrafficEntry{}, err
	}
	entry := store.TrafficEntry{
		UUID: stringField(obj["uuid"]), Email: stringField(obj["email"]),
		Upload: upload, Download: download,
	}
	if value, ok := obj["userId"]; ok && value != nil {
		id, err := validate.NonNegative(value, "用户")
		if err != nil {
			return store.TrafficEntry{}, err
		}
		entry.UserID = &id
	}
	return entry, nil
}

func stringField(value any) string {
	text, _ := value.(string)
	return text
}
