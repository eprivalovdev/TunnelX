import Foundation

// MARK: - TCP Settings

/// Configuration for TCP transport protocol.
///
/// TCP (Transmission Control Protocol) is the standard, reliable stream-based transport
/// protocol. It provides ordered, error-checked delivery of data with flow control.
///
/// ## Characteristics
/// - **Reliability**: Guaranteed delivery with error checking
/// - **Ordering**: Packets arrive in order
/// - **Flow Control**: Automatic bandwidth management
/// - **Widespread**: Supported by all networks
///
/// ## Use Cases
/// - Direct connections in low-censorship environments
/// - High-throughput applications
/// - When reliability is more important than latency
///
/// ## HTTP Obfuscation
/// TCP settings support optional HTTP header obfuscation to make traffic
/// appear as HTTP requests, improving compatibility with certain firewalls.
///
/// - SeeAlso: [Xray TCP Configuration](https://xtls.github.io/en/config/transport#tcpobject)
public struct TCPSettings: Encodable {
	
	// MARK: - Nested Types
	
	/// HTTP header obfuscation type for TCP connections.
	///
	/// Determines whether to add HTTP headers to disguise TCP traffic.
	public enum HeaderType: String, Encodable, CaseIterable {
		/// No HTTP header obfuscation (standard TCP).
		///
		/// Use this for:
		/// - Direct connections
		/// - Maximum performance
		/// - No firewall concerns
		case none = "none"
		
		// Future: HTTP obfuscation can be added here
		// case http = "http"
	}
	
	/// HTTP header configuration for TCP obfuscation.
	///
	/// Currently supports only "none" type, but structure allows for
	/// future HTTP obfuscation features.
	public struct Header: Encodable {
		/// The type of header obfuscation to apply.
		public var type: HeaderType
		
		/// Creates a TCP header configuration.
		///
		/// - Parameter type: Header obfuscation type (default: `.none`)
		public init(type: HeaderType = .none) {
			self.type = type
		}
	}
	
	// MARK: - Properties
	
	/// Header configuration for this TCP connection.
	///
	/// Defines whether and how to apply HTTP header obfuscation.
	public let header: Header
	
	// MARK: - Initializers
	
	/// Creates a TCP transport configuration.
	///
	/// By default, creates a standard TCP connection without HTTP obfuscation.
	///
	/// ## Example
	/// ```swift
	/// // Standard TCP
	/// let tcp = TCPSettings()
	///
	/// // TCP with explicit header configuration
	/// let tcpWithHeader = TCPSettings(header: TCPSettings.Header(type: .none))
	/// ```
	public init(header: Header = Header()) {
		self.header = header
	}
}
