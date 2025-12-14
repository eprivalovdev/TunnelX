import Foundation

// MARK: - SOCKS Inbound Configuration

/// Configuration for SOCKS5 inbound protocol.
///
/// SOCKS5 is a versatile proxy protocol supporting both TCP and UDP traffic.
/// It's the most common inbound protocol for local proxy applications.
///
/// ## Features
/// - TCP and UDP support
/// - Optional authentication (username/password)
/// - User level for routing policies
/// - Configurable UDP relay address
///
/// ## Example Usage
///
/// ### No Authentication (Default)
/// ```swift
/// let socks = SocksInboundConfigurationObject(
///     auth: .noauth,
///     udp: true
/// )
/// ```
///
/// ### With Authentication
/// ```swift
/// let socks = SocksInboundConfigurationObject(
///     auth: .password,
///     udp: true,
///     userLevel: 0
/// )
/// ```
///
/// - Note: When using password authentication, configure users in the inbound policy.
///
/// - SeeAlso: [Xray SOCKS Inbound](https://xtls.github.io/en/config/inbounds/socks)
public struct SocksInboundConfigurationObject: Encodable {
	
	// MARK: - Nested Types
	
	/// Authentication method for SOCKS5 connections.
	public enum Auth: String, Encodable, CaseIterable {
		/// No authentication required (fastest, less secure).
		///
		/// Use for local-only connections where security isn't a concern.
		case noauth = "noauth"
		
		/// Username/password authentication.
		///
		/// Requires configuring user accounts in inbound settings.
		case password = "password"
	}
	
	// MARK: - Properties
	
	/// Authentication method to use.
	public let auth: Auth
	
	/// Enable UDP relay support.
	///
	/// When enabled, SOCKS5 clients can relay UDP packets through the proxy.
	/// Required for applications that need UDP (DNS, games, VoIP).
	public let udp: Bool
	
	/// Local IP address for UDP relay (optional).
	///
	/// Specifies which local IP to use for UDP relay.
	/// If nil, uses the same IP as the TCP listener.
	public let ip: String?
	
	/// User level for routing policies.
	///
	/// Used by routing rules to apply different policies based on user level.
	/// Matches the `level` field in routing rules.
	public let userLevel: Int?
	
	// MARK: - Initializers
	
	/// Creates SOCKS5 inbound configuration.
	///
	/// - Parameters:
	///   - auth: Authentication method (default: `.noauth`)
	///   - udp: Enable UDP relay (default: `true`)
	///   - ip: Local IP for UDP relay (default: nil)
	///   - userLevel: User level for routing (default: nil)
	public init(
		auth: Auth = .noauth,
		udp: Bool = true,
		ip: String? = nil,
		userLevel: Int? = nil
	) {
		self.auth = auth
		self.udp = udp
		self.ip = ip
		self.userLevel = userLevel
	}
	
	// MARK: - Encodable
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(auth, forKey: .auth)
		try container.encode(udp, forKey: .udp)
		try container.encodeIfPresent(ip, forKey: .ip)
		try container.encodeIfPresent(userLevel, forKey: .userLevel)
	}
	
	private enum CodingKeys: String, CodingKey {
		case auth
		case udp
		case ip
		case userLevel
	}
}

