import Foundation
import HevSocks5Tunnel
import Darwin
import os

/// Concrete runner for Hev Socks5 tunnel.
public final class SwiftHevSocks5Tunnel {
	private static var queue = DispatchQueue(label: "xtunnel.socks5tunnel", qos: .userInitiated)
	private static var isRunning = false
	
	public static func run(config: HevSocks5TunnelConfig, completion: ((Int32) -> Void)? = nil) {
		guard !isRunning, let tunFD = getTunFD() else { return }
		
		isRunning = true
		
		queue.async {
			var result: Int32 = -1
			
			switch config {
			case .file(let path):
				result = hev_socks5_tunnel_main(path.path, tunFD)
			case .string(let content):
				content.withCString { cStr in
					result = hev_socks5_tunnel_main(cStr, tunFD)
				}
			}
			
			isRunning = false
			
			completion?(result)
		}
	}
	
	public static func quit() {
		guard isRunning else { return }
		
		hev_socks5_tunnel_quit()
		
		isRunning = false
	}
	
	public static func stats() -> (txPackets: Int, txBytes: Int, rxPackets: Int, rxBytes: Int) {
		var txPackets = 0, txBytes = 0, rxPackets = 0, rxBytes = 0
		
		hev_socks5_tunnel_stats(&txPackets, &txBytes, &rxPackets, &rxBytes)
		
		return (txPackets, txBytes, rxPackets, rxBytes)
	}
	
	private static func getTunFD() -> Int32? {
		var buf = [CChar](repeating: 0, count: Int(IFNAMSIZ))
		let utunPrefix = "utun".utf8CString.dropLast()
		
		return (0...1024).first { (_ fd: Int32) -> Bool in
			var len = socklen_t(buf.count)
			return getsockopt(fd, 2, 2, &buf, &len) == 0 && buf.starts(with: utunPrefix)
		}
	}
}
