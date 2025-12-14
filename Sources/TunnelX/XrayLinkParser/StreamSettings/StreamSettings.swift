import Foundation

// MARK: - Stream Settings

/// Transport and security configuration for Xray connections.
///
/// `StreamSettings` combines network transport protocols (TCP, WebSocket, gRPC, etc.)
/// with security protocols (TLS, Reality) to define how data is transmitted between
/// the client and server.
///
/// ## Architecture
///
/// Stream settings consist of two main components:
/// 1. **Network Transport**: How data packets are transmitted (TCP, WS, gRPC, etc.)
/// 2. **Security Layer**: How data is encrypted and authenticated (TLS, Reality)
///
/// ```
/// ┌─────────────────────────────────────┐
/// │         Application Data            │
/// ├─────────────────────────────────────┤
/// │    Security Layer (TLS/Reality)     │  ← Encryption & Authentication
/// ├─────────────────────────────────────┤
/// │  Transport Protocol (TCP/WS/gRPC)   │  ← How data is sent
/// ├─────────────────────────────────────┤
/// │          Network Layer              │
/// └─────────────────────────────────────┘
/// ```
///
/// ## Security Protocols
///
/// - **None**: No transport encryption (fast, but insecure)
/// - **TLS**: Standard TLS encryption (secure, widely compatible)
/// - **Reality**: Anti-detection TLS (secure, undetectable)
///
/// ## Example Configurations
///
/// ### WebSocket + TLS (Common)
/// ```swift
/// let settings = try StreamSettings(
///     network: .ws,
///     security: .tls,
///     wsSettings: WebSocketSettings(path: "/api/v1/ws"),
///     tlsSettings: TLSSettings(
///         serverName: "example.com",
///         fingerprint: .chrome
///     )
/// )
/// ```
///
/// ### gRPC + Reality (Maximum Stealth)
/// ```swift
/// let settings = try StreamSettings(
///     network: .grpc,
///     security: .reality,
///     grpcSettings: GRPCSettings(serviceName: "GunService"),
///     realitySettings: RealitySettings(
///         serverName: "www.microsoft.com",
///         publicKey: "...",
///         fingerprint: .chrome
///     )
/// )
/// ```
///
/// ### TCP (Maximum Performance)
/// ```swift
/// let settings = StreamSettings(
///     network: .tcp,
///     security: .none,
///     tcpSettings: TCPSettings()
/// )
/// ```
///
/// - SeeAlso:
///   - [Xray Transport Configuration](https://xtls.github.io/en/config/transport)
///   - `NetworkType` for available transport protocols
///   - `SecurityType` for available security protocols
public struct StreamSettings: Encodable, Parsable {
	
	// MARK: - Type Aliases
	
	public typealias Network = NetworkType
	public typealias Security = SecurityType
	public typealias TCP = TCPSettings
	public typealias WS = WebSocketSettings
	public typealias GRPC = GRPCSettings
	public typealias KCP = KCPSettings
	public typealias QUIC = QUICSettings
	public typealias HTTP = HTTPSettings
	public typealias HTTPUpgrade = HTTPUpgradeSettings
	public typealias XHTTP = XHTTPSettings
	public typealias TLS = TLSSettings
	public typealias Reality = RealitySettings
	
	// MARK: - Legacy Raw TCP
	
	/// Raw TCP settings (minimal overhead variant).
	///
	/// - Note: This is a legacy transport type. Consider using standard TCP instead.
	public struct RAW: Encodable {
		public struct Header: Encodable {
			var type: String = "none"
		}
		public let header = Header()
		public init() {}
	}
	
	// MARK: - Properties
	
	/// Network transport protocol to use.
	public let network: Network
	
	/// Security protocol to use for encryption and authentication.
	public let security: Security
	
	/// TCP protocol settings (when `network` is `.tcp`).
	public var tcpSettings: TCP?
	
	/// Raw TCP settings (when `network` is `.raw`).
	public var rawSettings: RAW?
	
	/// WebSocket protocol settings (when `network` is `.ws`).
	public var wsSettings: WS?
	
	/// gRPC protocol settings (when `network` is `.grpc`).
	public var grpcSettings: GRPC?
	
