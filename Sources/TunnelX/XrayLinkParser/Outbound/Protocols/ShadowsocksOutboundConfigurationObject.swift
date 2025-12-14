import Foundation

// MARK: - Shadowsocks Outbound Configuration

/// Configuration object for Shadowsocks protocol outbound connections.
///
/// Shadowsocks is a secure SOCKS5 proxy protocol designed to protect internet traffic
/// from censorship and surveillance. It uses various encryption methods to secure data
/// transmission while maintaining high performance.
///
/// ## Key Features
/// - **Multiple Cipher Support**: Various AEAD and stream ciphers
/// - **Password-Based Authentication**: Simple password-based encryption key derivation
/// - **UDP Support**: Optional UDP relay for applications that require it
/// - **2022 Edition**: New BLAKE3-based ciphers for improved security and performance
///
/// ## Cipher Selection
/// - **Recommended**: `2022-blake3-aes-256-gcm` or `2022-blake3-chacha20-poly1305`
/// - **Legacy**: `aes-256-gcm`, `chacha20-poly1305` (still secure but older)
/// - **Avoid**: `none`, `plain` (no encryption, testing only)
///
/// ## Example Usage
/// ```swift
/// let ssConfig = ShadowsocksOutboundConfigurationObject(
///     address: "example.com",
///     port: 8388,
///     method: ._2022_blake3_aes_256_gcm,
///     password: "your-base64-encoded-key",
///     level: 0
/// )
/// ```
///
/// - SeeAlso:
///   - [Xray Shadowsocks Documentation](https://xtls.github.io/en/config/outbounds/shadowsocks)
///   - [Shadowsocks 2022 Edition](https://github.com/Shadowsocks-NET/shadowsocks-specs/blob/main/2022-1-shadowsocks-2022-edition.md)
public struct ShadowsocksOutboundConfigurationObject: Encodable, Parsable {
	
	// MARK: - Nested Types
	
	/// Encryption method for Shadowsocks connections.
	///
	/// Shadowsocks supports various AEAD (Authenticated Encryption with Associated Data)
	/// ciphers for securing traffic. The 2022 edition ciphers use BLAKE3 for improved
	/// performance and security.
	public enum Method: String, Identifiable, CustomStringConvertible, Codable, CaseIterable, Equatable {
		
		public var id: Self { self }
		
		// MARK: - 2022 Edition (Recommended)
		
		/// BLAKE3-AES-128-GCM - 2022 Edition cipher with 128-bit key
		///
		/// Fast and secure, suitable for most use cases. Lower key size provides
		/// better performance on systems without AES hardware acceleration.
		case _2022_blake3_aes_128_gcm = "2022-blake3-aes-128-gcm"
		
		/// BLAKE3-AES-256-GCM - 2022 Edition cipher with 256-bit key
		///
		/// Maximum security with AES-256. Best for systems with AES-NI support.
		/// Recommended for high-security requirements.
		case _2022_blake3_aes_256_gcm = "2022-blake3-aes-256-gcm"
		
		/// BLAKE3-ChaCha20-Poly1305 - 2022 Edition cipher
		///
		/// Excellent performance on ARM devices and systems without AES hardware.
		/// Recommended for mobile devices and embedded systems.
		case _2022_blake3_chacha20_poly1305 = "2022-blake3-chacha20-poly1305"
		
		// MARK: - Legacy AEAD Ciphers
		
		/// AES-256-GCM - Legacy AEAD cipher
		///
		/// Widely supported, secure, and fast on systems with AES-NI.
		/// Good compatibility with older Shadowsocks implementations.
		case aes_256_gcm = "aes-256-gcm"
		
		/// AES-128-GCM - Legacy AEAD cipher
		///
		/// Faster than AES-256 with slightly lower security margin.
		/// Still considered cryptographically secure.
		case aes_128_gcm = "aes-128-gcm"
		
		/// ChaCha20-Poly1305 - Legacy AEAD cipher
		///
		/// Software-friendly cipher, excellent for devices without AES acceleration.
		case chacha20_poly1305 = "chacha20-poly1305"
		
		/// ChaCha20-IETF-Poly1305 - IETF standardized variant
		///
		/// Standardized version of ChaCha20-Poly1305 (RFC 8439).
		case chacha20_ietf_poly1305 = "chacha20-ietf-poly1305"
		
		// MARK: - Testing Only (Not Secure)
		
		/// Plain text - No encryption
		///
		/// - Warning: Only for testing. Never use in production environments.
		case plain = "plain"
		
		/// No encryption
		///
		/// - Warning: Only for testing. Never use in production environments.
		case none = "none"
		
		// MARK: - CustomStringConvertible
		
		/// Human-readable description of the encryption method.
		public var description: String {
			switch self {
			case ._2022_blake3_aes_128_gcm:
				return "2022-Blake3-AES-128-GCM"
			case ._2022_blake3_aes_256_gcm:
				return "2022-Blake3-AES-256-GCM"
			case ._2022_blake3_chacha20_poly1305:
				return "2022-Blake3-ChaCha20-Poly1305"
			case .aes_256_gcm:
				return "AES-256-GCM"
			case .aes_128_gcm:
				return "AES-128-GCM"
			case .chacha20_poly1305:
				return "ChaCha20-Poly1305"
			case .chacha20_ietf_poly1305:
				return "ChaCha20-IETF-Poly1305"
			case .none:
				return "None"
			case .plain:
				return "Plain"
			}
		}
	}
	
