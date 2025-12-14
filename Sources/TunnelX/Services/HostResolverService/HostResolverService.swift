import Foundation
import Darwin

/// Resolves hostnames to IP addresses and walks arbitrary JSON-like structures to replace host fields.
final class HostResolverService {
	private let addressKey = "address"
	
	func resolveHost(_ host: String) -> String? {
		var hints = addrinfo(
			ai_flags: AI_PASSIVE,
			ai_family: AF_UNSPEC,
			ai_socktype: SOCK_STREAM,
			ai_protocol: 0,
			ai_addrlen: 0,
			ai_canonname: nil,
			ai_addr: nil,
			ai_next: nil
		)
		
		var result: UnsafeMutablePointer<addrinfo>? = nil
		guard getaddrinfo(host, nil, &hints, &result) == 0, let res = result else {
			return nil
		}
		
		var resolvedIP: String?
		var info: UnsafeMutablePointer<addrinfo>? = res
		while let addr = info {
			if let sa = addr.pointee.ai_addr {
				var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
				if getnameinfo(
					sa,
					socklen_t(addr.pointee.ai_addrlen),
					&hostBuffer,
					socklen_t(hostBuffer.count),
					nil,
					0,
					NI_NUMERICHOST
				) == 0 {
					resolvedIP = String(cString: hostBuffer)
					break
				}
			}
			info = addr.pointee.ai_next
		}
		
		freeaddrinfo(res)
		
		return resolvedIP
	}
	
	func resolveAddressesWithLogging(in object: Any, changes: inout [(host: String, ip: String)]) -> Any {
		if var dict = object as? [String: Any] {
			for (key, value) in dict {
				if key == addressKey, let host = value as? String {
					if isIPAddress(host) {
						continue
					}
					
					if let ip = resolveHost(host) {
						dict[key] = ip
						changes.append((host: host, ip: ip))
					}
				} else {
					dict[key] = resolveAddressesWithLogging(in: value, changes: &changes)
				}
			}
			return dict
		} else if var arr = object as? [Any] {
			for i in 0..<arr.count {
				arr[i] = resolveAddressesWithLogging(in: arr[i], changes: &changes)
			}
			return arr
		} else {
			return object
		}
	}
	
	private func isIPAddress(_ value: String) -> Bool {
		value.range(of: #"^\d{1,3}(\.\d{1,3}){3}$"#, options: .regularExpression) != nil || value.contains(":")
	}
}

