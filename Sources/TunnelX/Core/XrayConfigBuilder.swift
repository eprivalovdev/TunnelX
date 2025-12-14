import Foundation

/// Builds Xray tunnel configurations from various sources.
///
/// Responsibilities:
/// - Parse configuration from URLs, JSON strings, or Outbound models
/// - Resolve hostnames to IP addresses
/// - Generate complete Xray configurations with inbounds, outbounds, routing, DNS, and logging
///
/// For saving configurations to disk, use `XrayConfigurationWriter`.
public struct XrayConfigBuilder {

	/// The source of the configuration.
	public enum Source {
		/// Configuration from a URL (vless://, vmess://, etc.)
		case url(String)
		/// Configuration as a JSON string
		case json(String)
		/// Configuration from Outbound model
		case outbound(Outbound)
	}
	
	// MARK: - Constants
	
	private enum Constants {
		static let socksPort: Int = 10808
		static let inboundTag: String = "socks"
		static let directTag: String = "direct"
		static let blockTag: String = "block"
	}
	
	// MARK: - Properties
	
	private let logService: XrayLogService
	private let hostResolverService: HostResolverService
	
	private var currentAddress: String {
		XrayTunnelSettings.tunnelAddress
	}
	
	// MARK: - Init
	
	/// Initializes the configuration builder with default services.
	public init() {
		self.init(
			logService: XrayLogService(),
			hostResolverService: HostResolverService()
		)
	}
	
	/// Initializes the configuration builder with custom services (for testing).
	private init(
		logService: XrayLogService,
		hostResolverService: HostResolverService
	) {
		self.logService = logService
		self.hostResolverService = hostResolverService
	}
	
	// MARK: - Public API
	
	/// Builds configuration data from the specified source.
	/// - Parameter source: The configuration source (.url, .json, or .outbound)
	/// - Returns: JSON configuration data
	/// - Throws: TunnelXError if building fails
	/// - Example:
	/// ```swift
	/// let builder = XrayConfigBuilder()
	/// let data = try builder.build(from: .url("vless://..."))
	///
	/// let writer = XrayConfigurationWriter()
	/// let fileURL = try writer.writeConfiguration(data)
	/// ```
	public func build(from source: Source) throws -> Data {
		let jsonObject: Any = try buildJSONObject(from: source)
		
		var changes: [(host: String, ip: String)] = []
		let resolvedObject = hostResolverService.resolveAddressesWithLogging(
			in: jsonObject,
			changes: &changes
		)
		
		return try JSONSerialization.data(withJSONObject: resolvedObject, options: [.prettyPrinted])
	}
	
	/// Convenience method to build and save configuration in one call.
	/// - Parameters:
	///   - source: The configuration source
	///   - fileName: The file name (default: "config.json")
	/// - Returns: URL of the saved file
	/// - Throws: TunnelXError if building or saving fails
	@discardableResult
	public func buildAndSave(from source: Source, fileName: String = "config.json") throws -> URL {
		let data = try build(from: source)
		let writer = XrayConfigurationWriter()
		return try writer.writeConfiguration(data, fileName: fileName)
	}
	
	/// Builds and saves SOCKS5 configuration file.
	/// - Parameter fileName: The file name (default: "socks5_config.yaml")
	/// - Returns: URL of the saved file
	/// - Throws: TunnelXError if writing fails
	@discardableResult
	public func buildAndSaveSocks5Config(fileName: String = "socks5_config.yaml") throws -> URL {
		let writer = XrayConfigurationWriter()
		return try writer.writeSocks5Config(
			address: currentAddress,
			port: Constants.socksPort,
			fileName: fileName
		)
	}
}

// MARK: - Core Building
private extension XrayConfigBuilder {
	
