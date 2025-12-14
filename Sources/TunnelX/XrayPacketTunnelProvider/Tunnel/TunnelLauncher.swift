import NetworkExtension

/// Launches and stops the Packet Tunnel connection with prepared options.
public final class TunnelLauncher {
	
	private let xrayLogService: XrayLogService
	
	public init(logService: XrayLogService = XrayLogService()) {
		self.xrayLogService = logService
	}
	
	public func startTunnel(
		manager: NEVPNManager,
		config: TunnelConfig,
		options: [String: NSObject]? = nil,
		completion: @escaping (Error?) -> Void
	) {
		do {
			let startOptions = try makeTunnelOptions(config: config, options: options)
			resetLogs()
			try manager.connection.startVPNTunnel(options: startOptions)
			completion(nil)
		} catch {
			completion(error)
		}
	}
	
	public func startTunnel(manager: NEVPNManager, config: TunnelConfig, options: [String: NSObject]? = nil) throws {
		let startOptions = try makeTunnelOptions(config: config, options: options)
		resetLogs()
		try manager.connection.startVPNTunnel(options: startOptions)
	}
	
	public func stopTunnel(manager: NEVPNManager) {
		manager.connection.stopVPNTunnel()
	}
	
	private func resetLogs() {
		func resetFile(at url: URL) throws {
			let fm = FileManager.default
			if fm.fileExists(atPath: url.path) {
				try fm.removeItem(at: url)
			}
			fm.createFile(atPath: url.path, contents: nil)
		}
		
		do {
			try resetFile(at: xrayLogService.getLogFiles().error)
			try resetFile(at: xrayLogService.getLogFiles().access)
		} catch {
			print("Failed to reset logs: \(error)")
		}
	}
	
	private func makeTunnelOptions(config: TunnelConfig, options: [String: NSObject]?) throws -> [String: NSObject] {
		let data = try JSONEncoder().encode(config)
		var mergedOptions: [String: NSObject] = options ?? [:]
		mergedOptions["tunnelConfig"] = data as NSObject
		return mergedOptions
	}
}
