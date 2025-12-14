import Foundation

// MARK: - gRPC Settings

/// Configuration for gRPC transport protocol.
///
/// ## Requirements
/// - TLS encryption (gRPC over TLS)
/// - Server must support gRPC
///
/// - SeeAlso: [Xray gRPC Configuration](https://xtls.github.io/en/config/transport#grpcobject)
public struct GRPCSettings: Encodable, Parsable {
	
	// MARK: - Properties
	
	/// gRPC service name.
	///
	/// The name of the gRPC service endpoint. This should match the server
	/// configuration and appear in the HTTP/2 `:path` pseudo-header.
	///
	/// ## Examples
	/// - Standard: `"GunService"`
	/// - Custom: `"ApiService"`
	/// - Camouflaged: `"grpc.health.v1.Health"`
	///
	/// ## Best Practices
	/// - Use service names that look legitimate
	/// - Match server configuration exactly
	/// - Consider using standard gRPC service patterns
	///
	/// - Note: Leave nil to use default service name.
	public var serviceName: String?
	
	/// gRPC authority (`:authority` pseudo-header).
	///
	/// The value for the HTTP/2 `:authority` pseudo-header, similar to the
	/// HTTP `Host` header. Used for virtual hosting and routing.
	///
	/// ## Use Cases
	/// - CDN routing
	/// - Virtual hosting
	/// - Load balancer routing
	///
	/// ## Example Values
	/// - Domain: `"api.example.com"`
	/// - IP with port: `"192.168.1.1:443"`
	/// - Default: Same as connection target (if nil)
	///
	/// - Note: If nil, defaults to the connection target address.
	public var authority: String?
	
	/// Enable multi-stream mode.
	///
	/// When enabled, uses multiple HTTP/2 streams for parallel data transmission.
	/// This can improve throughput for high-bandwidth applications.
	///
	/// ## Performance Impact
	/// - ✅ **Enabled**: Better throughput, higher concurrency
	/// - ❌ **Disabled**: Lower overhead, simpler implementation
	///
	/// ## Recommendation
	/// - Enable for high-throughput applications
	/// - Disable for low-latency or simple use cases
	///
	/// - Note: Both client and server must agree on this setting.
	public var multiMode: Bool?
	
	/// Idle timeout in seconds.
	///
	/// Maximum time a connection can remain idle before being closed.
	/// Helps manage connection resources and detect dead connections.
	///
	/// ## Typical Values
	/// - Short-lived: 30-60 seconds
	/// - Long-lived: 300-600 seconds (5-10 minutes)
	/// - No timeout: nil or very large value
	///
	/// ## Considerations
	/// - Too short: Frequent reconnections
	/// - Too long: Resource waste on dead connections
	///
	/// - Note: Set to nil for default server behavior.
	public var idleTimeout: Int?
	
	/// Health check timeout in seconds.
	///
	/// Timeout for gRPC health check probes. Used to verify connection
	/// is still alive and responsive.
	///
	/// ## Typical Values
	/// - Standard: 20 seconds
	/// - Fast detection: 10 seconds
	/// - Tolerant: 30+ seconds
	///
	/// - Note: Set to nil to disable or use default.
	public var healthCheckTimeout: Int?
	
	/// Initial window size for flow control.
	///
	/// HTTP/2 flow control window size in bytes. Larger values allow more
	/// data in-flight, improving throughput for high-bandwidth connections.
	///
	/// ## Typical Values
	/// - Default: 65535 bytes (64 KB)
	/// - High bandwidth: 1048576 bytes (1 MB)
	/// - Low latency: 32768 bytes (32 KB)
	///
	/// ## Considerations
	/// - Larger: Better throughput, more memory usage
	/// - Smaller: Lower memory usage, potential throughput reduction
	///
	/// - Note: Must be between 65535 and 2147483647 (2^31 - 1).
	public var initialWindowsSize: Int?
	
	// MARK: - Initializers
	
	/// Creates gRPC settings from a parsed link.
	///
	/// Extracts gRPC configuration parameters from a connection URL.
	///
	/// - Parameter parser: Link parser containing gRPC parameters
	/// - Throws: `TunnelXError.invalidNetworkType` if network type is not gRPC
	///
	/// ## Supported Parameters
	/// - `serviceName`: gRPC service name
	/// - `authority`: Authority pseudo-header
	/// - `multiMode`: Enable multi-stream mode (boolean)
	/// - `idle_timeout`: Idle timeout in seconds (integer)
	/// - `health_check_timeout`: Health check timeout in seconds (integer)
	/// - `initial_windows_size`: Initial window size in bytes (integer)
	public init(_ parser: LinkParser) throws {
		guard parser.network == .grpc else {
			throw TunnelXError.invalidNetworkType(expected: "grpc", actual: parser.network.rawValue)
		}
		
		let parametersMap = parser.parametersMap
		
		// Parse service name
		self.serviceName = parametersMap["serviceName"]
		
		// Parse authority
		self.authority = parametersMap["authority"]
		
		// Parse multiMode (boolean)
		if let multiModeString = parametersMap["multiMode"] {
			self.multiMode = (multiModeString as NSString).boolValue
		} else {
			self.multiMode = nil
		}
		
		// Parse integer parameters
		self.idleTimeout = parametersMap["idle_timeout"].flatMap { Int($0) }
		self.healthCheckTimeout = parametersMap["health_check_timeout"].flatMap { Int($0) }
		self.initialWindowsSize = parametersMap["initial_windows_size"].flatMap { Int($0) }
	}
	
	/// Creates gRPC settings with explicit parameters.
	///
	/// - Parameters:
	///   - serviceName: gRPC service name (default: nil)
	///   - authority: Authority pseudo-header (default: nil)
	///   - multiMode: Enable multi-stream mode (default: nil)
	///   - idleTimeout: Idle timeout in seconds (default: nil)
	///   - healthCheckTimeout: Health check timeout in seconds (default: nil)
	///   - initialWindowsSize: Initial window size in bytes (default: nil)
	///
	/// ## Example
	/// ```swift
	/// let grpc = GRPCSettings(
	///     serviceName: "GunService",
	///     multiMode: true,
	///     idleTimeout: 300,
	///     initialWindowsSize: 1048576
	/// )
	/// ```
	public init(
		serviceName: String? = nil,
		authority: String? = nil,
		multiMode: Bool? = nil,
		idleTimeout: Int? = nil,
		healthCheckTimeout: Int? = nil,
		initialWindowsSize: Int? = nil
	) {
		self.serviceName = serviceName
		self.authority = authority
		self.multiMode = multiMode
		self.idleTimeout = idleTimeout
		self.healthCheckTimeout = healthCheckTimeout
		self.initialWindowsSize = initialWindowsSize
	}
	
	// MARK: - Encodable
	
	enum CodingKeys: String, CodingKey {
		case serviceName
		case authority
		case multiMode
		case idleTimeout = "idle_timeout"
		case healthCheckTimeout = "health_check_timeout"
		case initialWindowsSize = "initial_windows_size"
	}
}
