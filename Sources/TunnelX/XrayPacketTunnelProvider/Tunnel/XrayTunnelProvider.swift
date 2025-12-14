import NetworkExtension

/// Entry points used inside PacketTunnelProvider to launch/stop services.
///
/// This class provides static methods for managing the Xray tunnel lifecycle
/// within a Network Extension's PacketTunnelProvider.
///
/// # Usage
/// Call `startTunnel(options:)` from your PacketTunnelProvider's
/// `startTunnel(options:)` method, and `stopTunnel()` from `stopTunnel(with:)`.
public final class XrayTunnelProvider {
	private static let controller = XrayTunnelController()
	
	/// Starts the Xray tunnel services
	/// - Parameter options: Options dictionary containing tunnel configuration
	/// - Throws: TunnelXError if configuration is invalid or tunnel start fails
	public static func startTunnel(options: [String: NSObject]?) async throws {
		guard
			let configData = options?["tunnelConfig"] as? Data,
			let config = try? JSONDecoder().decode(TunnelConfig.self, from: configData)
		else {
			throw TunnelXError.tunnelConfigurationDecodeFailed
		}
		
		do {
			try controller.startTunnelServices(configs: config)
		} catch let error as TunnelXError {
			stopTunnel()
			throw error
		} catch {
			stopTunnel()
			throw TunnelXError.tunnelStartFailed(underlying: error)
		}
	}
	
	/// Stops the Xray tunnel services
	public static func stopTunnel() {
		controller.stopTunnelServices()
	}
	
	// Prevent instantiation
	private init() {}
}
