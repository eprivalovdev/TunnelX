import Foundation

// MARK: - Security Type

/// Transport layer security protocols supported by Xray.
///
/// Security types define how data is encrypted and authenticated during transmission.
/// Xray supports multiple security protocols, each with different characteristics
/// regarding security, performance, and obfuscation capabilities.
///
/// ## Security Options
///
/// - **None**: No transport encryption (protocol-level encryption only)
/// - **TLS**: Standard Transport Layer Security with certificates
/// - **Reality**: Xray's anti-detection TLS implementation
///
/// ## Selection Guide
///
/// - **Trusted Networks**: Use `none` for maximum performance
/// - **Standard Security**: Use `tls` for general-purpose encryption
/// - **High Censorship**: Use `reality` for maximum anti-detection
///
/// - Important: Some protocols (like Trojan) require `tls` to function correctly.
///              VLESS can work with any security type.
///
/// - SeeAlso:
///   - [Xray TLS Configuration](https://xtls.github.io/en/config/transport#tlsobject)
///   - [Xray Reality Configuration](https://xtls.github.io/en/config/transport#realityobject)
public enum SecurityType: String, Encodable, CaseIterable {
	
	/// No transport layer encryption.
	///
	/// Data is transmitted without additional encryption at the transport layer.
	/// Protocol-level encryption (like VMess) may still be applied.
	///
	/// ## Use Cases
	/// - Trusted local networks
	/// - Protocols with built-in encryption (VMess, Shadowsocks)
	/// - Maximum performance requirements
	///
	/// ## Security Considerations
	/// - ⚠️ Traffic is **not encrypted** at transport layer
	/// - ⚠️ Vulnerable to **man-in-the-middle** attacks
	/// - ⚠️ Protocol fingerprinting is **easier**
	///
	/// - Warning: Only use in trusted environments or with protocols
	///            that provide their own encryption.
	case none = "none"
	
	/// Standard TLS (Transport Layer Security).
	///
	/// Uses industry-standard TLS protocol with X.509 certificates for encryption
	/// and authentication. Compatible with standard TLS clients and servers.
	///
	/// ## Use Cases
	/// - General-purpose secure connections
	/// - Compatibility with standard infrastructure
	/// - CDN and reverse proxy scenarios
	///
	/// ## Features
	/// - ✅ Strong encryption (TLS 1.2+, TLS 1.3)
	/// - ✅ Certificate-based authentication
	/// - ✅ ALPN negotiation (HTTP/2, HTTP/1.1)
	/// - ✅ SNI (Server Name Indication)
	/// - ✅ Wide compatibility
	///
	/// ## Requirements
	/// - Valid TLS certificate on server
	/// - Matching SNI configuration
	/// - Optional: Custom CA for self-signed certificates
	///
	/// - Note: TLS 1.3 is preferred for better security and performance.
	case tls = "tls"
	
	/// Reality protocol (Xray's anti-detection TLS).
	///
	/// Reality is Xray's proprietary TLS implementation designed to be
	/// indistinguishable from legitimate HTTPS traffic. It provides maximum
	/// anti-detection capabilities while maintaining strong security.
	///
	/// ## Use Cases
	/// - High-censorship environments
	/// - Active probing resistance
	/// - Traffic analysis evasion
	///
	/// ## Features
	/// - ✅ **Perfect Mimicry**: Indistinguishable from real websites
	/// - ✅ **Anti-Probing**: Responds like legitimate servers to probes
	/// - ✅ **No Certificate**: Uses public key authentication
	/// - ✅ **SNI Camouflage**: Can mimic any HTTPS website
	/// - ✅ **Spider X**: Random destination websites for camouflage
	///
	/// ## Configuration Requirements
	/// - Public key (pbk) from server
	/// - Server name (SNI) of a real HTTPS website
	/// - Optional: Short ID (sid) for routing
	/// - Optional: Spider X (spx) for destination URLs
	///
	/// ## How It Works
	/// 1. Client initiates TLS handshake mimicking access to `serverName`
	/// 2. Server validates client's public key
	/// 3. If invalid, server behaves exactly like the real `serverName` website
	/// 4. If valid, server establishes encrypted tunnel
	///
	/// ## Security
	/// - Uses Curve25519 for key exchange
	/// - AES-256-GCM for data encryption
	/// - Perfect forward secrecy
	/// - Resistance to replay attacks
	///
	/// - Important: Choose a popular, stable HTTPS website for `serverName`.
	///              The server must be able to access this website to mimic it.
	///
	/// - SeeAlso: [Reality Protocol Documentation](https://github.com/XTLS/Reality)
	case reality = "reality"
}
