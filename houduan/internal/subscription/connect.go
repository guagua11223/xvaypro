package subscription

import (
	"strconv"
	"strings"

	"xvay/houduan/internal/errs"
	"xvay/houduan/internal/protocol"
	"xvay/houduan/internal/store"
)

// PickNode chooses the node a one-tap connect should use.
// An explicit node id is used as-is. Otherwise region "auto" prefers an online Reality node.
func PickNode(nodes []store.Node, nodeID int64, region string, now, offlineMs int64) (store.Node, error) {
	usable := make([]store.Node, 0, len(nodes))
	for _, node := range nodes {
		if node.Enabled && (node.XrayEnabled || node.Hy2Enabled) {
			usable = append(usable, node)
		}
	}
	if nodeID > 0 {
		for _, node := range usable {
			if node.ID == nodeID {
				return node, nil
			}
		}
		return store.Node{}, errs.New(404, "NO_NODE", "节点不存在或未启用")
	}
	matched := usable
	if !isAuto(region) {
		matched = matched[:0]
		for _, node := range usable {
			if matchesRegion(node, region) {
				matched = append(matched, node)
			}
		}
	}
	if len(matched) == 0 {
		return store.Node{}, errs.New(404, "NO_NODE", "没有可用节点")
	}
	best := matched[0]
	for _, node := range matched[1:] {
		if preferNode(node, best, now, offlineMs) {
			best = node
		}
	}
	return best, nil
}

// ClientProfile is the config the app starts after the connect button is pressed.
// Reality is preferred because the mobile client ships an embedded xray core.
func ClientProfile(user store.User, node store.Node) (map[string]any, string, error) {
	if err := assertAccess(user); err != nil {
		return nil, "", err
	}
	view := protocolNode(node)
	account := protocolUser(user)
	id := strconv.FormatInt(node.ID, 10)
	if node.XrayEnabled {
		return map[string]any{
			"name":       node.Name + " · Reality",
			"key":        "n" + id + "-reality",
			"coreType":   "xray",
			"format":     "json",
			"coreConfig": protocol.BuildXrayClient(view, account),
		}, "reality", nil
	}
	if node.Hy2Enabled {
		return map[string]any{
			"name":       node.Name + " · Hysteria2",
			"key":        "n" + id + "-hysteria2",
			"coreType":   "hysteria2",
			"format":     "json",
			"coreConfig": protocol.BuildHysteriaClient(view, account),
		}, "hysteria2", nil
	}
	return nil, "", errs.New(404, "NO_NODE", "节点没有可用协议")
}

func isAuto(region string) bool {
	switch strings.ToLower(strings.TrimSpace(region)) {
	case "", "auto", "自动":
		return true
	default:
		return false
	}
}

func matchesRegion(node store.Node, region string) bool {
	return strings.EqualFold(node.CountryCode, region) ||
		strings.EqualFold(strings.TrimSpace(node.Region), strings.TrimSpace(region)) ||
		strings.EqualFold(node.Name, strings.TrimSpace(region))
}

func preferNode(next, current store.Node, now, offlineMs int64) bool {
	nextOnline := nodeOnline(next, now, offlineMs)
	currentOnline := nodeOnline(current, now, offlineMs)
	if nextOnline != currentOnline {
		return nextOnline
	}
	if next.XrayEnabled != current.XrayEnabled {
		return next.XrayEnabled
	}
	if next.SortOrder != current.SortOrder {
		return next.SortOrder < current.SortOrder
	}
	return next.ID < current.ID
}

func nodeOnline(node store.Node, now, offlineMs int64) bool {
	return node.LastSeenAt > 0 && now-node.LastSeenAt <= offlineMs
}
