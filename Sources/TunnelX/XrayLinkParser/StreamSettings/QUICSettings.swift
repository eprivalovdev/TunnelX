import Foundation

// MARK: - QUIC Settings

/// QUIC (Quick UDP Internet Connections) transport configuration.
///
/// Modern UDP-based protocol with built-in encryption and 0-RTT.
///
/// - SeeAlso: [Xray QUIC Configuration](https://xtls.github.io/en/config/transport#quicobject)
public struct QUICSettings: Encodable, Parsable {
	
	// MARK: - Nested Types
	
	/// Encryption method for QUIC.
	public enum Security: String, Encodable, CaseIterable {
		case none = "none"
		case aes_128_gcm = "aes-128-gcm"
		case chacha20_poly1305 = "chacha20-poly1305"
	}
	
	/// Header obfuscation type.
	public enum HeaderType: String, Encodable, CaseIterable {
		case none = "none"
		case srtp = "srtp"
		case utp = "utp"
		case wechat_video = "wechat-video"
		case dtls = "dtls"
		case wireguard = "wireguard"
	}
	
	/// Header configuration.
	public struct Header: Encodable {
		public var type: HeaderType
		
		public init(type: HeaderType = .none) {
			self.type = type
		}
	}
	
	// MARK: - Properties
	
	/// Encryption method.
	public var security: Security
	
	/// Encryption key (for non-none security).
	public var key: String?
	
	/// Header obfuscation configuration.
	public var header: Header
	
	// MARK: - Initializers
	
	/// Creates QUIC settings from parsed link.
	public init(_ parser: LinkParser) throws {
		guard parser.network == .quic else {
			throw TunnelXError.invalidNetworkType(expected: "quic", actual: parser.network.rawValue)
		}
		
		let params = parser.parametersMap
		
		if let s = params["quicSecurity"], let sec = Security(rawValue: s) {
			self.security = sec
		} else {
			self.security = .none
		}
		
		self.key = params["key"]
		
		if let ht = params["headerType"], let t = HeaderType(rawValue: ht) {
			self.header = Header(type: t)
		} else {
			self.header = Header()
		}
	}
	
	/// Creates QUIC settings with explicit parameters.
	public init(
		security: Security = .none,
		key: String? = nil,
		header: Header = Header()
	) {
		self.security = security
		self.key = key
		self.header = header
	}
}
