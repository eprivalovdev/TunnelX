import Foundation

// MARK: - Trojan Outbound Configuration

/// Configuration object for Trojan protocol outbound connections.
///
/// Trojan is a proxy protocol designed to disguise traffic as standard HTTPS traffic,
/// making it difficult to detect and block. It achieves this by mimicking the behavior
/// of legitimate TLS connections while providing secure proxying capabilities.
///
/// ## Key Features
/// - **TLS Camouflage**: Traffic appears as regular HTTPS, making detection difficult
/// - **Password Authentication**: Simple password-based user authentication
/// - **High Performance**: Minimal protocol overhead
/// - **TLS Required**: Always uses TLS for encryption (configured in StreamSettings)
///
/// ## Security Considerations
/// - Passwords are transmitted over TLS, so TLS configuration is mandatory
/// - Use strong, randomly generated passwords
/// - Server must have a valid TLS certificate
///
/// ## Example Usage
/// ```swift
/// let trojanConfig = TrojanOutboundConfigurationObject(
///     address: "example.com",
///     port: 443,
///     password: "your-secure-password-here"
/// )
/// ```
///
/// - Important: Trojan protocol requires TLS configuration in `StreamSettings`.
///              The protocol will not function without proper TLS setup.
///
/// - SeeAlso:
///   - [Xray Trojan Documentation](https://xtls.github.io/en/config/outbounds/trojan)
///   - `StreamSettings.TLS` for TLS configuration details
public struct TrojanOutboundConfigurationObject: Encodable, Parsable {
	
	// MARK: - Properties
	
	/// The target server address (domain or IP address).
	///
	/// For best camouflage, use a domain name that matches the TLS certificate's SNI.
	public var address: String
	
	/// The target server port.
	///
	/// Standard HTTPS port (443) is recommended for better camouflage.
	public var port: Int
	
	/// Password for authentication.
	///
	/// This password must match the server-side configuration. Use a strong,
	/// randomly generated password for security.
	///
	/// - Important: Generate passwords using cryptographically secure random generators.
	///              Avoid using dictionary words or predictable patterns.
	public var password: String
	
	/// Optional email address for identification purposes.
	///
	/// Used for logging and statistics on the server side. Not used for authentication.
	public var email: String?
	
	/// User level for traffic statistics and routing policies.
	///
	/// Used by routing rules to apply different policies to different user levels.
	/// Defaults to 0 if not specified.
	public var level: Int?
	
	// MARK: - Initializers
	
	/// Creates a Trojan configuration with explicit parameters.
	///
	/// - Parameters:
	///   - address: Target server address (domain or IP)
	///   - port: Target server port (default: 443)
	///   - password: Authentication password
	///   - email: Optional email for identification (default: nil)
	///   - level: User level for routing policies (default: nil, uses server default)
	///
	/// - Note: Default port is intentionally 443 (not 433 as in previous version)
	public init(
		address: String = "",
		port: Int = 443,
		password: String = "",
		email: String? = nil,
		level: Int? = nil
	) {
		self.address = address
		self.port = port
		self.password = password
		self.email = email
		self.level = level
	}
	
	/// Creates a Trojan configuration from a parsed link.
	///
	/// Parses Trojan URLs (e.g., `trojan://password@host:port?params...`) and extracts
	/// server address, port, and authentication credentials.
	///
	/// - Parameter parser: Link parser containing connection details
	/// - Throws: `TunnelXError` if required parameters are missing
	///
	/// ## Supported Parameters
	/// - URL format: `trojan://password@host:port`
	/// - Query parameters:
	///   - `password`: Authentication password (can also be in userID field)
	///   - `email`: User email for identification
	///   - `level`: User level for routing
	public init(_ parser: LinkParser) throws {
		let parametersMap = parser.parametersMap
		
		// Parse address
		self.address = parametersMap["address"] ?? parser.host
		
		// Parse port
		if let portString = parametersMap["port"], let portValue = Int(portString) {
			self.port = portValue
		} else {
			self.port = parser.port != 0 ? parser.port : 443
		}
		
		// Parse password (can be in parameters or userID field for some URL formats)
		self.password = parametersMap["password"] ?? parser.userID
		
		// Parse optional fields
		self.email = parametersMap["email"]
		self.level = parametersMap["level"].flatMap { Int($0) }
	}
}