	/// mKCP protocol settings (when `network` is `.kcp`).
	public var kcpSettings: KCP?
	
	/// QUIC protocol settings (when `network` is `.quic`).
	public var quicSettings: QUIC?
	
	/// HTTP/2 protocol settings (when `network` is `.http`).
	public var httpSettings: HTTP?
	
	/// HTTP Upgrade protocol settings (when `network` is `.httpupgrade`).
	public var httpupgradeSettings: HTTPUpgrade?
	
	/// XHTTP protocol settings (when `network` is `.xhttp` or `.splithttp`).
	public var xhttpSettings: XHTTP?
	
	/// Reality security settings (when `security` is `.reality`).
	public var realitySettings: Reality?
	
	/// TLS security settings (when `security` is `.tls`).
	public var tlsSettings: TLS?
	
	// MARK: - Initializers
	
	/// Creates stream settings from a parsed link.
	///
	/// Automatically detects network and security types from the URL and
	/// configures the appropriate protocol settings.
	///
	/// - Parameter parser: Link parser containing stream configuration
	/// - Throws: `TunnelXError` if configuration is invalid or unsupported
	public init(_ parser: LinkParser) throws {
		self.network = parser.network
		self.security = parser.security
		
		// Configure network transport
		switch network {
		case .tcp:
			tcpSettings = TCP()
		case .raw:
			rawSettings = RAW()
		case .ws:
			wsSettings = try WS(parser)
		case .grpc:
			grpcSettings = try GRPC(parser)
		case .kcp:
			kcpSettings = try KCP(parser)
		case .quic:
			quicSettings = try QUIC(parser)
		case .http:
			httpSettings = try HTTP(parser)
		case .httpupgrade:
			httpupgradeSettings = try HTTPUpgrade(parser)
		case .xhttp, .splithttp:
			xhttpSettings = try XHTTP(parser)
		default:
			throw TunnelXError.unsupportedNetworkType(network.rawValue)
		}
		
		// Configure security layer
		switch security {
		case .none:
			break
		case .reality:
			realitySettings = try Reality(parser)
		case .tls:
			tlsSettings = try TLS(parser)
		}
	}
	
	/// Creates stream settings with explicit parameters.
	///
	/// - Parameters:
	///   - network: Network transport protocol
	///   - security: Security protocol
	///   - tcpSettings: TCP configuration (if applicable)
	///   - rawSettings: Raw TCP configuration (if applicable)
	///   - wsSettings: WebSocket configuration (if applicable)
	///   - grpcSettings: gRPC configuration (if applicable)
	///   - kcpSettings: mKCP configuration (if applicable)
	///   - quicSettings: QUIC configuration (if applicable)
	///   - httpSettings: HTTP/2 configuration (if applicable)
	///   - httpupgradeSettings: HTTP Upgrade configuration (if applicable)
	///   - xhttpSettings: XHTTP configuration (if applicable)
	///   - realitySettings: Reality security configuration (if applicable)
	///   - tlsSettings: TLS security configuration (if applicable)
	public init(
		network: Network,
		security: Security,
		tcpSettings: TCP? = nil,
		rawSettings: RAW? = nil,
		wsSettings: WS? = nil,
		grpcSettings: GRPC? = nil,
		kcpSettings: KCP? = nil,
		quicSettings: QUIC? = nil,
		httpSettings: HTTP? = nil,
		httpupgradeSettings: HTTPUpgrade? = nil,
		xhttpSettings: XHTTP? = nil,
		realitySettings: Reality? = nil,
		tlsSettings: TLS? = nil
	) {
		self.network = network
		self.security = security
		self.tcpSettings = tcpSettings
		self.rawSettings = rawSettings
		self.wsSettings = wsSettings
		self.grpcSettings = grpcSettings
		self.kcpSettings = kcpSettings
		self.quicSettings = quicSettings
		self.httpSettings = httpSettings
		self.httpupgradeSettings = httpupgradeSettings
		self.xhttpSettings = xhttpSettings
		self.realitySettings = realitySettings
		self.tlsSettings = tlsSettings
	}
}
