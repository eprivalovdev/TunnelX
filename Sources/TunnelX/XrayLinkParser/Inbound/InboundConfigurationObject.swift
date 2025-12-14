import Foundation

// MARK: - Inbound Configuration Object

/// Unified configuration object for inbound protocol settings.
///
/// Different inbound protocols require different configuration parameters.
/// This enum provides type-safe configuration for each protocol.
///
/// ## Supported Protocols
///
/// - **SOCKS5**: Full SOCKS5 proxy with authentication options
/// - **HTTP**: Standard HTTP/HTTPS proxy with timeout
///
/// ## Example Usage
///
/// ### SOCKS5 with Authentication
/// ```swift
/// let config = InboundConfigurationObject.socks(
///     SocksInboundConfigurationObject(
///         auth: .password,
///         udp: true
///     )
/// )
/// ```
///
/// ### HTTP Proxy
/// ```swift
/// let config = InboundConfigurationObject.http(timeout: 300)
/// ```
///
/// - SeeAlso: [Xray Inbound Configuration](https://xtls.github.io/en/config/inbounds)
public enum InboundConfigurationObject: Encodable {
	
	// MARK: - Cases
	
	/// SOCKS5 protocol configuration.
	///
	/// Supports both TCP and UDP with optional authentication.
	case socks(SocksInboundConfigurationObject)
	
	/// HTTP/HTTPS proxy configuration.
	///
	/// - Parameter timeout: Connection timeout in seconds.
	case http(timeout: Int)
	
	// TODO: Add more inbound protocols as needed:
	// case vmess(VmessInboundConfigurationObject)
	// case vless(VlessInboundConfigurationObject)
	// case trojan(TrojanInboundConfigurationObject)
	// case shadowsocks(ShadowsocksInboundConfigurationObject)
	// case dokodemo(DokodemoInboundConfigurationObject)
	
	// MARK: - Encodable
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		
		switch self {
		case .socks(let object):
			try container.encode(object)
			
		case .http(let timeout):
			try container.encode(["timeout": timeout])
		}
	}
}

