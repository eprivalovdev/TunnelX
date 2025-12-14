import Foundation

// MARK: - VLESS Outbound Configuration

/// Configuration object for VLESS protocol outbound connections.
///
/// VLESS (Verified Less) is a stateless, lightweight proxy protocol developed by the Xray project.
/// It provides efficient proxying with minimal protocol overhead and supports advanced features
/// like XTLS flow control for improved performance.
///
/// ## Key Features
/// - **Stateless Design**: No complex state management, reducing overhead
/// - **UUID-Based Authentication**: Simple yet secure user identification
/// - **XTLS Support**: Optional flow control for enhanced performance
/// - **Flexible Transport**: Works with any transport protocol (TCP, WebSocket, gRPC, etc.)
///
/// ## Configuration Structure
/// A VLESS outbound defines:
/// - Target server address and port
/// - List of users (typically one for client configurations)
/// - Transport and security settings (via `StreamSettings`)
///
/// ## Example Usage
/// ```swift
/// let vlessConfig = VlessOutboundConfigurationObject(
///     address: "example.com",
///     port: 443,
///     users: [
///         User(
///             id: "b831381d-6324-4d53-ad4f-8cda48b30811",
///             flow: .xtlsRprxVision,
///             encryption: .none
///         )
///     ]
/// )
/// ```
///
/// - Note: VLESS protocol itself doesn't provide encryption. Use TLS or Reality
///         in `StreamSettings` for secure connections.
///
/// - SeeAlso:
///   - [Xray VLESS Documentation](https://xtls.github.io/en/config/outbounds/vless)
///   - `User` for user configuration details
///   - `StreamSettings` for transport and security configuration
public struct VlessOutboundConfigurationObject: Encodable, Parsable {
	
	// MARK: - Properties
	
	/// The target server address (domain or IP address).
	///
	/// Can be a domain name (e.g., "example.com") or an IP address (IPv4 or IPv6).
	public let address: String
	
	/// The target server port.
	///
	/// Common ports: 443 (HTTPS), 80 (HTTP), or custom ports based on server configuration.
	public let port: Int
	
	/// List of users for authentication.
	///
	/// In client configurations, typically contains a single user. The server will verify
	/// the user's UUID against its configured user list.
	///
	/// - Note: Each user's UUID must match a valid UUID on the server side.
	public let users: [User]
	
	// MARK: - Initializers
	
	/// Creates a VLESS configuration from a parsed link.
	///
	/// Parses a VLESS URL (e.g., `vless://uuid@host:port?params...`) and extracts
	/// the server address, port, and user configuration.
	///
	/// - Parameter parser: Link parser containing connection details
	/// - Throws: `TunnelXError` if required parameters are missing or invalid
	///
	/// - SeeAlso: `LinkParser` for supported URL formats
	init(_ parser: LinkParser) throws {
		self.address = parser.host
		self.port = parser.port
		self.users = [try User(parser)]
	}
	
	/// Creates a VLESS configuration with explicit parameters.
	///
	/// Use this initializer when building configurations programmatically rather than
	/// parsing from a URL.
	///
	/// - Parameters:
	///   - address: Target server address (domain or IP)
	///   - port: Target server port
	///   - users: Array of user configurations (typically one for client configs)
	///
	/// - Precondition: `address` must not be empty and `port` must be valid (1-65535)
	public init(address: String, port: Int, users: [User]) {
		self.address = address
		self.port = port
		self.users = users
	}
}
