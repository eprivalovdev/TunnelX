import Foundation

// MARK: - Reality Settings

/// Reality protocol configuration for anti-detection TLS.
///
/// Reality provides perfect TLS camouflage by mimicking legitimate websites.
/// Server responds like the real website to invalid clients.
///
/// - SeeAlso: [Reality Protocol](https://github.com/XTLS/Reality)
public struct RealitySettings: Encodable, Parsable {
	
	// MARK: - Properties
	
	/// Show debug information (optional).
	public private(set) var show: Bool?
	
	/// Browser fingerprint to emulate.
	public private(set) var fingerprint: Fingerprint
	
	/// Server name to mimic (must be a real HTTPS website).
	public private(set) var serverName: String
	
	/// Server's public key (base64 encoded).
	public private(set) var publicKey: String
	
	/// Short ID for routing (0-16 hex characters).
	public private(set) var shortId: String?
	
	/// Spider X - random destination URLs for camouflage.
	public private(set) var spiderX: String?
	
	// MARK: - Initializers
	
	/// Creates Reality settings from parsed link.
	public init(_ parser: LinkParser) throws {
		guard parser.security == .reality else {
			throw TunnelXError.invalidSecurityType(expected: "reality", actual: parser.security.rawValue)
		}
		
		guard let pbk = parser.parametersMap["pbk"], !pbk.isEmpty else {
			throw TunnelXError.missingRealityPublicKey
		}
		
		self.publicKey = pbk
		self.serverName = try String.sni(parser)
		self.fingerprint = try Fingerprint(parser)
		self.shortId = parser.parametersMap["sid"]
		self.spiderX = parser.parametersMap["spx"]
		self.show = nil
	}
	
	/// Creates Reality settings with explicit parameters.
	public init(
		show: Bool? = nil,
		fingerprint: Fingerprint = .chrome,
		serverName: String = "",
		publicKey: String = "",
		shortId: String? = nil,
		spiderX: String? = nil
	) {
		self.show = show
		self.fingerprint = fingerprint
		self.serverName = serverName
		self.publicKey = publicKey
		self.shortId = shortId
		self.spiderX = spiderX
	}
}
