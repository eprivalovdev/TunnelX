import Foundation

// MARK: - WebSocket Settings

/// Configuration for WebSocket transport protocol.
///
/// WebSocket is a protocol providing full-duplex communication channels over HTTP.
/// It's excellent for bypassing firewalls and deep packet inspection as traffic
/// appears as standard HTTP(S) connections.
///
/// ## Key Features
/// - **HTTP Upgrade**: Starts as HTTP, upgrades to WebSocket
/// - **Firewall Friendly**: Passes through most corporate/school firewalls
/// - **CDN Compatible**: Can work behind Cloudflare and other CDNs
/// - **Custom Headers**: Support for custom HTTP headers
///
/// ## Use Cases
/// - Highly censored networks
/// - Corporate/school firewalls
/// - CDN-enabled servers
/// - Environments that block non-HTTP traffic
///
/// ## Performance
/// - Slight overhead compared to raw TCP (~5-10%)
/// - Excellent for moderate throughput
/// - Good latency characteristics
///
/// - SeeAlso: [Xray WebSocket Configuration](https://xtls.github.io/en/config/transport#websocketobject)
public struct WebSocketSettings: Encodable, Parsable {
	
	// MARK: - Properties
	
	/// WebSocket endpoint path.
	///
	/// The URL path for the WebSocket connection. This appears in the HTTP Upgrade
	/// request and should match the server configuration.
	///
	/// ## Examples
	/// - Standard: `"/"`
	/// - Obfuscated: `"/api/v1/ws"`
	/// - Randomized: `"/ws?token=abc123"`
	///
	/// ## Best Practices
	/// - Use paths that look like legitimate API endpoints
	/// - Avoid suspicious patterns (e.g., `/v2ray`, `/xray`)
	/// - Match your server's path exactly
	///
	/// - Note: Path includes query parameters if needed: `"/path?key=value"`
	public var path: String
	
	/// Host header value for the WebSocket connection.
	///
	/// Sets the `Host` HTTP header in the WebSocket upgrade request.
	/// Useful for:
	/// - CDN routing (when using Cloudflare, etc.)
	/// - Virtual hosting scenarios
	/// - SNI mismatch camouflage
	///
	/// ## Examples
	/// - CDN: `"www.example.com"`
	/// - Direct: Same as server address (can be nil)
	/// - Camouflage: A legitimate website domain
	///
	/// - Note: If nil, the `Host` header will match the connection target.
	public var host: String?
	
	/// Custom HTTP headers for the WebSocket upgrade request.
	///
	/// Additional headers to include in the initial HTTP request.
	/// Useful for:
	/// - Mimicking browser behavior
	/// - Adding authentication tokens
	/// - Improving obfuscation
	///
	/// ## Common Headers
	/// ```swift
	/// [
	///     "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)...",
	///     "Accept-Language": "en-US,en;q=0.9",
	///     "Cache-Control": "no-cache"
	/// ]
	/// ```
	///
	/// ## Security Considerations
	/// - ⚠️ Don't include sensitive data in headers (visible in traffic)
	/// - ✅ Use headers that match legitimate browser traffic
	/// - ✅ Ensure headers don't conflict with WebSocket requirements
	///
	/// - Note: Headers are sent in plaintext unless using TLS.
	public var headers: [String: String]?
	
	// MARK: - Initializers
	
	/// Creates WebSocket settings from a parsed link.
	///
	/// Extracts WebSocket configuration from a connection URL, including path,
	/// host, and custom headers.
	///
	/// - Parameter parser: Link parser containing WebSocket parameters
	/// - Throws: `TunnelXError.invalidNetworkType` if network type is not WebSocket
	///
	/// ## Supported Parameters
	/// - `path`: WebSocket endpoint path (default: `"/"`)
	/// - `host`: Host header value
	/// - `headers`: Custom headers in format `"Key1:Value1|Key2:Value2"`
	///
	/// ## Header Format
	/// Headers are encoded as pipe-separated key-value pairs:
	/// ```
	/// "User-Agent:Mozilla/5.0|Accept-Language:en-US"
	/// ```
	public init(_ parser: LinkParser) throws {
		guard parser.network == .ws else {
			throw TunnelXError.invalidNetworkType(expected: "ws", actual: parser.network.rawValue)
		}
		
		// Parse path (default to "/" if not specified)
		self.path = parser.parametersMap["path"] ?? "/"
		
		// Parse host header
		self.host = parser.parametersMap["host"]
		
		// Parse custom headers from pipe-separated format
		if let headersRaw = parser.parametersMap["headers"], !headersRaw.isEmpty {
			var headerMap: [String: String] = [:]
			
			// Split by pipe, then by colon
			headersRaw.split(separator: "|").forEach { pair in
				let parts = pair.split(separator: ":", maxSplits: 1).map { String($0) }
				if parts.count == 2 {
					let key = parts[0].trimmingCharacters(in: .whitespaces)
					let value = parts[1].trimmingCharacters(in: .whitespaces)
					headerMap[key] = value
				}
			}
			
			self.headers = headerMap.isEmpty ? nil : headerMap
		} else {
			self.headers = nil
		}
	}
	
	/// Creates WebSocket settings with explicit parameters.
	///
	/// - Parameters:
	///   - path: WebSocket endpoint path (default: `"/"`)
	///   - host: Host header value (default: nil)
	///   - headers: Custom HTTP headers (default: nil)
	///
	/// ## Example
	/// ```swift
	/// let ws = WebSocketSettings(
	///     path: "/api/v1/ws",
	///     host: "www.example.com",
	///     headers: [
	///         "User-Agent": "Mozilla/5.0 ...",
	///         "Accept-Language": "en-US,en;q=0.9"
	///     ]
	/// )
	/// ```
	public init(
		path: String = "/",
		host: String? = nil,
		headers: [String: String]? = nil
	) {
		self.path = path
		self.host = host
		self.headers = headers
	}
}
