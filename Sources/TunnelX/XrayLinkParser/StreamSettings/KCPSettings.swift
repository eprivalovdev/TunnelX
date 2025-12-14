import Foundation

// MARK: - mKCP Settings

/// mKCP (UDP-based) transport configuration.
///
/// KCP is designed for low-latency scenarios at the cost of bandwidth.
/// Good for real-time applications and lossy networks.
///
/// - SeeAlso: [Xray mKCP Configuration](https://xtls.github.io/en/config/transport#kcpobject)
public struct KCPSettings: Encodable, Parsable {
	
	// MARK: - Nested Types
	
	/// Header obfuscation type.
	public enum HeaderType: String, Encodable, CaseIterable {
		case none = "none"
		case srtp = "srtp"
		case utp = "utp"
		case wechat_video = "wechat-video"
		case dtls = "dtls"
		case wireguard = "wireguard"
	}
	
	/// Header configuration for packet obfuscation.
	public struct Header: Encodable {
		public var type: HeaderType
		
		public init(type: HeaderType = .none) {
			self.type = type
		}
	}
	
	// MARK: - Properties
	
	/// Maximum Transmission Unit (default: 1350 bytes).
	public var mtu: Int?
	
	/// Transmission Time Interval in ms (default: 50ms).
	public var tti: Int?
	
	/// Uplink capacity in MB/s (default: 5).
	public var uplinkCapacity: Int?
	
	/// Downlink capacity in MB/s (default: 20).
	public var downlinkCapacity: Int?
	
	/// Enable congestion control.
	public var congestion: Bool?
	
	/// Read buffer size in MB (default: 2).
	public var readBufferSize: Int?
	
	/// Write buffer size in MB (default: 2).
	public var writeBufferSize: Int?
	
	/// Header obfuscation configuration.
	public var header: Header
	
	/// Seed for packet obfuscation (optional).
	public var seed: String?
	
	// MARK: - Initializers
	
	/// Creates KCP settings from parsed link.
	public init(_ parser: LinkParser) throws {
		guard parser.network == .kcp else {
			throw TunnelXError.invalidNetworkType(expected: "kcp", actual: parser.network.rawValue)
		}
		
		let params = parser.parametersMap
		func intParam(_ key: String) -> Int? { params[key].flatMap { Int($0) } }
		
		self.mtu = intParam("mtu")
		self.tti = intParam("tti")
		self.uplinkCapacity = intParam("uplinkCapacity")
		self.downlinkCapacity = intParam("downlinkCapacity")
		
		if let c = params["congestion"] {
			self.congestion = (c as NSString).boolValue
		}
		
		self.readBufferSize = intParam("readBufferSize")
		self.writeBufferSize = intParam("writeBufferSize")
		
		if let ht = params["headerType"], let t = HeaderType(rawValue: ht) {
			self.header = Header(type: t)
		} else {
			self.header = Header()
		}
		
		self.seed = params["seed"]
	}
	
	/// Creates KCP settings with explicit parameters.
	public init(
		mtu: Int? = nil,
		tti: Int? = nil,
		uplinkCapacity: Int? = nil,
		downlinkCapacity: Int? = nil,
		congestion: Bool? = nil,
		readBufferSize: Int? = nil,
		writeBufferSize: Int? = nil,
		header: Header = Header(),
		seed: String? = nil
	) {
		self.mtu = mtu
		self.tti = tti
		self.uplinkCapacity = uplinkCapacity
		self.downlinkCapacity = downlinkCapacity
		self.congestion = congestion
		self.readBufferSize = readBufferSize
		self.writeBufferSize = writeBufferSize
		self.header = header
		self.seed = seed
	}
}
