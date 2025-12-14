import Foundation

// MARK: - Outbound Configuration Object

/// Unified configuration object for all Xray outbound protocol types.
///
/// This enum encapsulates protocol-specific configuration objects for different
/// outbound connection types. Each case contains the configuration details specific
/// to that protocol while providing a unified interface for encoding and parsing.
///
/// ## Supported Protocols
///
/// ### Proxy Protocols
/// - **VLESS**: Modern stateless proxy with XTLS support
/// - **VMess**: V2Ray's legacy encrypted proxy protocol
/// - **Trojan**: TLS-camouflaged proxy protocol
/// - **Shadowsocks**: SOCKS5-based encrypted proxy
/// - **WireGuard**: High-performance VPN protocol
///
/// ### Utility Protocols
/// - **Freedom**: Direct connection (no proxy)
/// - **Blackhole**: Connection blocking/dropping
///
/// ## Architecture
///
/// Each protocol configuration is:
/// 1. **Type-Safe**: Swift enums ensure compile-time protocol validation
/// 2. **Protocol-Specific**: Each case holds protocol-specific settings
/// 3. **Parsable**: Can be constructed from connection URLs
/// 4. **Encodable**: Serializes to Xray-compatible JSON format
///
/// ## JSON Encoding
///
/// Different protocols have different JSON structures:
/// - **Client-Server** protocols (VLESS, VMess): `{"vnext": [...]}`
/// - **Server-based** protocols (Trojan, Shadowsocks): `{"servers": [...]}`
/// - **Configuration** protocols (WireGuard): Direct object encoding
/// - **Simple** protocols (Freedom, Blackhole): Direct or empty encoding
///
/// ## Example Usage
///
/// ### Creating from a URL
/// ```swift
/// let parser = try LinkParser(url: "vless://uuid@host:port?params...")
/// let config = try OutboundConfigurationObject(parser)
/// ```
///
/// ### Creating programmatically
/// ```swift
/// let config = OutboundConfigurationObject.vless(
///     VlessOutboundConfigurationObject(
///         address: "example.com",
///         port: 443,
///         users: [...]
///     )
/// )
/// ```
///
/// ### Using in Outbound
/// ```swift
/// let outbound = Outbound(
///     protocol: .vless,
///     tag: "proxy",
///     settings: config,
///     streamSettings: streamSettings
/// )
/// ```
///
/// - SeeAlso:
///   - `Outbound` for complete outbound connection configuration
///   - `LinkParser` for URL parsing details
///   - Individual protocol configuration objects for protocol-specific details
public enum OutboundConfigurationObject: Encodable, Parsable {
	
	// MARK: - Cases
	
	/// VLESS protocol configuration.
	///
	/// VLESS (Verified Less) is a stateless, lightweight proxy protocol with
	/// minimal overhead. Supports XTLS flow control for enhanced performance.
	///
	/// - SeeAlso: `VlessOutboundConfigurationObject`
	case vless(VlessOutboundConfigurationObject)
	
	/// VMess protocol configuration.
	///
	/// VMess is V2Ray's legacy encrypted proxy protocol with built-in encryption
	/// and time-based authentication.
	///
	/// - SeeAlso: `VmessOutboundConfigurationObject`
	case vmess(VmessOutboundConfigurationObject)
	
	/// Trojan protocol configuration.
	///
	/// Trojan disguises proxy traffic as standard HTTPS, making it difficult
	/// to detect and block.
	///
	/// - SeeAlso: `TrojanOutboundConfigurationObject`
	case trojan(TrojanOutboundConfigurationObject)
	
	/// Shadowsocks protocol configuration.
	///
	/// Shadowsocks is a secure SOCKS5 proxy with various encryption methods,
	/// including modern 2022 edition BLAKE3-based ciphers.
	///
	/// - SeeAlso: `ShadowsocksOutboundConfigurationObject`
	case shadowsocks(ShadowsocksOutboundConfigurationObject)
	
	/// WireGuard protocol configuration.
	///
	/// WireGuard is a modern, high-performance VPN protocol using state-of-the-art
	/// cryptography.
	///
	/// - SeeAlso: `WireGuardOutboundConfigurationObject`
	case wireguard(WireGuardOutboundConfigurationObject)
	
