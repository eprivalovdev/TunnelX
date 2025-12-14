import Foundation

// MARK: - Inbound Protocol

/// Inbound connection protocol types supported by Xray.
///
/// Defines which protocol is used to accept incoming connections from clients.
///
/// - SeeAlso: [Xray Inbound Configuration](https://xtls.github.io/en/config/inbounds)
public enum InboundProtocol: String, Encodable, CaseIterable {
	/// SOCKS5 proxy protocol.
	///
	/// Standard SOCKS5 with authentication support.
	case socks = "socks"
	
	/// HTTP proxy protocol.
	///
	/// Standard HTTP/HTTPS proxy.
	case http = "http"
	
	/// VMess protocol (for server-side).
	///
	/// Accept VMess connections from clients.
	case vmess = "vmess"
	
	/// VLESS protocol (for server-side).
	///
	/// Accept VLESS connections from clients.
	case vless = "vless"
	
	/// Trojan protocol (for server-side).
	///
	/// Accept Trojan connections from clients.
	case trojan = "trojan"
	
	/// Shadowsocks protocol (for server-side).
	///
	/// Accept Shadowsocks connections from clients.
	case shadowsocks = "shadowsocks"
	
	/// Dokodemo-door (transparent proxy).
	///
	/// Accept any TCP/UDP connection and redirect to specified destination.
	/// Used for transparent proxying and port forwarding.
	case dokodemo = "dokodemo-door"
}
