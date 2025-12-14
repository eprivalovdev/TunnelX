import Foundation

public enum OutboundProtocol: String, Encodable {
	case vless
	case vmess
	case trojan
	case shadowsocks
	case wireguard
	case freedom
	case blackhole
}