	/// Freedom (direct connection) configuration.
	///
	/// Routes traffic directly to its destination without proxying.
	/// Used for local networks, trusted destinations, or split tunneling.
	///
	/// - SeeAlso: `FreedomOutboundConfigurationObject`
	case freedom(FreedomOutboundConfigurationObject)
	
	/// Blackhole (blocking) configuration.
	///
	/// Drops or blocks all traffic routed to it. Used for ad-blocking,
	/// content filtering, and access control.
	///
	/// - SeeAlso: `BlackholeOutboundConfigurationObject`
	case blackhole(BlackholeOutboundConfigurationObject)
	
	// MARK: - Initializers
	
	/// Creates an outbound configuration from a parsed link.
	///
	/// Analyzes the protocol type from the parser and constructs the appropriate
	/// protocol-specific configuration object.
	///
	/// - Parameter parser: Link parser containing protocol and connection details
	/// - Throws: `TunnelXError` if parsing fails or protocol is unsupported
	///
	/// ## Supported URL Formats
	/// - VLESS: `vless://uuid@host:port?params...`
	/// - VMess: `vmess://base64json` or `vmess://uuid@host:port?params...`
	/// - Trojan: `trojan://password@host:port?params...`
	/// - Shadowsocks: `ss://base64(method:password)@host:port` (SIP002)
	/// - WireGuard: Not yet supported (use configuration files)
	///
	/// - Important: The parser must have successfully parsed a valid protocol URL
	///              before calling this initializer.
	init(_ parser: LinkParser) throws {
		switch parser.outboundProtocol {
		case .vless:
			self = .vless(try VlessOutboundConfigurationObject(parser))
		case .vmess:
			self = .vmess(try VmessOutboundConfigurationObject(parser))
		case .trojan:
			self = .trojan(try TrojanOutboundConfigurationObject(parser))
		case .shadowsocks:
			self = .shadowsocks(try ShadowsocksOutboundConfigurationObject(parser))
		case .wireguard:
			self = .wireguard(try WireGuardOutboundConfigurationObject(parser))
		case .freedom:
			self = .freedom(try FreedomOutboundConfigurationObject(parser))
		case .blackhole:
			self = .blackhole(try BlackholeOutboundConfigurationObject(parser))
		}
	}
	
	// MARK: - Encodable
	
	/// Encodes the configuration to Xray-compatible JSON format.
	///
	/// Different protocols use different JSON structures according to Xray specifications:
	///
	/// - **VLESS/VMess**: `{"vnext": [server_config]}`
	/// - **Trojan/Shadowsocks**: `{"servers": [server_config]}`
	/// - **WireGuard**: Direct object `{secretKey, peers, ...}`
	/// - **Freedom/Blackhole**: Direct object or empty `{}`
	///
	/// ## Example JSON Output
	///
	/// ### VLESS
	/// ```json
	/// {
	///   "vnext": [{
	///     "address": "example.com",
	///     "port": 443,
	///     "users": [{"id": "uuid", "encryption": "none"}]
	///   }]
	/// }
	/// ```
	///
	/// ### Shadowsocks
	/// ```json
	/// {
	///   "servers": [{
	///     "address": "example.com",
	///     "port": 8388,
	///     "method": "2022-blake3-aes-256-gcm",
	///     "password": "password"
	///   }]
	/// }
	/// ```
	///
	/// - Parameter encoder: The encoder to write data to
	/// - Throws: `EncodingError` if encoding fails
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		
		switch self {
		case .vless(let object):
			// VLESS uses "vnext" (next hop) structure
			try container.encode(["vnext": [object]])
			
		case .vmess(let object):
			// VMess uses "vnext" (next hop) structure
			try container.encode(["vnext": [object]])
			
		case .trojan(let object):
			// Trojan uses "servers" structure
			try container.encode(["servers": [object]])
			
		case .shadowsocks(let object):
			// Shadowsocks uses "servers" structure
			try container.encode(["servers": [object]])
			
		case .wireguard(let object):
			// WireGuard encodes its configuration directly
			try container.encode(object)
			
		case .freedom(let object):
			// Freedom encodes its configuration directly
			try container.encode(object)
			
		case .blackhole(let object):
			// Blackhole encodes its response configuration
			try container.encode(object)
		}
	}
}
