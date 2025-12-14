import Foundation

public struct TunnelConfig: Codable {
	public let xrayConfigPath: String
	public let socks5Config: HevSocks5TunnelConfig
	public let geoDataDir: String
	
	public init(xrayConfigPath: String, socks5Config: HevSocks5TunnelConfig, geoDataDir: String) {
		self.xrayConfigPath = xrayConfigPath
		self.socks5Config = socks5Config
		self.geoDataDir = geoDataDir
	}
}
