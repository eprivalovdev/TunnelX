import Foundation
import Network

/// A utility class that detects which loopback address (IPv4 or IPv6) is reachable for connecting to the local proxy.
///
/// `LoopbackAddressResolver` attempts to establish TCP connections to both `127.0.0.1` (IPv4) and `::1` (IPv6)
/// on the specified port to determine which address responds first. This is useful for environments where
/// IPv6 may be disabled or IPv4 is preferred.
///
/// ## Usage
///
/// ```swift
/// let resolver = LoopbackAddressResolver()
/// await resolver.resolve(port: 10808) { address in
///     print("Detected loopback address: \(address)")
///     // Use this address to connect to SOCKS5 proxy
/// }
/// ```
///
/// - Note: This class must be used from the main actor context.
/// - Important: The resolver will return `::1` (IPv6) as a fallback if neither address responds within the timeout period.
@MainActor
public final class LoopbackAddressResolver {
	private var didFinish = false
	
	/// Resolves the best available loopback address by attempting connections to both IPv4 and IPv6 addresses.
	///
	/// This method creates concurrent TCP connections to both `127.0.0.1` and `::1` on the specified port.
	/// The first address that successfully connects will be returned via the completion handler.
	/// If neither address responds within the timeout period (1.5 seconds), `::1` is returned as a fallback.
	///
	/// - Parameters:
	///   - port: The port number to test connectivity on. Defaults to `10808` (common SOCKS5 port).
	///   - completion: A closure that receives the resolved loopback address (either `"127.0.0.1"` or `"::1"`).
	///
	/// - Note: The completion handler is always called exactly once, even if multiple connections succeed.
	/// - Warning: This method performs network operations and should not be called repeatedly in tight loops.
	///
	/// ## Example
	///
	/// ```swift
	/// let resolver = LoopbackAddressResolver()
	/// await resolver.resolve(port: 10808) { address in
	///     XrayTunnelSettings.setTunnelAddress(address)
	///     print("Using loopback address: \(address)")
	/// }
	/// ```
	public func resolve(port: UInt16 = 10808, completion: @escaping (String) -> Void) {
		let queue = DispatchQueue(label: "xtunnel.loopback.detect.network")
		let testTimeout: TimeInterval = 1.5
		let hosts = ["127.0.0.1", "::1"]
		let nwPort = NWEndpoint.Port(rawValue: port)!
		
		func finish(_ address: String) {
			guard !didFinish else { return }
			didFinish = true
			completion(address)
		}
		
		for host in hosts {
			let connection = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .tcp)
			connection.stateUpdateHandler = { state in
				switch state {
				case .ready:
					Task { @MainActor in finish(host) }
					connection.cancel()
				case .failed:
					connection.cancel()
				default:
					break
				}
			}
			connection.start(queue: queue)
		}
		
		queue.asyncAfter(deadline: .now() + testTimeout) {
			Task { @MainActor in finish("::1") }
		}
	}
}
