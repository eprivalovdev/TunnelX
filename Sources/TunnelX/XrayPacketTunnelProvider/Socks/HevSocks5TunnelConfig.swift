import Foundation

public enum HevSocks5TunnelConfig: Codable {
	case file(path: URL)
	case string(content: String)
}
