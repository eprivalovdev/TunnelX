import Foundation

// MARK: - Network Type

/// Transport protocol types supported by Xray for data transmission.
///
/// Xray supports multiple transport protocols, each with different characteristics
/// regarding performance, obfuscation, and compatibility with network environments.
///
/// ## Protocol Categories
///
/// ### Stream-Based Protocols
/// - **TCP**: Standard TCP connections, reliable and widely supported
/// - **KCP**: UDP-based protocol with lower latency, better for lossy networks
/// - **WebSocket**: HTTP-based upgrade protocol, good for firewall traversal
/// - **HTTP/2**: Multiplexed HTTP connections with header compression
/// - **gRPC**: Modern RPC protocol built on HTTP/2
///
/// ### Experimental Protocols
/// - **QUIC**: UDP-based with built-in encryption and multiplexing
/// - **XHTTP/SplitHTTP**: Xray's custom HTTP-based protocols
/// - **HTTPUpgrade**: WebSocket alternative using HTTP Upgrade mechanism
///
/// ### Special Purpose
/// - **DomainSocket**: Unix domain sockets for local IPC
/// - **Raw**: Minimal overhead TCP variant
///
/// ## Selection Guide
///
/// - **Best Performance**: TCP, KCP
/// - **Best Obfuscation**: WebSocket, HTTP/2, gRPC
/// - **Firewall Traversal**: WebSocket, HTTP/2, HTTPUpgrade
/// - **Low Latency**: KCP, QUIC
/// - **High Throughput**: TCP, gRPC
///
/// - SeeAlso: [Xray Transport Protocols](https://xtls.github.io/en/config/transport)
public enum NetworkType: String, Encodable, CaseIterable {
	
	// MARK: - Stream Protocols
	
	/// Standard TCP protocol.
	///
	/// - **Pros**: Reliable, widely supported, good performance
	/// - **Cons**: No built-in obfuscation
	/// - **Use Case**: Direct connections, low-censorship environments
	case tcp = "tcp"
	
	/// mKCP (UDP-based KCP protocol).
	///
	/// - **Pros**: Lower latency than TCP, better for packet loss
	/// - **Cons**: Higher bandwidth usage, may be blocked by some firewalls
	/// - **Use Case**: Gaming, real-time applications, lossy networks
	case kcp = "kcp"
	
	/// WebSocket protocol.
	///
	/// - **Pros**: Excellent obfuscation, bypasses most firewalls
	/// - **Cons**: Slight overhead compared to raw TCP
	/// - **Use Case**: Highly censored networks, corporate firewalls
	case ws = "ws"
	
	/// HTTP/2 protocol (also known as h2).
	///
	/// - **Pros**: Multiplexing, header compression, looks like HTTPS traffic
	/// - **Cons**: Requires TLS, slightly higher overhead
	/// - **Use Case**: High-performance obfuscation, CDN compatibility
	case http = "http"
	
	/// gRPC protocol (built on HTTP/2).
	///
	/// - **Pros**: Modern RPC protocol, strong obfuscation, CDN-friendly
	/// - **Cons**: Requires TLS, learning curve
	/// - **Use Case**: Maximum obfuscation, cloud environments
	case grpc = "grpc"
	
	// MARK: - Experimental Protocols
	
	/// QUIC protocol (Quick UDP Internet Connections).
	///
	/// - **Pros**: Built-in encryption, 0-RTT, multiplexing
	/// - **Cons**: Experimental, may be detected and blocked
	/// - **Use Case**: Modern networks, low-latency requirements
	case quic = "quic"
	
	/// XHTTP protocol (Xray's custom HTTP protocol).
	///
	/// - **Pros**: Optimized for Xray, good obfuscation
	/// - **Cons**: Xray-specific, less tested
	/// - **Use Case**: Xray-to-Xray connections
	case xhttp = "xhttp"
	
	/// SplitHTTP protocol (variant of XHTTP).
	///
	/// - **Pros**: Better compatibility with certain CDNs
	/// - **Cons**: Xray-specific
	/// - **Use Case**: CDN environments
	case splithttp = "splithttp"
	
	/// HTTP Upgrade protocol (WebSocket alternative).
	///
	/// - **Pros**: Similar to WebSocket but different handshake
	/// - **Cons**: Newer, less tested
	/// - **Use Case**: WebSocket alternative for specific scenarios
	case httpupgrade = "httpupgrade"
	
	// MARK: - Special Purpose
	
	/// Unix domain socket for local inter-process communication.
	///
	/// - **Pros**: Very fast for local connections
	/// - **Cons**: Only works locally, not over network
	/// - **Use Case**: Local service chaining, process communication
	case domainsocket = "domainsocket"
	
	/// Raw TCP with minimal overhead.
	///
	/// - **Pros**: Minimal protocol overhead
	/// - **Cons**: Limited features
	/// - **Use Case**: Maximum performance in trusted environments
	case raw = "raw"
}
