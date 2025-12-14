import Foundation

public struct Outbound: Encodable, Parsable {
	
	public private(set) var `protocol`: OutboundProtocol
	public private(set) var tag: String
	public private(set) var settings: OutboundConfigurationObject?
	public private(set) var streamSettings: StreamSettings?
	public private(set) var sendThrough: String?
	
	/// Creates an Outbound configuration from a parsed link
	/// - Parameter parser: The link parser containing connection details
	/// - Throws: TunnelXError if configuration building fails
	public init(_ parser: LinkParser) throws {
		`protocol` = parser.outboundProtocol
		tag = "proxy"
		settings = try OutboundConfigurationObject(parser)
		streamSettings = try StreamSettings(parser)
		sendThrough = "0.0.0.0"
	}
	
	/// Creates an Outbound configuration with explicit parameters
	/// - Parameters:
	///   - protocol: Outbound protocol type (default: vless)
	///   - tag: Tag identifier for routing (default: empty)
	///   - settings: Protocol-specific settings (optional)
	///   - streamSettings: Transport and security settings (optional)
	///   - sendThrough: Source IP address for outbound connections (default: "0.0.0.0")
	public init(
		`protocol`: OutboundProtocol = .vless,
		tag: String = String(),
		settings: OutboundConfigurationObject? = nil,
		streamSettings: StreamSettings? = nil,
		sendThrough: String? = "0.0.0.0"
	) {
		self.protocol = `protocol`
		self.tag = tag
		self.settings = settings
		self.streamSettings = streamSettings
		self.sendThrough = sendThrough
	}
}
