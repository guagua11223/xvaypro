import Foundation
import NetworkExtension

/// Safari 走主 App 里 xray 的本地 HTTP 代理。
/// 默认路由让系统把网页流量交给这条隧道，节点 IP 和 DNS 排除在外，避免拨号绕回隧道后被丢弃。
class PacketTunnelProvider: NEPacketTunnelProvider {
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let port = proxyPort(options)
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.mtu = 1500

        let ipv4 = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.255.255"])
        ipv4.includedRoutes = [NEIPv4Route.default()]
        ipv4.excludedRoutes = excludedRoutes()
        settings.ipv4Settings = ipv4

        let dns = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        settings.dnsSettings = dns

        let proxy = NEProxySettings()
        proxy.httpEnabled = true
        proxy.httpServer = NEProxyServer(address: "127.0.0.1", port: port)
        proxy.httpsEnabled = true
        proxy.httpsServer = NEProxyServer(address: "127.0.0.1", port: port)
        proxy.excludeSimpleHostnames = true
        proxy.exceptionList = ["localhost", "127.0.0.1", "*.local"]
        settings.proxySettings = proxy

        setTunnelNetworkSettings(settings) { [weak self] error in
            if error == nil {
                self?.discardPackets()
            }
            completionHandler(error)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    private func discardPackets() {
        packetFlow.readPackets { [weak self] _, _ in
            self?.discardPackets()
        }
    }

    private func proxyPort(_ options: [String: NSObject]?) -> Int {
        if let port = plistInt(options?["httpPort"]), port > 0 {
            return port
        }
        if let proto = protocolConfiguration as? NETunnelProviderProtocol,
           let config = proto.providerConfiguration,
           let port = plistInt(config["httpPort"]),
           port > 0 {
            return port
        }
        return 15492
    }

    private func excludedRoutes() -> [NEIPv4Route] {
        var routes = [
            NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),
            NEIPv4Route(destinationAddress: "1.1.1.1", subnetMask: "255.255.255.255"),
            NEIPv4Route(destinationAddress: "8.8.8.8", subnetMask: "255.255.255.255"),
        ]
        for address in serverAddresses() where isIPv4(address) {
            routes.append(NEIPv4Route(destinationAddress: address, subnetMask: "255.255.255.255"))
        }
        return routes
    }

    private func serverAddresses() -> [String] {
        guard let proto = protocolConfiguration as? NETunnelProviderProtocol,
              let config = proto.providerConfiguration,
              let core = config["coreConfig"] as? String,
              let data = core.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let outbounds = json["outbounds"] as? [[String: Any]] else {
            return []
        }
        var addresses: [String] = []
        for outbound in outbounds {
            guard let settings = outbound["settings"] as? [String: Any] else { continue }
            if let vnext = settings["vnext"] as? [[String: Any]] {
                for node in vnext {
                    if let address = node["address"] as? String {
                        addresses.append(address)
                    }
                }
            }
            if let servers = settings["servers"] as? [[String: Any]] {
                for server in servers {
                    if let address = server["address"] as? String {
                        addresses.append(address)
                    }
                }
            }
        }
        return addresses
    }

    private func isIPv4(_ value: String) -> Bool {
        let parts = value.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let n = Int(part), n >= 0, n <= 255 else { return false }
            return true
        }
    }

    private func plistInt(_ value: Any?) -> Int? {
        if let number = value as? Int { return number }
        if let number = value as? NSNumber { return number.intValue }
        return nil
    }
}
