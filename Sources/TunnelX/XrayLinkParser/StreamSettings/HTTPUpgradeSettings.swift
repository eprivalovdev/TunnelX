import Foundation

// MARK: - HTTP Upgrade Settings

/// HTTP Upgrade transport configuration.
///
/// Similar to WebSocket but uses HTTP Upgrade mechanism differently.
///
/// - SeeAlso: [Xray HTTPUpgrade Configuration](https://xtls.github.io/en/config/transport#httpupgradeobject)
public struct HTTPUpgradeSettings: Encodable, Parsable {
	
	// MARK: - Properties
	
	/// Request path.
	public var path: String?
	
	/// Host header value.
	public var host: String?
	
	// MARK: - Initializers
	
	/// Creates HTTP Upgrade settings from parsed link.
	public init(_ parser: LinkParser) throws {
		guard parser.network == .httpupgrade else {
			throw TunnelXError.invalidNetworkType(expected: "httpupgrade", actual: parser.network.rawValue)
		}
		
		self.path = parser.parametersMap["path"]
		self.host = parser.parametersMap["host"]
	}
	
	/// Creates HTTP Upgrade settings with explicit parameters.
	public init(path: String? = nil, host: String? = nil) {
		self.path = path
		self.host = host
	}
}
