import Foundation

// MARK: - WireGuard Outbound Configuration

/// Configuration object for WireGuard protocol outbound connections.
///
/// WireGuard is a modern, high-performance VPN protocol that uses state-of-the-art
/// cryptography. It's designed to be simpler, faster, and more secure than traditional
/// VPN protocols like IPsec and OpenVPN.
///
/// ## Key Features
/// - **High Performance**: Minimal protocol overhead with modern cryptography
/// - **Strong Security**: ChaCha20-Poly1305, Curve25519, BLAKE2s
/// - **Stealth**: Silent when not in use, minimal handshake packets
/// - **Cross-Platform**: Wide support across operating systems
///
/// ## Cryptographic Design
/// - **Key Exchange**: Curve25519 elliptic curve Diffie-Hellman
/// - **Encryption**: ChaCha20-Poly1305 authenticated encryption
/// - **Hashing**: BLAKE2s
/// - **Handshake**: Noise protocol framework (1-RTT)
///
/// ## Example Usage
/// ```swift
/// let wgConfig = WireGuardOutboundConfigurationObject(
///     secretKey: "cGVlciBzZWNyZXQga2V5IGluIGJhc2U2NA==",
///     address: ["10.0.0.2/32"],
///     peers: [
///         WireGuardOutboundConfigurationObject.Peer(
///             publicKey: "c2VydmVyIHB1YmxpYyBrZXkgaW4gYmFzZTY0",
///             endpoint: "example.com:51820",
///             allowedIPs: ["0.0.0.0/0"]
///         )
///     ]
/// )
/// ```
///
/// - Important: WireGuard requires proper key management. Never share your private key.
///              Generate keys using: `wg genkey` and `wg pubkey`.
///
/// - SeeAlso:
///   - [Xray WireGuard Documentation](https://xtls.github.io/en/config/outbounds/wireguard)
///   - [WireGuard Official Site](https://www.wireguard.com/)
public struct WireGuardOutboundConfigurationObject: Encodable, Parsable {
	
	// MARK: - Nested Types
	
	/// WireGuard peer configuration.
	///
	/// A peer represents a remote WireGuard endpoint (typically the VPN server).
	/// Each peer has a public key, endpoint address, and routing configuration.
	public struct Peer: Encodable {
		
		// MARK: - Properties
		
		/// Public key of the peer (base64-encoded).
		///
		/// This is the server's public key, generated from its private key.
		/// Must be exactly 32 bytes (44 characters in base64).
		///
		/// - Important: Verify the public key matches the server to prevent MITM attacks.
		public let publicKey: String
		
		/// Endpoint address of the peer (format: `host:port`).
		///
		/// Specifies where to send WireGuard packets. Can be a domain name or IP address.
		/// Standard WireGuard port is 51820, but any UDP port can be used.
		///
		/// Example: `"vpn.example.com:51820"` or `"198.51.100.1:51820"`
		public let endpoint: String?
		
		/// Pre-shared key for additional layer of symmetric encryption (base64-encoded).
		///
		/// Optional pre-shared key that adds an additional layer of symmetric-key
		/// cryptography for post-quantum resistance. Must be 32 bytes (44 chars base64).
		///
		/// - Note: Both client and server must have the same PSK configured.
		public let preSharedKey: String?
		
		/// Reserved bytes for anti-detection (3 bytes).
		///
		/// Some WireGuard implementations use reserved bytes in the packet header
		/// to evade traffic analysis. Each byte should be 0-255.
		///
		/// - Note: Server must be configured with matching reserved bytes.
		public let reserved: [UInt8]?
		
		/// IP address ranges allowed for routing through this peer.
		///
		/// Specifies which destination IPs should be routed through this WireGuard tunnel.
		/// Use `["0.0.0.0/0", "::/0"]` to route all traffic through the VPN.
		///
		/// Examples:
		/// - All traffic: `["0.0.0.0/0", "::/0"]`
		/// - Specific subnet: `["10.0.0.0/8"]`
		/// - Multiple ranges: `["192.168.1.0/24", "10.0.0.0/8"]`
		public let allowedIPs: [String]?
		
		/// Persistent keepalive interval in seconds.
		///
		/// Sends keepalive packets to maintain NAT mappings and firewall rules.
		/// Useful when behind NAT or firewall. Set to 0 to disable.
		///
		/// Recommended: 25 seconds for most NAT scenarios.
		public let keepAlive: Int?
		
		// MARK: - Initializers
		
		/// Creates a WireGuard peer configuration.
		///
		/// - Parameters:
		///   - publicKey: Peer's public key (base64, 44 chars)
		///   - endpoint: Peer's endpoint address (host:port) (default: nil)
		///   - preSharedKey: Optional pre-shared key for post-quantum security (default: nil)
		///   - reserved: Reserved bytes for anti-detection [3 bytes] (default: nil)
		///   - allowedIPs: IP ranges to route through this peer (default: nil)
		///   - keepAlive: Keepalive interval in seconds (default: nil)
		public init(
			publicKey: String,
			endpoint: String? = nil,
			preSharedKey: String? = nil,
			reserved: [UInt8]? = nil,
			allowedIPs: [String]? = nil,
			keepAlive: Int? = nil
		) {
			self.publicKey = publicKey
			self.endpoint = endpoint
			self.preSharedKey = preSharedKey
			self.reserved = reserved
			self.allowedIPs = allowedIPs
			self.keepAlive = keepAlive
		}
		
