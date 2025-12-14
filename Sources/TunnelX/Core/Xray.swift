import Foundation

/// One-time environment setup for Xray tunnel system.
///
/// Configure once at app launch with your App Group identifier:
/// ```swift
/// Xray.configure(appGroup: "group.com.example.app")
/// ```
///
/// This automatically:
/// - Configures shared storage
/// - Downloads GeoIP/GeoSite data
/// - Detects working loopback address
@MainActor
public enum Xray {
	
	// MARK: - Configuration State
	
	private static var isConfigured = false
	private static var configuredAppGroup: String?
	
	// MARK: - Public API
	
	/// Configure Xray environment. Call once at app launch.
	///
	/// Example:
	/// ```swift
	/// @main
	/// struct MyApp: App {
	///     init() {
	///         Xray.configure(appGroup: "group.com.example.app")
	///     }
	///
	///     var body: some Scene { ... }
	/// }
	/// ```
	///
	/// - Parameter appGroup: App Group identifier for shared storage
	public static func configure(appGroup: String) {
		guard !isConfigured else {
			print("⚠️ Xray.configure() called multiple times. Ignoring.")
			return
		}
		
		isConfigured = true
		configuredAppGroup = appGroup
		
		// 1. Configure settings storage
		XrayTunnelSettings.configure(appGroup: appGroup)
		
		// 2. Launch background tasks
		Task.detached {
			// Download GeoData files
			let geoDataManager = GeoDataManager(appGroup: appGroup)
			try? await geoDataManager.downloadAndSaveGeoFiles()
		}
		
		Task { @MainActor in
			// Detect working loopback address
			let resolver = LoopbackAddressResolver()
			resolver.resolve { address in
				XrayTunnelSettings.setTunnelAddress(address)
			}
		}
	}
}

