import Foundation

// MARK: - VLESS User

/// Represents a user configuration for VLESS protocol outbound connections.
///
/// VLESS is a stateless protocol designed for efficient proxying with minimal overhead.
/// Each user is identified by a UUID and can optionally use flow control for advanced features.
///
/// ## Flow Control Options
/// - `xtls-rprx-vision`: XTLS Vision flow control for enhanced performance
/// - `xtls-rprx-vision-udp443`: Vision with UDP 443 support
/// - `none` or empty: No flow control (default)
///
/// ## Encryption
/// VLESS itself doesn't encrypt data. Encryption is provided by the transport layer (TLS/Reality).
///
/// ## Example
/// ```swift
/// let user = User(
///     id: "b831381d-6324-4d53-ad4f-8cda48b30811",
///     flow: .xtlsRprxVision,
///     encryption: .none,
///     level: 0
/// )
/// ```
///
/// - SeeAlso: [Xray VLESS Documentation](https://xtls.github.io/en/config/outbounds/vless)
public struct User: Encodable, Parsable {
	
	// MARK: - Nested Types
	
	/// Flow control mechanism for VLESS connections.
	///
	/// Flow control enables advanced features like XTLS (Xray TLS) for improved performance
	/// by reducing unnecessary encryption layers.
	public enum Flow: String, Encodable, CaseIterable {
		/// XTLS Vision flow control - recommended for most use cases
		case xtlsRprxVision = "xtls-rprx-vision"
		
		/// XTLS Vision with UDP 443 support
		case xtlsRprxVisionUdp443 = "xtls-rprx-vision-udp443"
		
		/// No flow control (empty string for compatibility)
		case none = ""
	}
	
	/// Encryption method for VLESS protocol.
	///
	/// VLESS currently only supports "none" as encryption is handled by the transport layer.
	public enum Encryption: String, Encodable {
		/// No encryption at VLESS protocol level (encryption via TLS/Reality)
		case none = "none"
	}
	
	// MARK: - Properties
	
	/// Unique identifier for the user (UUID format).
	///
	/// This must match the UUID configured on the server side.
	public let id: String
	
	/// Flow control mechanism to use for this connection.
	///
	/// Defaults to `.none`. Use `.xtlsRprxVision` for optimal performance with compatible servers.
	public let flow: Flow
	
	/// Encryption method for the VLESS protocol layer.
	///
	/// Always "none" for VLESS as encryption is provided by transport security (TLS/Reality).
	public let encryption: Encryption
	
	/// User level for traffic statistics and routing policies.
	///
	/// Used by routing rules to apply different policies to different user levels.
	/// Defaults to 0.
	public let level: Int
	
	// MARK: - Initializers
	
	/// Creates a VLESS user configuration from a parsed link.
	///
	/// Extracts user credentials and flow control settings from the parsed URL.
	///
	/// - Parameter parser: Link parser containing user credentials and settings
	/// - Throws: `TunnelXError.missingUserID` if the user ID is empty
	public init(_ parser: LinkParser) throws {
		let parametersMap = parser.parametersMap
		
		// Get user ID from parser (UUID)
		let userId = parser.userID
		guard !userId.isEmpty else {
			throw TunnelXError.missingUserID
		}
		self.id = userId
		
		// Parse flow control
		if let flowString = parametersMap["flow"], !flowString.isEmpty {
			self.flow = Flow(rawValue: flowString) ?? .none
		} else {
			self.flow = .none
		}
		
		// Parse encryption (always "none" for VLESS)
		if let encString = parametersMap["encryption"] {
			self.encryption = Encryption(rawValue: encString) ?? .none
		} else {
			self.encryption = .none
		}
		
		// Parse level
		if let levelString = parametersMap["level"], let levelValue = Int(levelString) {
			self.level = levelValue
		} else {
			self.level = 0
		}
	}
	
	/// Creates a VLESS user configuration with explicit parameters.
	///
	/// - Parameters:
	///   - id: Unique user identifier (UUID format)
	///   - flow: Flow control mechanism (default: `.none`)
	///   - encryption: Encryption method (default: `.none`)
	///   - level: User level for routing policies (default: `0`)
	public init(
		id: String,
		flow: Flow = .none,
		encryption: Encryption = .none,
		level: Int = 0
	) {
		self.id = id
		self.flow = flow
		self.encryption = encryption
		self.level = level
	}
	
	// MARK: - Encodable
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(id, forKey: .id)
		try container.encode(encryption, forKey: .encryption)
		try container.encode(level, forKey: .level)
		
		// Only encode flow if it's not empty
		if flow != .none {
			try container.encode(flow, forKey: .flow)
		}
	}
	
	private enum CodingKeys: String, CodingKey {
		case id
		case flow
		case encryption
		case level
	}
}
