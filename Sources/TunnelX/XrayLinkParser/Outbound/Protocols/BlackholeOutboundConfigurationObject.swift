import Foundation

// MARK: - Blackhole Outbound Configuration

/// Configuration object for Blackhole protocol outbound connections.
///
/// Blackhole is Xray's connection blocking protocol that discards all traffic sent to it.
/// It's used to implement blocking rules for unwanted traffic, such as ads, trackers,
/// or blocked domains.
///
/// ## Use Cases
/// - **Ad Blocking**: Block advertising domains
/// - **Tracker Blocking**: Prevent analytics and tracking
/// - **Malware Protection**: Block known malicious domains
/// - **Content Filtering**: Enforce access policies
/// - **Privacy**: Block telemetry and data collection
///
/// ## Response Types
/// The Blackhole protocol supports two response strategies:
/// - **None**: Silently drop packets (no response)
/// - **HTTP**: Send HTTP error responses for HTTP requests
///
/// ## Routing Examples
/// ```swift
/// // Block advertising domains
/// Rule(
///     domain: ["geosite:category-ads-all"],
///     outboundTag: .block
/// )
///
/// // Block specific IPs
/// Rule(
///     ip: ["1.2.3.4", "5.6.7.8"],
///     outboundTag: .block
/// )
/// ```
///
/// ## Example Usage
/// ```swift
/// // Silent blocking
/// let blackhole = BlackholeOutboundConfigurationObject(
///     response: .none
/// )
///
/// // HTTP error responses
/// let httpBlock = BlackholeOutboundConfigurationObject(
///     response: .http
/// )
/// ```
///
/// - Note: Blackhole is typically combined with routing rules to selectively block traffic.
///
/// - SeeAlso:
///   - [Xray Blackhole Documentation](https://xtls.github.io/en/config/outbounds/blackhole)
///   - `Route.Rule` for routing configuration
public struct BlackholeOutboundConfigurationObject: Encodable, Parsable {
	
	// MARK: - Nested Types
	
	/// Response strategy for blocked connections.
	///
	/// Determines how the Blackhole protocol responds to connection attempts.
	public enum ResponseType: String, Encodable, CaseIterable {
		/// Silently drop all packets without any response.
		///
		/// The connection attempt times out naturally. This is stealthier
		/// but may cause applications to wait for timeout periods.
		///
		/// - Use when: You want maximum stealth and don't mind timeouts
		case none = "none"
		
		/// Send HTTP error responses for HTTP/HTTPS requests.
		///
		/// Returns immediate HTTP error responses (typically 403 Forbidden),
		/// allowing browsers and applications to fail quickly.
		///
		/// - Use when: Blocking web content and want fast failure
		/// - Note: Only works for HTTP-based protocols
		case http = "http"
	}
	
	// MARK: - Properties
	
	/// Response strategy for blocked connections.
	///
	/// Determines what happens when traffic is routed to the Blackhole:
	/// - `.none`: Silent drop (default, most stealthy)
	/// - `.http`: HTTP error response (faster failure for web traffic)
	public let response: ResponseType
	
	// MARK: - Initializers
	
	/// Creates a Blackhole configuration with explicit response type.
	///
	/// - Parameter response: Response strategy for blocked connections (default: `.none`)
	///
	/// ## Choosing Response Type
	/// - Use `.none` for:
	///   - Maximum stealth
	///   - Non-HTTP protocols
	///   - When you don't mind timeout delays
	///
	/// - Use `.http` for:
	///   - Web content blocking
	///   - Faster application response
	///   - User-facing block messages
	public init(response: ResponseType = .none) {
		self.response = response
	}
	
	/// Creates a Blackhole configuration from a parsed link.
	///
	/// - Parameter parser: Link parser containing connection details
	/// - Throws: Never throws as Blackhole doesn't require specific parameters
	///
	/// - Note: Blackhole protocol doesn't use traditional connection URLs.
	///         This initializer exists for protocol conformance and uses
	///         default values.
	public init(_ parser: LinkParser) throws {
		// Blackhole doesn't parse from URLs, use default silent blocking
		self.response = .none
	}
	
	// MARK: - Encodable
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(["type": response.rawValue], forKey: .response)
	}
	
	private enum CodingKeys: String, CodingKey {
		case response
	}
}
