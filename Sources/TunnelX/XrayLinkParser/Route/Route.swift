import Foundation

// MARK: - Route

/// Routing configuration for traffic distribution.
///
/// Routes determine how connections are handled based on various conditions
/// like domain, IP, protocol, etc.
///
/// ## Example
/// ```swift
/// let route = Route(
///     domainStrategy: .ipIfNonMatch,
///     rules: [
///         Route.Rule(domain: ["geosite:cn"], outboundTag: .direct),
///         Route.Rule(ip: ["geoip:private"], outboundTag: .direct),
///         Route.Rule(outboundTag: .proxy)
///     ]
/// )
/// ```
///
/// - SeeAlso: [Xray Routing](https://xtls.github.io/en/config/routing)
public struct Route: Codable {
	
	// MARK: - Nested Types
	
	/// Domain resolution strategy.
	public enum DomainStrategy: String, Codable, CaseIterable {
		/// Use domain as-is without resolution.
		case asIs = "AsIs"
		
		/// Resolve to IP if domain doesn't match any rules.
		case ipIfNonMatch = "IPIfNonMatch"
		
		/// Resolve to IP on demand when needed for routing.
		case ipOnDemand = "IPOnDemand"
	}
	
	/// Domain matching algorithm.
	public enum DomainMatcher: String, Codable, CaseIterable {
		/// Hybrid matcher (balanced speed/memory).
		case hybrid = "hybrid"
		
		/// Linear matcher (low memory, slower).
		case linear = "linear"
	}
	
	/// Outbound tag reference.
	public enum Outbound: String, Codable, CaseIterable {
		/// Direct connection (no proxy).
		case direct = "direct"
		
		/// Proxy connection.
		case proxy = "proxy"
		
		/// Block connection.
		case block = "block"
	}
	
	/// Routing rule configuration.
	public struct Rule: Codable {
		
		// MARK: - Properties
		
		/// Domain matcher for this rule.
		public let domainMatcher: DomainMatcher?
		
		/// Rule type (always "field").
		public let type: String = "field"
		
		/// Domain patterns to match.
		///
		/// Supports:
		/// - Plain: `"example.com"`
		/// - Subdomain: `"domain:example.com"`
		/// - Full: `"full:example.com"`
		/// - Regex: `"regexp:.*\\.example\\.com$"`
		/// - GeoSite: `"geosite:cn"`, `"geosite:category-ads-all"`
		public let domain: [String]?
		
		/// IP ranges to match (CIDR format).
		///
		/// Supports:
		/// - CIDR: `"10.0.0.0/8"`, `"192.168.0.0/16"`
		/// - GeoIP: `"geoip:cn"`, `"geoip:private"`
		public let ip: [String]?
		
		/// Port or port range (e.g., "80", "1000-2000").
		public let port: String?
		
		/// Source port or port range.
		public let sourcePort: String?
		
		/// Network type ("tcp", "udp", or "tcp,udp").
		public let network: String?
		
		/// Source IP ranges (CIDR format).
		public let source: [String]?
		
		/// User email list for VMess/VLESS.
		public let user: [String]?
		
		/// Inbound tags to match.
		public let inboundTag: [String]?
		
		/// Protocol list ("http", "tls", "bittorrent", etc.).
		public let `protocol`: [String]?
		
		/// Custom attributes query.
		public let attrs: String?
		
		/// Target outbound tag.
		public let outboundTag: Outbound
		
		/// Load balancer tag (for balancing).
		public let balancerTag: String?
		
		// MARK: - Initializers
		
		public init(
			domainMatcher: DomainMatcher? = nil,
			type: String = "field",
			domain: [String]? = nil,
			ip: [String]? = nil,
			port: String? = nil,
			sourcePort: String? = nil,
			network: String? = nil,
			source: [String]? = nil,
			user: [String]? = nil,
			inboundTag: [String]? = nil,
			`protocol`: [String]? = nil,
			attrs: String? = nil,
			outboundTag: Outbound = .direct,
			balancerTag: String? = nil
		) {
			self.domainMatcher = domainMatcher
			self.domain = domain
			self.ip = ip
			self.port = port
			self.sourcePort = sourcePort
			self.network = network
			self.source = source
			self.user = user
			self.inboundTag = inboundTag
			self.protocol = `protocol`
			self.attrs = attrs
			self.outboundTag = outboundTag
			self.balancerTag = balancerTag
		}
	}
	
	/// Load balancer configuration.
	public struct Balancer: Codable {
		/// Balancer tag.
		public let tag: String
		
		/// Outbound selectors.
		public let selector: [String]
		
		/// Balancing strategy (optional).
		public let strategy: String?
		
		public init(
			tag: String,
			selector: [String] = [],
			strategy: String? = nil
		) {
			self.tag = tag
			self.selector = selector
			self.strategy = strategy
		}
	}
	
	// MARK: - Properties
	
	/// Domain resolution strategy.
	public let domainStrategy: DomainStrategy
	
	/// Domain matching algorithm.
	public let domainMatcher: DomainMatcher?
	
	/// Routing rules (evaluated in order).
	public let rules: [Rule]
	
	/// Load balancers configuration.
	public let balancers: [Balancer]?
	
	// MARK: - Initializers
	
	public init(
		domainStrategy: DomainStrategy = .asIs,
		domainMatcher: DomainMatcher? = nil,
		rules: [Rule] = [],
		balancers: [Balancer]? = nil
	) {
		self.domainStrategy = domainStrategy
		self.domainMatcher = domainMatcher
		self.rules = rules
		self.balancers = balancers
	}
}
