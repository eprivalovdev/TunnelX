import Foundation

/// Coordinates start/stop of both Xray core and SOCKS5 tunnel.
internal final class XrayTunnelController {
	private let xrayRunner: XrayCoreRunner
	private let socksController: SocksTunnelRunner
	
	init(
		xrayRunner: XrayCoreRunner = DefaultXrayCoreRunner(),
		socksController: SocksTunnelRunner = DefaultSocksTunnelRunner()
	) {
		self.xrayRunner = xrayRunner
		self.socksController = socksController
	}
	
	func startTunnelServices(configs: TunnelConfig) throws {
		try startSocks5Tunnel(config: configs.socks5Config)
		try startXray(configPath: configs.xrayConfigPath, geoDataDir: configs.geoDataDir)
	}
	
	func stopTunnelServices() {
		stopServices()
	}
	
	// MARK: - Private
	private func startXray(configPath: String, geoDataDir: String) throws {
		try xrayRunner.run(dataDir: geoDataDir, configPath: configPath)
	}
	
	private func startSocks5Tunnel(config: HevSocks5TunnelConfig) throws {
		socksController.run(config: config) { result in
			// SOCKS5 tunnel callback - result code indicates success/failure
			// Future enhancement: Add proper logging infrastructure
		}
	}
	
	private func stopServices() {
		socksController.quit()
		do { try xrayRunner.stop() } catch {}
	}
}
