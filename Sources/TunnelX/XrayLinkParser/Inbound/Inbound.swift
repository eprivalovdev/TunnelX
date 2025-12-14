import Foundation

// MARK: - Inbound

/// Inbound connection configuration for accepting client connections.
///
/// Inbound defines how Xray accepts connections from clients (local applications).
/// Typically used to create a local SOCKS5 or HTTP proxy.
///
/// ## Common Configurations
///
/// ### SOCKS5 Proxy (Most Common)
/// ```swift
/// let inbound = Inbound(
///     listen: "127.0.0.1",
///     port: 10808,
///     protocol: .socks,
///     tag: "socks"
/// )
/// ```
///
/// ### HTTP Proxy
/// ```swift
/// let inbound = Inbound(
///     listen: "127.0.0.1",
///     port: 10809,
///     protocol: .http,
///     settings: .http(timeout: 300),
///     tag: "http-in"
/// )
/// ```
///
/// - SeeAlso: [Xray Inbound Configuration](https://xtls.github.io/en/config/inbounds)
public struct Inbound: Encodable {
	
	// MARK: - Nested Types
	
	/// Traffic sniffing configuration for protocol detection.
	///
	/// Sniffing allows Xray to detect the actual protocol of connections
	/// and route them accordingly, even if they're wrapped in other protocols.
	public struct Sniffing: Encodable {
		
		// MARK: - Properties
		
		/// Enable sniffing.
		public let enabled: Bool
		
		/// Protocols to detect and override destination.
		///
		/// Common values: `["http", "tls", "quic", "fakedns"]`
		public let destOverride: [String]
		
		/// Only sniff metadata without content inspection.
		public let metadataOnly: Bool
		
		/// Only use sniffing results for routing (don't override destination).
		public let routeOnly: Bool
		
		/// Domains to exclude from sniffing.
		public let domainsExcluded: [String]
		
		// MARK: - Initializers
		
		/// Creates sniffing configuration.
		///
		/// - Parameters:
		///   - enabled: Enable sniffing (default: `false`)
		///   - destOverride: Protocols to detect (default: `["http", "tls", "quic"]`)
		///   - metadataOnly: Metadata-only sniffing (default: `false`)
		///   - routeOnly: Use for routing only (default: `true`)
		///   - domainsExcluded: Domains to exclude (default: `[]`)
		public init(
			enabled: Bool = false,
			destOverride: [String] = ["http", "tls", "quic"],
			metadataOnly: Bool = false,
			routeOnly: Bool = true,
			domainsExcluded: [String] = []
		) {
			self.enabled = enabled
			self.destOverride = destOverride
			self.metadataOnly = metadataOnly
			self.routeOnly = routeOnly
			self.domainsExcluded = domainsExcluded
		}
	}
	
	// MARK: - Properties
	
	/// Listen address (IP to bind to).
	///
	/// Common values:
	/// - `"127.0.0.1"`: IPv4 localhost only
	/// - `"::1"`: IPv6 localhost only
	/// - `"0.0.0.0"`: All IPv4 interfaces
	/// - `"::"`: All IPv6 interfaces
	public let listen: String
	
	/// Listen port.
	public let port: Int
	
	/// Inbound protocol type.
	public let `protocol`: InboundProtocol
	
	/// Protocol-specific settings.
	public let settings: InboundConfigurationObject
	
	/// Tag for routing rules.
	public let tag: String
	
	/// Traffic sniffing configuration.
	public let sniffing: Sniffing
	
	/// Stream settings for the inbound (optional).
	///
	/// Used for inbound protocols that need transport configuration
	/// (e.g., VMess, VLESS, Trojan inbounds).
	public let streamSettings: StreamSettings?
	
	// MARK: - Initializers
	
	/// Creates inbound configuration.
	///
	/// - Parameters:
	///   - listen: Listen address (default: `"127.0.0.1"`)
	///   - port: Listen port (default: `10808`)
	///   - protocol: Protocol type (default: `.socks`)
	///   - settings: Protocol settings (default: SOCKS5 with no auth)
	///   - tag: Routing tag (default: `"socks"`)
	///   - sniffing: Sniffing configuration (default: disabled)
	///   - streamSettings: Stream settings (default: nil)
	public init(
		listen: String = "127.0.0.1",
		port: Int = 10808,
		`protocol`: InboundProtocol = .socks,
		settings: InboundConfigurationObject = .socks(SocksInboundConfigurationObject()),
		tag: String = "socks",
		sniffing: Sniffing = Sniffing(),
		streamSettings: StreamSettings? = nil
	) {
		self.listen = listen
		self.port = port
		self.`protocol` = `protocol`
		self.settings = settings
		self.tag = tag
		self.sniffing = sniffing
		self.streamSettings = streamSettings
	}
}

// MARK: - Extensions

public extension Inbound.Sniffing {
	/// Creates sniffing configuration from storage model.
	init(from stored: StorageSniffing) {
		self.init(
			enabled: stored.enabled,
			destOverride: stored.destOverride,
			metadataOnly: stored.metadataOnly,
			routeOnly: stored.routeOnly,
			domainsExcluded: stored.domainsExcluded
		)
	}
}

