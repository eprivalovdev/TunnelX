import Foundation
import NetworkExtension

/// High-level facade that prepares configs, downloads GeoData and launches/stops the tunnel.
/// It composes `XrayConfigBuilder`, `XrayConfigurationWriter`, and `TunnelLauncher`.
@MainActor
public final class XrayTunnelService {
	private let builder: XrayConfigBuilder
	private let writer: XrayConfigurationWriter
	private let logService: XrayLogService
	private let launcher: TunnelLauncher
	
	public init() {
		self.builder = XrayConfigBuilder()
		self.writer = XrayConfigurationWriter()
		self.logService = XrayLogService()
		self.launcher = TunnelLauncher(logService: logService)
		
		guard !DefaultsSuite.currentAppGroup.isEmpty else {
			fatalError("XrayTunnelService requires App Group configuration. Call Xray.configure(appGroup:) before creating XrayTunnelService")
		}
	}
	
	/// Builds `TunnelConfig` and writes config files into the App Group container.
	public func prepareConfigs(from source: XrayConfigBuilder.Source) throws -> TunnelConfig {
		// Build Xray configuration
		let xrayConfigData = try builder.build(from: source)
		let xrayConfigURL = try writer.writeConfiguration(xrayConfigData)
		
		// Build SOCKS5 configuration
		let socksConfigURL = try writer.writeSocks5Config(address: XrayTunnelSettings.tunnelAddress)
		
		// Get GeoData directory
		guard let geoDir = GeoDataManager(appGroup: DefaultsSuite.currentAppGroup).geoDataDirectoryPath()?.path else {
			throw TunnelXError.geoDataContainerUnavailable
		}
		
		return TunnelConfig(
			xrayConfigPath: xrayConfigURL.path,
			socks5Config: .file(path: socksConfigURL),
			geoDataDir: geoDir
		)
	}
	
	/// Starts the tunnel by building configuration and delegating to `TunnelLauncher`.
	public func start(
		manager: NEVPNManager,
		source: XrayConfigBuilder.Source,
		options: [String: NSObject]? = nil,
		completion: @escaping (Error?) -> Void
	) {
		do {
			let config = try prepareConfigs(from: source)
			launcher.startTunnel(manager: manager, config: config, options: options, completion: completion)
		} catch {
			completion(error)
		}
	}
	
	/// Synchronous variant of tunnel start.
	public func start(manager: NEVPNManager, source: XrayConfigBuilder.Source, options: [String: NSObject]? = nil) throws {
		let config = try prepareConfigs(from: source)
		try launcher.startTunnel(manager: manager, config: config, options: options)
	}
	
	/// Stops the tunnel.
	public func stop(manager: NEVPNManager) {
		launcher.stopTunnel(manager: manager)
	}
	
	/// Paths to Xray log files in the App Group container.
	public var logFiles: LogFiles {
		logService.getLogFiles()
	}
	
	/// Downloads GeoData files using the configuration stored in XrayTunnelSettings.
	/// - Throws: `TunnelXError` if download fails
	public func downloadGeoData() async throws {
		let config = XrayTunnelSettings.geoDataConfig
		let geoDataManager = GeoDataManager(appGroup: DefaultsSuite.currentAppGroup, configuration: config)
		try await geoDataManager.downloadAndSaveGeoFiles()
	}
	
	/// Downloads GeoData files using a custom configuration.
	/// - Parameter configuration: Custom GeoData configuration
	/// - Throws: `TunnelXError` if download fails
	public func downloadGeoData(configuration: GeoDataManager.Configuration) async throws {
		let geoDataManager = GeoDataManager(appGroup: DefaultsSuite.currentAppGroup, configuration: configuration)
		try await geoDataManager.downloadAndSaveGeoFiles()
	}
}

