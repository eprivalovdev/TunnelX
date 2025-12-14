import Foundation

/// A type-safe parser and validator for Xray connection URLs (vless://, vmess://, trojan://, etc.)
///
/// `LinkParser` extracts and validates all components from proxy share links,
/// providing type-safe access to connection parameters through a well-defined API.
///
/// # Usage Example
/// ```swift
/// let parser = try LinkParser(urlString: "vless://uuid@host:port?type=ws&security=tls")
/// let config = try parser.getConfiguration()
/// ```
///
/// # URL Structure
/// The parser expects URLs in the following format:
/// ```
/// protocol://userID@host:port?param1=value1&param2=value2#connectionName
/// ```
///
/// # Supported Protocols
/// - `vless://` - VLESS protocol
/// - `vmess://` - VMess protocol
/// - `trojan://` - Trojan protocol
/// - `shadowsocks://` - Shadowsocks protocol
/// - `wireguard://` - WireGuard protocol
///
/// # Thread Safety
/// `LinkParser` is a value type (struct) and is inherently thread-safe for immutable operations.
public struct LinkParser {
	
	// MARK: - Query Parameter Keys
	
	/// Type-safe enumeration of query parameter keys used in Xray share links.
	///
	/// This enum provides compile-time safety and prevents typos when accessing
	/// query parameters from the URL.
	public enum ParameterKey: String, CaseIterable {
		/// Network transport type (ws, grpc, tcp, etc.)
		case type
		
		/// Security/encryption type (tls, reality, none)
		case security
		
		/// WebSocket or HTTP path
		case path
		
		/// Server Name Indication for TLS
		case sni
		
		/// Host header value
		case host
		
		/// Reality public key
		case pbk
		
		/// Reality short ID
		case sid
		
		/// Reality spider X parameter
		case spx
		
		/// gRPC service name
		case serviceName
		
		/// gRPC authority
		case authority
		
		/// TLS/Reality fingerprint
		case fp
		
		/// ALPN protocols
		case alpn
		
		/// Flow control type
		case flow
		
		/// HTTP method
		case method
		
		/// Custom headers
		case headers
		
		/// QUIC security
		case quicSecurity
		
		/// Encryption key
		case key
		
		/// Header type for KCP/QUIC
		case headerType
		
		/// Mode for XHTTP
		case mode
		
		/// Maximum Transmission Unit
		case mtu
		
		/// Time To Interval
		case tti
		
		/// Uplink capacity
		case uplinkCapacity
		
		/// Downlink capacity
		case downlinkCapacity
		
		/// Congestion control
		case congestion
		
		/// Read buffer size
		case readBufferSize
		
		/// Write buffer size
		case writeBufferSize
		
		/// Seed value
		case seed
		
		/// gRPC multi-mode
		case multiMode
		
		/// Idle timeout
		case idle_timeout
		
		/// Health check timeout
		case health_check_timeout
		
		/// Initial window size
		case initial_windows_size
	}
	
	// MARK: - Public Properties
	
	/// The outbound connection protocol (vless, vmess, trojan, etc.)
	public let outboundProtocol: OutboundProtocol
	
	/// User identifier (UUID for VLESS/VMESS, password for Trojan)
	public let userID: String
	
	/// Server host address
	public let host: String
	
	/// Server port number (1-65535)
	public let port: Int
	
	/// Network transport type (ws, grpc, tcp, etc.)
	public let network: StreamSettings.Network
	
	/// Security/encryption type (tls, reality, none)
	public let security: StreamSettings.Security
	
	/// URL fragment (typically contains connection name/remarks)
	public let fragment: String
	
	/// Dictionary of all query parameters from the URL
	///
	/// For type-safe access, use the `parameter(_:)` method with `ParameterKey`.
	public let parametersMap: [String: String]
	
	// MARK: - Initialization
	
