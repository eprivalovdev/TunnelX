import Foundation

// MARK: - VMess Outbound Configuration

/// Configuration object for VMess protocol outbound connections.
///
/// VMess is a proprietary encrypted proxy protocol developed by V2Ray/Xray.
/// It provides authentication, encryption, and obfuscation capabilities to protect
/// traffic from detection and analysis.
///
/// ## Key Features
/// - **UUID-Based Authentication**: Each user is identified by a unique UUID
/// - **Built-in Encryption**: Protocol-level encryption (AES, ChaCha20, etc.)
/// - **Adaptive Encryption**: Support for alterId for enhanced security
/// - **Time-Based Authentication**: Uses system time for authentication (requires time sync)
///
/// ## Security Considerations
/// - Ensure system time is synchronized (within 90 seconds of server time)
/// - Use `alterId: 0` for modern AEAD encryption (recommended)
/// - Legacy alterId values are deprecated and less secure
///
/// ## Example Usage
/// ```swift
/// let vmessConfig = VmessOutboundConfigurationObject(
///     address: "example.com",
///     port: 443,
///     users: [
///         VmessOutboundConfigurationObject.User(
///             id: "b831381d-6324-4d53-ad4f-8cda48b30811",
///             alterId: 0,
///             security: "auto",
///             level: 0
///         )
///     ]
/// )
/// ```
///
/// - Important: VMess requires accurate system time. Time drift > 90 seconds will cause
///              connection failures.
///
/// - SeeAlso:
///   - [Xray VMess Documentation](https://xtls.github.io/en/config/outbounds/vmess)
///   - `StreamSettings` for transport and security configuration
public struct VmessOutboundConfigurationObject: Encodable, Parsable {
	
	// MARK: - Nested Types
	
	/// User configuration for VMess protocol.
	///
	/// Each user represents a set of credentials and security settings for connecting
	/// to a VMess server.
	public struct User: Encodable {
		
		/// Encryption security method for VMess connections.
		///
		/// Defines the cipher algorithm used for payload encryption.
		public enum Security: String, Encodable, CaseIterable {
			/// Automatic selection based on client and server capabilities
			case auto = "auto"
			
			/// AES-128-GCM (recommended for most cases)
			case aes128Gcm = "aes-128-gcm"
			
			/// ChaCha20-Poly1305 (good for ARM devices)
			case chacha20Poly1305 = "chacha20-poly1305"
			
			/// No encryption (not recommended, use only for testing)
			case none = "none"
			
			/// Zero encryption overhead (deprecated)
			case zero = "zero"
		}
		
		// MARK: - Properties
		
		/// Unique user identifier (UUID format).
		///
		/// Must match the server-side user configuration.
		public var id: String
		
		/// Alternative ID count for enhanced security.
		///
		/// - `0`: Modern AEAD encryption (recommended)
		/// - `1-65535`: Legacy dynamic ID encryption (deprecated)
		///
		/// - Important: Use `0` for new deployments. Non-zero values are deprecated.
		public var alterId: Int
		
		/// Encryption method for the connection.
		///
		/// Defaults to `"auto"` which automatically negotiates the best available cipher.
		public var security: String
		
		/// User level for traffic statistics and routing policies.
		///
		/// Used by routing rules to apply different policies to different user levels.
		public var level: Int
		
		// MARK: - Initializers
		
		/// Creates a VMess user configuration.
		///
		/// - Parameters:
		///   - id: User UUID (must be valid UUID format)
		///   - alterId: Alternative ID count (use 0 for AEAD encryption)
		///   - security: Encryption method (default: "auto")
		///   - level: User level for routing (default: 0)
		public init(id: String, alterId: Int = 0, security: String = "auto", level: Int = 0) {
			self.id = id
			self.alterId = alterId
			self.security = security
			self.level = level
		}
	}
	
	// MARK: - Properties
	
	/// The target server address (domain or IP address).
	///
	/// Can be a domain name (e.g., "example.com") or an IP address (IPv4 or IPv6).
	public var address: String
	
	/// The target server port.
	///
	/// Common ports: 443 (HTTPS), 80 (HTTP), or custom ports based on server configuration.
	public var port: Int
	
	/// List of users for authentication.
	///
	/// Typically contains a single user in client configurations.
	public var users: [User]
	
	// MARK: - Initializers
	
	/// Creates a VMess configuration with explicit parameters.
	///
	/// - Parameters:
	///   - address: Target server address (domain or IP)
	///   - port: Target server port
	///   - users: Array of user configurations
	public init(address: String, port: Int, users: [User]) {
		self.address = address
		self.port = port
		self.users = users
	}
	
	/// Creates a VMess configuration from a parsed link.
	///
	/// Parses VMess URLs in various formats (JSON-based, URI-based) and extracts
	/// server address, port, and user credentials.
	///
	/// - Parameter parser: Link parser containing connection details
	/// - Throws: `TunnelXError.missingUserID` if the user ID is empty
	///
	/// ## Supported Parameters
	/// - `address` or `host`: Server address
	/// - `port`: Server port
	/// - `id` or `uuid`: User UUID
	/// - `alterId` or `aid`: Alternative ID (default: 0)
	/// - `security` or `scy`: Encryption method (default: "auto")
	/// - `level`: User level (default: 0)
	public init(_ parser: LinkParser) throws {
		let parametersMap = parser.parametersMap
		
		// Parse address (try multiple parameter names for compatibility)
		self.address = parametersMap["address"] ?? parser.host
		
		// Parse port
		if let portString = parametersMap["port"], let portValue = Int(portString) {
			self.port = portValue
		} else {
			self.port = parser.port
		}
		
		// Parse user ID (UUID)
		let id = parametersMap["id"] 
			?? parametersMap["uuid"] 
			?? parser.userID
		
		guard !id.isEmpty else {
			throw TunnelXError.missingUserID
		}
		
		// Parse alterId
		let alterId = Int(parametersMap["alterId"] ?? parametersMap["aid"] ?? "0") ?? 0
		
		// Parse security method
		let security = parametersMap["security"] ?? parametersMap["scy"] ?? "auto"
		
		// Parse user level
		let level = Int(parametersMap["level"] ?? "0") ?? 0
		
		// Create user
		self.users = [User(id: id, alterId: alterId, security: security, level: level)]
	}
}