		// MARK: - Encodable
		
		private enum CodingKeys: String, CodingKey {
			case publicKey
			case endpoint
			case preSharedKey
			case reserved
			case allowedIPs
			case keepAlive
		}
	}
	
	// MARK: - Properties
	
	/// Client's private key (base64-encoded, 32 bytes).
	///
	/// This is your WireGuard private key. Must be kept secret and never shared.
	/// Generate using: `wg genkey`
	///
	/// - Important: Never commit private keys to version control or share them.
	public let secretKey: String
	
	/// Local IP addresses assigned to the WireGuard interface.
	///
	/// These are the virtual IP addresses assigned to your WireGuard interface.
	/// Should match the addresses allocated by the VPN server.
	///
	/// Examples:
	/// - IPv4 only: `["10.0.0.2/32"]`
	/// - IPv4 and IPv6: `["10.0.0.2/32", "fd00::2/128"]`
	public let address: [String]?
	
	/// Maximum transmission unit (MTU) for the WireGuard interface.
	///
	/// The maximum packet size for WireGuard packets. WireGuard has 80 bytes of overhead,
	/// so typical values are:
	/// - Standard Ethernet (1500): MTU = 1420
	/// - PPPoE (1492): MTU = 1412
	/// - IPv6 (1280): MTU = 1200
	///
	/// - Note: If nil, system will auto-detect appropriate MTU.
	public let mtu: Int?
	
	/// List of WireGuard peers (typically one for client configs).
	///
	/// Each peer represents a remote WireGuard endpoint. Client configurations
	/// typically have one peer (the VPN server).
	public let peers: [Peer]
	
	/// Domain resolution strategy for peer endpoints.
	///
	/// Controls how domain names in peer endpoints are resolved:
	/// - `"AsIs"`: Use system DNS (default)
	/// - `"UseIP"`: Force IPv4/IPv6
	/// - `"UseIPv4"`: Force IPv4 only
	/// - `"UseIPv6"`: Force IPv6 only
	public let domainStrategy: String?
	
	/// Number of worker threads for WireGuard processing.
	///
	/// Controls parallelism for encryption/decryption operations.
	/// Higher values may improve throughput on multi-core systems.
	///
	/// - Note: If nil, uses system default (typically CPU core count).
	public let workers: Int?
	
	/// Reserved bytes for anti-detection (3 bytes).
	///
	/// Default reserved bytes applied to all peers unless overridden per-peer.
	/// Used for traffic obfuscation in some deployments.
	public let reserved: [UInt8]?
	
	// MARK: - Initializers
	
	/// Creates a WireGuard configuration with explicit parameters.
	///
	/// - Parameters:
	///   - secretKey: Client's private key (base64, 44 chars)
	///   - address: Local IP addresses for the interface (default: nil)
	///   - mtu: Maximum transmission unit (default: nil for auto-detect)
	///   - peers: Array of peer configurations
	///   - domainStrategy: DNS resolution strategy (default: nil)
	///   - workers: Number of worker threads (default: nil for auto)
	///   - reserved: Default reserved bytes (default: nil)
	public init(
		secretKey: String,
		address: [String]? = nil,
		mtu: Int? = nil,
		peers: [Peer],
		domainStrategy: String? = nil,
		workers: Int? = nil,
		reserved: [UInt8]? = nil
	) {
		self.secretKey = secretKey
		self.address = address
		self.mtu = mtu
		self.peers = peers
		self.domainStrategy = domainStrategy
		self.workers = workers
		self.reserved = reserved
	}
	
	// MARK: - Parsable
	
	/// Error types for WireGuard parsing operations.
	public enum WireGuardParsingError: Error, LocalizedError {
		case unsupported(String)
		
		public var errorDescription: String? {
			switch self {
			case .unsupported(let message):
				return "WireGuard parsing not supported: \(message)"
			}
		}
	}
	
	/// Creates a WireGuard configuration from a parsed link.
	///
	/// - Parameter parser: Link parser containing connection details
	/// - Throws: `WireGuardParsingError.unsupported` as WireGuard URL parsing is not yet implemented
	///
	/// - Note: WireGuard doesn't have a standardized URI format. Most implementations
	///         use configuration files. URL parsing support may be added in the future.
	public init(_ parser: LinkParser) throws {
		throw WireGuardParsingError.unsupported("WireGuard link parsing not implemented. Use configuration file or manual initialization.")
	}
	
	// MARK: - Encodable
	
	private enum CodingKeys: String, CodingKey {
		case secretKey
		case address
		case mtu
		case peers
		case domainStrategy
		case workers
		case reserved
	}
}