	/// Initializes a parser with an Xray share link URL.
	///
	/// - Parameter urlString: Xray share link string (vless://..., vmess://..., etc.)
	/// - Throws: `TunnelXError` if the URL is invalid or required parameters are missing
	///
	/// # Validation Rules
	/// - URL must be properly formatted
	/// - Protocol (scheme) must be supported
	/// - User ID must not be empty
	/// - Host must not be empty
	/// - Port must be in range 1-65535
	/// - Network type parameter must be present
	/// - Security type parameter must be present
	public init(urlString: String) throws {
		guard let components = URLComponents(string: urlString) else {
			throw TunnelXError.invalidURL(urlString)
		}
		
		// Extract and validate each component
		self.outboundProtocol = try Self.extractProtocol(from: components)
		self.userID = try Self.extractUserID(from: components)
		self.host = try Self.extractHost(from: components)
		self.port = try Self.extractPort(from: components)
		
		// Build parameters map from query items
		self.parametersMap = Self.buildParametersMap(from: components.queryItems)
		
		// Extract required parameters from query
		self.network = try Self.extractNetworkType(from: parametersMap)
		self.security = try Self.extractSecurityType(from: parametersMap)
		
		// Extract optional fragment (connection name)
		self.fragment = components.fragment ?? ""
	}
	
	// MARK: - Public API
	
	/// Retrieves a query parameter value using a type-safe key.
	///
	/// - Parameter key: The parameter key to retrieve
	/// - Returns: The parameter value, or `nil` if not present
	///
	/// # Example
	/// ```swift
	/// if let path = parser.parameter(.path) {
	///     print("WebSocket path: \(path)")
	/// }
	/// ```
	public func parameter(_ key: ParameterKey) -> String? {
		parametersMap[key.rawValue]
	}
	
	/// Retrieves a required query parameter value using a type-safe key.
	///
	/// - Parameters:
	///   - key: The parameter key to retrieve
	///   - error: The error to throw if the parameter is missing
	/// - Returns: The parameter value
	/// - Throws: The provided error if the parameter is missing or empty
	///
	/// # Example
	/// ```swift
	/// let publicKey = try parser.requireParameter(.pbk, or: .missingSecurityType)
	/// ```
	public func requireParameter(
		_ key: ParameterKey,
		or error: TunnelXError
	) throws -> String {
		guard let value = parameter(key), !value.isEmpty else {
			throw error
		}
		return value
	}
	
	/// Builds an `XrayConfiguration` from the parsed link.
	///
	/// - Returns: A configured `XrayConfiguration` object
	/// - Throws: `TunnelXError` if configuration building fails
	public func getConfiguration() throws -> XrayConfiguration {
		try XrayConfiguration(self)
	}
}

// MARK: - Private Extraction Methods

private extension LinkParser {
	
	/// Extracts and validates the protocol from URL components.
	///
	/// - Parameter components: URL components containing the scheme
	/// - Returns: Validated outbound protocol
	/// - Throws: `TunnelXError.unsupportedProtocol` if scheme is missing or unsupported
	static func extractProtocol(from components: URLComponents) throws -> OutboundProtocol {
		guard let scheme = components.scheme, !scheme.isEmpty else {
			throw TunnelXError.unsupportedProtocol("nil")
		}
		
		guard let `protocol` = OutboundProtocol(rawValue: scheme) else {
			throw TunnelXError.unsupportedProtocol(scheme)
		}
		
		return `protocol`
	}
	
	/// Extracts and validates the user ID from URL components.
	///
	/// - Parameter components: URL components containing the user field
	/// - Returns: Validated user ID
	/// - Throws: `TunnelXError.missingUserID` if user ID is missing or empty
	static func extractUserID(from components: URLComponents) throws -> String {
		guard let userID = components.user, !userID.isEmpty else {
			throw TunnelXError.missingUserID
		}
		
		return userID
	}
	
	/// Extracts and validates the host from URL components.
	///
	/// - Parameter components: URL components containing the host field
	/// - Returns: Validated host address
	/// - Throws: `TunnelXError.missingHost` if host is missing or empty
	static func extractHost(from components: URLComponents) throws -> String {
		guard let host = components.host, !host.isEmpty else {
			throw TunnelXError.missingHost
		}
		
		return host
	}
	
