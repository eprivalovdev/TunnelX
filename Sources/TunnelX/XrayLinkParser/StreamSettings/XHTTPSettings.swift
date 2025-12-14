import Foundation

// MARK: - XHTTP Settings

/// XHTTP transport configuration.
///
/// Xray's custom HTTP-based protocol with optimizations.
/// Also used for SplitHTTP mode.
///
/// - SeeAlso: [Xray XHTTP Configuration](https://xtls.github.io/en/config/transport#xhttpobject)
public struct XHTTPSettings: Encodable, Parsable {
	
	// MARK: - Properties
	
	/// Operation mode ("auto", "packet-up", "stream-up", "stream-one").
	public var mode: String
	
	/// Request path.
	public var path: String
	
	// MARK: - Initializers
	
	/// Creates XHTTP settings from parsed link.
	public init(_ parser: LinkParser) throws {
		guard parser.network == .xhttp || parser.network == .splithttp else {
			throw TunnelXError.invalidNetworkType(expected: "xhttp", actual: parser.network.rawValue)
		}
		
		self.mode = parser.parametersMap["mode"] ?? "auto"
		self.path = parser.parametersMap["path"] ?? "/"
	}
	
	/// Creates XHTTP settings with explicit parameters.
	public init(mode: String = "auto", path: String = "/") {
		self.mode = mode
		self.path = path
	}
}