	/// Builds JSON object from source.
	func buildJSONObject(from source: Source) throws -> Any {
		switch source {
		case .url(let urlString):
			return try buildFromURL(urlString)
		case .json(let jsonString):
			return try buildFromJSON(jsonString)
		case .outbound(let outbound):
			return try buildFromOutbound(outbound)
		}
	}
	
	/// Builds configuration from a URL.
	func buildFromURL(_ urlString: String) throws -> Any {
		let parser = try LinkParser(urlString: urlString)
		
		let config = try parser.getConfiguration()
		applyStandardConfiguration(to: config)
		
		let jsonStr = try config.toJSON()
		return try parseJSON(from: jsonStr)
	}
	
	/// Builds configuration from a JSON string.
	func buildFromJSON(_ jsonString: String) throws -> Any {
		return try parseJSON(from: jsonString)
	}
	
	/// Builds configuration from an Outbound model.
	func buildFromOutbound(_ outbound: Outbound) throws -> Any {
		let proxyOutbound = Outbound(
			protocol: outbound.protocol,
			tag: Route.Outbound.proxy.rawValue,
			settings: outbound.settings,
			streamSettings: outbound.streamSettings,
			sendThrough: outbound.sendThrough
		)
		
		let config = XrayConfiguration().outbound(proxyOutbound)
		applyStandardConfiguration(to: config)
		
		let jsonStr = try config.toJSON()
		return try parseJSON(from: jsonStr)
	}
	
	/// Applies standard configuration elements (DNS, routing, inbound, logging, direct/block outbounds).
	func applyStandardConfiguration(to config: XrayConfiguration) {
		config
			.dns(makeDNS())
			.routing(makeRouting())
			.inbound(makeInbound())
			.log(makeLog())
			.outbound(makeDirectOutbound())
			.outbound(makeBlockOutbound())
	}
	
	/// Parses JSON string to JSON object.
	func parseJSON(from string: String) throws -> Any {
		guard let data = string.data(using: .utf8) else {
			throw TunnelXError.stringToDataConversionFailed
		}
		
		do {
			return try JSONSerialization.jsonObject(with: data)
		} catch {
			throw TunnelXError.jsonParsingFailed(underlying: error)
		}
	}
}

// MARK: - Config Elements
private extension XrayConfigBuilder {
	
	func makeInbound() -> Inbound {
		Inbound(
			listen: currentAddress,
			port: Constants.socksPort,
			protocol: .socks,
			settings: .socks(.init(auth: .noauth, udp: true)),
			tag: Constants.inboundTag,
			sniffing: .init(from: XrayTunnelSettings.sniffing)
		)
	}
	
	func makeDNS() -> DNS {
		XrayTunnelSettings.dns.toDNS()
	}
	
	func makeRouting() -> Route {
		let stored = XrayTunnelSettings.route
		var route = stored.toRoute()
		
		// Add inbound tag to rules that don't have one
		let updatedRules = route.rules.map { rule in
			guard rule.inboundTag == nil else { return rule }
			
			return Route.Rule(
				domain: rule.domain,
				ip: rule.ip,
				port: rule.port,
				inboundTag: [Constants.inboundTag],
				outboundTag: rule.outboundTag
			)
		}
		
		return Route(
			domainStrategy: route.domainStrategy,
			domainMatcher: route.domainMatcher,
			rules: updatedRules,
			balancers: route.balancers
		)
	}
	
	func makeLog() -> Log {
		let logFiles = logService.getLogFiles()
		
		return Log(
			loglevel: XrayTunnelSettings.logLevel,
			access: logFiles.access.path,
			error: logFiles.error.path,
			dnsLog: XrayTunnelSettings.dnsLogEnabled,
			maskAddress: ""
		)
	}
	
	func makeDirectOutbound() -> Outbound {
		Outbound(protocol: .freedom, tag: Constants.directTag, sendThrough: nil)
	}
	
	func makeBlockOutbound() -> Outbound {
		Outbound(protocol: .blackhole, tag: Constants.blockTag, sendThrough: nil)
	}
}

