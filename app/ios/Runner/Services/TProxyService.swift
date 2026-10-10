import Foundation
import NetworkExtension
import Libv2raymobile


class TProxyService {
    public var isCoreActive = false;
    public var isTunActive = false;
    public var isSystemProxyActive = false;
    weak var statusChangeListener: StatusChangeListener?

    protocol StatusChangeListener: AnyObject {
        func onAllStatusChange(isCoreActive: Bool)
        func onCoreStatusChange(isCoreActive: Bool)
        func onTunStatusChange(isTunActive: Bool)
    }

    func setStatusChangeListener(_ listener: StatusChangeListener?) {
        self.statusChangeListener = listener
    }

    private func notifyAppDelegateAllStatusChange() {
        statusChangeListener?.onAllStatusChange(isCoreActive: isCoreActive)
    }

    private func notifyAppDelegateCoreStatusChange() {
        statusChangeListener?.onCoreStatusChange(isCoreActive: isCoreActive)
    }

    private func notifyAppDelegateTunStatusChange() {
        statusChangeListener?.onTunStatusChange(isTunActive: isTunActive)
    }

    func startAll(){
        startCore()
        startTun()
        notifyAppDelegateAllStatusChange()
    }

    func stopAll(){
        stopTun()
        stopCore()
        notifyAppDelegateAllStatusChange()
    }

    public var coreManager: Libv2raymobileCoreManager?
    private let preferences = UserDefaults.standard

    func startCore(){
        let geoipPath = Bundle.main.path(forResource: "geoip", ofType: "dat")
        let assetPath = (geoipPath! as NSString).deletingLastPathComponent
        let configFilePath = getConfigFilePath()

        coreManager = Libv2raymobileCoreManager()
        Libv2raymobileSetEnv("v2ray.location.asset", assetPath)
        Libv2raymobileSetEnv("xray.location.asset", assetPath)
        coreManager!.runConfig(configFilePath)

        isCoreActive = true
        notifyAppDelegateCoreStatusChange()
    }

    func stopCore(){
        coreManager?.stop()
        coreManager = nil
        isCoreActive = false
        notifyAppDelegateCoreStatusChange()
    }

    private func getConfigFilePath() -> String {
        let appPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appPath.appendingPathComponent("conf/core.gen.json").path
    }

    func startTun(){
        let bundleId = (Bundle.main.bundleIdentifier ?? "") + ".PacketTunnel"
        let coreConfig = (try? String(contentsOfFile: getConfigFilePath(), encoding: .utf8)) ?? ""
        let tunConfig = (try? String(contentsOfFile: tunConfigFilePath(), encoding: .utf8)) ?? ""
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, _ in
            guard let self else { return }
            let manager = managers?.first ?? NETunnelProviderManager()
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = bundleId
            proto.serverAddress = "讯连宝"
            let storedPort = preferences.integer(forKey: "flutter.app.http.port")
            let httpPort = storedPort > 0 ? storedPort : 15492
            proto.providerConfiguration = [
                "coreConfig": coreConfig,
                "tunConfig": tunConfig,
                "httpPort": httpPort,
            ]
            manager.protocolConfiguration = proto
            manager.localizedDescription = "讯连宝"
            manager.isEnabled = true
            manager.saveToPreferences { error in
                if error != nil {
                    self.finishTunStart(false)
                    return
                }
                manager.loadFromPreferences { error in
                    if error != nil {
                        self.finishTunStart(false)
                        return
                    }
                    do {
                        try manager.connection.startVPNTunnel()
                        self.finishTunStart(true)
                    } catch {
                        self.finishTunStart(false)
                    }
                }
            }
        }
    }

    private func finishTunStart(_ started: Bool) {
        isTunActive = started
        notifyAppDelegateTunStatusChange()
    }
    
    func stopTun(){
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, _ in
            managers?.first?.connection.stopVPNTunnel()
            self?.isTunActive = false
            self?.notifyAppDelegateTunStatusChange()
        }
    }

    private func tunConfigFilePath() -> String {
        let appPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appPath.appendingPathComponent("conf/tun2socks.hev_socks5_tunnel.gen.yaml").path
    }
}