	// MARK: - Properties
	
	/// The target server address (domain or IP address).
	///
	/// Can be a domain name (e.g., "example.com") or an IP address (IPv4 or IPv6).
	public var address: String
	
	/// The target server port.
	///
	/// Common Shadowsocks ports: 8388, 443, or custom ports.
	public var port: Int
	
	/// Encryption method for the connection.
	///
	/// Determines the cipher algorithm used to encrypt traffic. Use 2022 edition
	/// ciphers for best security and performance.
	///
	/// - SeeAlso: `Method` for available encryption methods
	public var method: Method
	
	/// Password for encryption key derivation.
	///
	/// For 2022 edition ciphers, this should be a base64-encoded key of appropriate length:
	/// - 128-bit ciphers: 16-byte key (base64: 24 chars)
	/// - 256-bit ciphers: 32-byte key (base64: 44 chars)
	///
	/// For legacy ciphers, this can be any string (key will be derived via EVP_BytesToKey).
	///
	/// - Important: Use cryptographically secure random keys for production deployments.
	public var password: String?
	
	/// Optional email address for identification.
	///
	/// Used for logging and statistics. Not used for authentication or encryption.
	public var email: String?
	
	/// User level for traffic statistics and routing policies.
	///
	/// Used by routing rules to apply different policies to different user levels.
	public var level: Int?
	
	/// Enable UDP over TCP (UoT) encapsulation.
	///
	/// When enabled, UDP packets are encapsulated in TCP connections for environments
	/// where UDP is blocked or unreliable.
	///
	/// - Note: Requires server-side support for UoT.
	public var uot: Bool?
	
	/// UDP over TCP protocol version.
	///
	/// Specifies which UoT version to use. Currently supported: 1.
	public var uotVersion: Int?
	
	// MARK: - Initializers
	
	/// Creates a Shadowsocks configuration with explicit parameters.
	///
	/// - Parameters:
	///   - address: Target server address (domain or IP)
	///   - port: Target server port (default: 8388)
	///   - method: Encryption method (default: `.none`)
	///   - password: Encryption password/key (default: empty)
	///   - email: Optional email for identification (default: nil)
	///   - level: User level for routing (default: 0)
	///   - uot: Enable UDP over TCP (default: nil)
	///   - uotVersion: UoT protocol version (default: nil)
	public init(
		address: String = "",
		port: Int = 8388,
		method: Method = .none,
		password: String = "",
		email: String? = nil,
		level: Int = 0,
		uot: Bool? = nil,
		uotVersion: Int? = nil
	) {
		self.address = address
		self.port = port
		self.method = method
		self.password = password
		self.email = email
		self.level = level
		self.uot = uot
		self.uotVersion = uotVersion
	}
	
	/// Creates a Shadowsocks configuration from a parsed link.
	///
	/// Parses Shadowsocks URLs (SIP002 format and legacy formats) and extracts
	/// server configuration details.
	///
	/// - Parameter parser: Link parser containing connection details
	/// - Throws: `TunnelXError` if required parameters are missing
	///
	/// ## Supported URL Formats
	/// - SIP002: `ss://base64(method:password)@host:port`
	/// - Legacy: Parameters in query string
	///
	/// ## Supported Parameters
	/// - `address` or `host`: Server address
	/// - `port`: Server port
	/// - `method`: Encryption method
	/// - `password`: Encryption key/password
	/// - `email`: User identification (optional)
	/// - `level`: User level (optional)
	/// - `uot`: UDP over TCP flag (optional)
	/// - `uot_version`: UoT version (optional)
	public init(_ parser: LinkParser) throws {
		let parametersMap = parser.parametersMap
		
		// Parse address
		self.address = parametersMap["address"] ?? parser.host
		
		// Parse port
		if let portString = parametersMap["port"], let portValue = Int(portString) {
			self.port = portValue
		} else {
			self.port = parser.port != 0 ? parser.port : 8388
		}
		
		// Parse encryption method
		if let methodString = parametersMap["method"], let methodValue = Method(rawValue: methodString) {
			self.method = methodValue
		} else {
			self.method = .none
		}
		
		// Parse password
		self.password = parametersMap["password"]
		
		// Parse optional fields
		self.email = parametersMap["email"]
		self.level = parametersMap["level"].flatMap { Int($0) }
		self.uot = parametersMap["uot"].map { ($0 as NSString).boolValue }
		self.uotVersion = parametersMap["uot_version"].flatMap { Int($0) }
	}
	
	// MARK: - Encodable
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(address, forKey: .address)
		try container.encode(port, forKey: .port)
		try container.encode(method, forKey: .method)
		
		try container.encodeIfPresent(password, forKey: .password)
		try container.encodeIfPresent(email, forKey: .email)
		try container.encodeIfPresent(level, forKey: .level)
		try container.encodeIfPresent(uot, forKey: .uot)
		try container.encodeIfPresent(uotVersion, forKey: .uotVersion)
	}
	
	private enum CodingKeys: String, CodingKey {
		case address
		case port
		case method
		case password
		case email
		case level
		case uot
		case uotVersion = "UoTVersion"
	}
}