	/// Extracts and validates the port from URL components.
	///
	/// - Parameter components: URL components containing the port field
	/// - Returns: Validated port number (1-65535)
	/// - Throws: `TunnelXError.invalidPort` if port is missing or out of valid range
	static func extractPort(from components: URLComponents) throws -> Int {
		guard let port = components.port else {
			throw TunnelXError.invalidPort(0)
		}
		
		guard (1...65535).contains(port) else {
			throw TunnelXError.invalidPort(port)
		}
		
		return port
	}
	
	/// Builds a parameters dictionary from URL query items.
	///
	/// Empty values are filtered out to maintain data quality.
	///
	/// - Parameter queryItems: Optional array of URL query items
	/// - Returns: Dictionary mapping parameter names to values
	static func buildParametersMap(from queryItems: [URLQueryItem]?) -> [String: String] {
		guard let queryItems else {
			return [:]
		}
		
		return queryItems.reduce(into: [:]) { result, item in
			if let value = item.value, !value.isEmpty {
				result[item.name] = value
			}
		}
	}
	
	/// Extracts the network transport type from parameters.
	///
	/// - Parameter parameters: Dictionary of query parameters
	/// - Returns: Validated network type
	/// - Throws: `TunnelXError.missingNetworkType` if type is missing or invalid
	static func extractNetworkType(from parameters: [String: String]) throws -> StreamSettings.Network {
		guard let typeString = parameters[ParameterKey.type.rawValue],
			  !typeString.isEmpty else {
			throw TunnelXError.missingNetworkType
		}
		
		guard let network = StreamSettings.Network(rawValue: typeString) else {
			throw TunnelXError.missingNetworkType
		}
		
		return network
	}
	
	/// Extracts the security/encryption type from parameters.
	///
	/// - Parameter parameters: Dictionary of query parameters
	/// - Returns: Validated security type
	/// - Throws: `TunnelXError.missingSecurityType` if security is missing or invalid
	static func extractSecurityType(from parameters: [String: String]) throws -> StreamSettings.Security {
		guard let securityString = parameters[ParameterKey.security.rawValue],
			  !securityString.isEmpty else {
			throw TunnelXError.missingSecurityType
		}
		
		guard let security = StreamSettings.Security(rawValue: securityString) else {
			throw TunnelXError.missingSecurityType
		}
		
		return security
	}
}

// MARK: - CustomStringConvertible

extension LinkParser: CustomStringConvertible {
	public var description: String {
		"""
		LinkParser {
		  protocol: \(outboundProtocol.rawValue)
		  host: \(host)
		  port: \(port)
		  network: \(network.rawValue)
		  security: \(security.rawValue)
		  fragment: \(fragment.isEmpty ? "<empty>" : "\"\(fragment)\"")
		  parameters: \(parametersMap.isEmpty ? "<none>" : formatParameters())
		}
		"""
	}
	
	/// Formats parameters for readable output.
	private func formatParameters() -> String {
		let sortedParams = parametersMap.sorted { $0.key < $1.key }
		let formatted = sortedParams.map { "    \($0.key) = \"\($0.value)\"" }.joined(separator: "\n")
		return "\n" + formatted
	}
}

// MARK: - Equatable

extension LinkParser: Equatable {
	public static func == (lhs: LinkParser, rhs: LinkParser) -> Bool {
		lhs.outboundProtocol == rhs.outboundProtocol &&
		lhs.userID == rhs.userID &&
		lhs.host == rhs.host &&
		lhs.port == rhs.port &&
		lhs.network == rhs.network &&
		lhs.security == rhs.security &&
		lhs.fragment == rhs.fragment &&
		lhs.parametersMap == rhs.parametersMap
	}
}

// MARK: - Hashable

extension LinkParser: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(outboundProtocol)
		hasher.combine(userID)
		hasher.combine(host)
		hasher.combine(port)
		hasher.combine(network)
		hasher.combine(security)
		hasher.combine(fragment)
		
		// Hash parameters in a stable order
		let sortedKeys = parametersMap.keys.sorted()
		for key in sortedKeys {
			hasher.combine(key)
			hasher.combine(parametersMap[key])
		}
	}
}
