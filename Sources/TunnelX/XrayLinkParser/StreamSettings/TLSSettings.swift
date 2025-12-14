import Foundation

// MARK: - TLS Settings

/// TLS (Transport Layer Security) configuration.
///
/// Standard TLS encryption with certificate validation and ALPN negotiation.
///
/// - SeeAlso: [Xray TLS Configuration](https://xtls.github.io/en/config/transport#tlsobject)
public struct TLSSettings: Encodable, Parsable {
	
	// MARK: - Nested Types
	
	/// Application-Layer Protocol Negotiation (ALPN) values.
	public enum ALPN: String, CaseIterable, Codable {
		/// HTTP/2 protocol.
		case h2 = "h2"
		
		/// HTTP/1.1 protocol.
		case http1_1 = "http/1.1"
	}
	
	// MARK: - Properties
	
	/// Server Name Indication (SNI) for TLS handshake.
	public var serverName: String
	
	/// Allow insecure certificates (for testing only).
	///
	/// - Warning: Never use in production.
	public var allowInsecure: Bool
	
	/// ALPN protocols to negotiate.
	public var alpn: [ALPN]
	
	/// Browser fingerprint to emulate.
	public var fingerprint: Fingerprint
	
	// MARK: - Initializers
	
	/// Creates TLS settings from parsed link.
	public init(_ parser: LinkParser) throws {
		guard parser.security == .tls else {
			throw TunnelXError.invalidSecurityType(expected: "tls", actual: parser.security.rawValue)
		}
		
		self.serverName = try String.sni(parser)
		self.fingerprint = try Fingerprint(parser)
		self.allowInsecure = false
		
		if let value = parser.parametersMap["alpn"], !value.isEmpty {
			self.alpn = value.components(separatedBy: ",").compactMap(ALPN.init)
		} else {
			self.alpn = ALPN.allCases
		}
	}
	
	/// Creates TLS settings with explicit parameters.
	public init(
		serverName: String = "",
		allowInsecure: Bool = false,
		alpn: [ALPN] = ALPN.allCases,
		fingerprint: Fingerprint = .chrome
	) {
		self.serverName = serverName
		self.allowInsecure = allowInsecure
		self.alpn = alpn
		self.fingerprint = fingerprint
	}
}
