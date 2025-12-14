import Foundation

// MARK: - HTTP/2 Settings

/// HTTP/2 (h2) transport configuration.
///
/// HTTP/2 with multiplexing and header compression. Excellent for CDN compatibility.
///
/// - SeeAlso: [Xray HTTP/2 Configuration](https://xtls.github.io/en/config/transport#httpobject)
public struct HTTPSettings: Encodable, Parsable {
	
	// MARK: - Properties
	
	/// Host addresses for HTTP/2 connections.
	public var host: [String]?
	
	/// Request path.
	public var path: String?
	
	/// HTTP method (GET, POST, etc.).
	public var method: String?
	
	/// Custom HTTP headers.
	public var headers: [String: String]?
	
	// MARK: - Initializers
	
	/// Creates HTTP/2 settings from parsed link.
	public init(_ parser: LinkParser) throws {
		guard parser.network == .http else {
			throw TunnelXError.invalidNetworkType(expected: "http", actual: parser.network.rawValue)
		}
		
		let params = parser.parametersMap
		
		// Parse host (comma-separated)
		if let hostStr = params["host"], !hostStr.isEmpty {
			self.host = hostStr.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
		} else {
			self.host = nil
		}
		
		self.path = params["path"]
		self.method = params["method"]
		
		// Parse headers (pipe-separated key:value pairs)
		if let headersRaw = params["headers"], !headersRaw.isEmpty {
			var map: [String: String] = [:]
			headersRaw.split(separator: "|").forEach { pair in
				let parts = pair.split(separator: ":", maxSplits: 1).map { String($0) }
				if parts.count == 2 {
					let key = parts[0].trimmingCharacters(in: .whitespaces)
					let value = parts[1].trimmingCharacters(in: .whitespaces)
					map[key] = value
				}
			}
			self.headers = map.isEmpty ? nil : map
		} else {
			self.headers = nil
		}
	}
	
	/// Creates HTTP/2 settings with explicit parameters.
	public init(
		host: [String]? = nil,
		path: String? = nil,
		method: String? = nil,
		headers: [String: String]? = nil
	) {
		self.host = host
		self.path = path
		self.method = method
		self.headers = headers
	}
}
