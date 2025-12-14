import Foundation

// MARK: - DNS Configuration

/// DNS configuration for Xray.
///
/// Controls how Xray resolves domain names, including custom DNS servers,
/// query strategies, and caching.
///
/// ## Example
/// ```swift
/// let dns = DNS(
///     servers: [
///         .address("8.8.8.8"),
///         .server(DNS.Server(
///             address: "1.1.1.1",
///             domains: ["geosite:geolocation-!cn"]
///         ))
///     ],
///     queryStrategy: .useIPv4
/// )
/// ```
///
/// - SeeAlso: [Xray DNS Configuration](https://xtls.github.io/en/config/dns)
public struct DNS: Codable {
	
	// MARK: - Nested Types
	
	/// DNS server configuration.
	public struct Server: Codable {
		
		// MARK: - Properties
		
		/// Skip fallback DNS if this server fails.
		public let skipFallback: Bool
		
		/// DNS server address (IP or domain).
		public let address: String
		
		/// Domain patterns for this server.
		///
		/// This server is only used for matching domains.
		/// Supports: plain, domain, geosite, etc.
		public let domains: [String]
		
		/// DNS server port.
		public let port: Int
		
		/// Expected IP ranges (CIDR format).
		///
		/// If resolved IPs don't match, try fallback servers.
		public let expectIPs: [String]?
		
		/// Client IP to send in DNS query.
		public let clientIP: String?
		
		// MARK: - Initializers
		
		public init(
			skipFallback: Bool = false,
			address: String,
			domains: [String] = [],
			port: Int = 53,
			expectIPs: [String]? = nil,
			clientIP: String? = nil
		) {
			self.skipFallback = skipFallback
			self.address = address
			self.domains = domains
			self.port = port
			self.expectIPs = expectIPs
			self.clientIP = clientIP
		}
	}
	
	/// IP version query strategy.
	public enum QueryStrategy: String, Codable, CaseIterable {
		/// Use IPv4 only.
		case useIPv4 = "UseIPv4"
		
		/// Use IPv6 only.
		case useIPv6 = "UseIPv6"
		
		/// Use both IPv4 and IPv6.
		case useIP = "UseIP"
	}
	
	// MARK: - Properties
	
	/// Disable fallback to system DNS.
	public var disableFallback: Bool
	
	/// DNS module ID (for routing).
	public var id: String
	
	/// Disable DNS query caching.
	public var disableCache: Bool
	
	/// IP version query strategy.
	public var queryStrategy: QueryStrategy
	
	/// Disable fallback if domain matches.
	public var disableFallbackIfMatch: Bool
	
	/// DNS servers list.
	public var servers: [EncodableDNSItem]
	
	/// Static hosts mapping (domain -> IP).
	public var hosts: [String: String]?
	
	/// Client IP for DNS queries.
	public var clientIP: String?
	
	/// DNS module tag for routing.
	public var tag: String?
	
	// MARK: - Initializers
	
	public init(
		disableFallback: Bool = false,
		id: String = UUID().uuidString,
		disableCache: Bool = false,
		queryStrategy: QueryStrategy = .useIPv4,
		disableFallbackIfMatch: Bool = false,
		servers: [EncodableDNSItem],
		hosts: [String: String]? = nil,
		clientIP: String? = nil,
		tag: String? = nil
	) {
		self.disableFallback = disableFallback
		self.id = id
		self.disableCache = disableCache
		self.queryStrategy = queryStrategy
		self.disableFallbackIfMatch = disableFallbackIfMatch
		self.servers = servers
		self.hosts = hosts
		self.clientIP = clientIP
		self.tag = tag
	}
}

// MARK: - DNS Item

/// DNS server item (address string or full server config).
public enum EncodableDNSItem: Codable {
	/// Simple DNS server address.
	case address(String)
	
	/// Full DNS server configuration.
	case server(DNS.Server)
	
	// MARK: - Encodable
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
		case .address(let address):
			try container.encode(address)
		case .server(let server):
			try container.encode(server)
		}
	}
}
