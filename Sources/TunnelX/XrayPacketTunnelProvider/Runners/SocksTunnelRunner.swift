import Foundation

/// Protocol abstraction to control SOCKS5 tunnel.
protocol SocksTunnelRunner {
	func run(config: HevSocks5TunnelConfig, completion: ((Int32) -> Void)?)
	func quit()
	func stats() -> (txPackets: Int, txBytes: Int, rxPackets: Int, rxBytes: Int)
}

struct DefaultSocksTunnelRunner: SocksTunnelRunner {
	func run(config: HevSocks5TunnelConfig, completion: ((Int32) -> Void)?) {
		SwiftHevSocks5Tunnel.run(config: config, completion: completion)
	}
	
	func quit() {
		SwiftHevSocks5Tunnel.quit()
	}
	
	func stats() -> (txPackets: Int, txBytes: Int, rxPackets: Int, rxBytes: Int) {
		SwiftHevSocks5Tunnel.stats()
	}
}

