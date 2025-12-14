import Foundation

// MARK: - Freedom Outbound Configuration

/// Configuration object for Freedom protocol outbound connections.
///
/// Freedom is Xray's direct connection protocol that routes traffic directly to its
/// destination without proxying. It's typically used as a fallback for local/direct
/// connections or specific routing rules.
///
/// ## Use Cases
/// - **Direct Access**: Route specific domains/IPs directly without proxy
/// - **Local Networks**: Access local services (192.168.x.x, 10.x.x.x)
/// - **Performance**: Bypass proxy for trusted destinations
/// - **Split Tunneling**: Selective routing based on rules
///
/// ## Routing Examples
/// ```swift
/// // Route local networks directly
/// Rule(
///     ip: ["192.168.0.0/16", "10.0.0.0/8"],
///     outboundTag: .direct
/// )
///
/// // Route specific domains directly
/// Rule(
///     domain: ["localhost", "local.dev"],
///     outboundTag: .direct
/// )
/// ```
///
/// ## Example Usage
/// ```swift
/// let freedomConfig = FreedomOutboundConfigurationObject(
///     domainStrategy: .useIP,
///     redirect: nil,
///     userLevel: 0
/// )
/// ```
///
/// - SeeAlso:
///   - [Xray Freedom Documentation](https://xtls.github.io/en/config/outbounds/freedom)
///   - `Route.Rule` for routing configuration
public struct FreedomOutboundConfigurationObject: Encodable, Parsable {
	
	// MARK: - Nested Types
	
	/// Domain resolution strategy for Freedom connections.
	///
	/// Controls how domain names are resolved before establishing direct connections.
	public enum DomainStrategy: String, Encodable, CaseIterable {
		/// Use the domain as-is (no pre-resolution)
		///
		/// The domain is passed to the system resolver, which handles DNS.
		/// Most compatible but may leak DNS queries.
		case asIs = "AsIs"
		
		/// Use IPv4 addresses only
		///
		/// Resolves domains to IPv4 addresses using Xray's internal DNS.
		/// Useful for IPv4-only networks.
		case useIPv4 = "UseIPv4"
		
		/// Use IPv6 addresses only
		///
		/// Resolves domains to IPv6 addresses using Xray's internal DNS.
		/// Useful for IPv6-only networks.
		case useIPv6 = "UseIPv6"
		
		/// Use both IPv4 and IPv6 (Happy Eyeballs)
		///
		/// Attempts both IPv4 and IPv6 connections simultaneously.
		/// Fastest connection wins. Recommended for modern networks.
		case useIP = "UseIP"
	}
	
	// MARK: - Properties
	
	/// Domain resolution strategy to use.
	///
	/// Determines how domain names in connection requests are handled.
	/// Defaults to `.asIs` for maximum compatibility.
	public let domainStrategy: DomainStrategy
	
	/// Redirect destination for all connections (format: `host:port`).
	///
	/// When set, all outbound connections are redirected to this address
	/// instead of their original destination. Useful for:
	/// - Transparent proxying
	/// - Testing and debugging
	/// - Traffic interception
	///
	/// Example: `"127.0.0.1:8080"` redirects all traffic to local proxy
	///
	/// - Note: Leave nil for normal direct connections
	public let redirect: String?
	
	/// User level for traffic statistics and policy routing.
	///
	/// Matches user levels defined in routing rules and policy settings.
	/// Used for applying different QoS or routing policies.
	public let userLevel: Int
	
	// MARK: - Initializers
	
	/// Creates a Freedom configuration with explicit parameters.
	///
	/// - Parameters:
	///   - domainStrategy: How to resolve domain names (default: `.asIs`)
	///   - redirect: Optional redirect destination (default: nil)
	///   - userLevel: User level for policies (default: 0)
	public init(
		domainStrategy: DomainStrategy = .asIs,
		redirect: String? = nil,
		userLevel: Int = 0
	) {
		self.domainStrategy = domainStrategy
		self.redirect = redirect
		self.userLevel = userLevel
	}
	
	/// Creates a Freedom configuration from a parsed link.
	///
	/// - Parameter parser: Link parser containing connection details
	/// - Throws: Never throws as Freedom doesn't require specific parameters
	///
	/// - Note: Freedom protocol doesn't use traditional connection URLs.
	///         This initializer exists for protocol conformance.
	public init(_ parser: LinkParser) throws {
		// Freedom doesn't parse from URLs, use defaults
		self.domainStrategy = .asIs
		self.redirect = nil
		self.userLevel = 0
	}
	
	// MARK: - Encodable
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(domainStrategy, forKey: .domainStrategy)
		try container.encodeIfPresent(redirect, forKey: .redirect)
		try container.encode(userLevel, forKey: .userLevel)
	}
	
	private enum CodingKeys: String, CodingKey {
		case domainStrategy
		case redirect
		case userLevel
	}
}
