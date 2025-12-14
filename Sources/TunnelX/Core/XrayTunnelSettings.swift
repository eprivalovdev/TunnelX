import Foundation

/// Global settings for Xray tunnel configuration.
/// Must be configured with App Group before use.
///
/// `XrayTunnelSettings` provides a centralized API for managing persistent
/// tunnel configuration settings across your app and Network Extension.
///
/// # Configuration
/// Before using any methods, configure the App Group:
/// ```swift
/// XrayTunnelSettings.configure(appGroup: "group.com.example.app")
/// ```
///
/// # Example Usage
/// ```swift
/// // Set DNS configuration
/// XrayTunnelSettings.setDNS(
///     StorageDNS(
///         servers: ["8.8.8.8", "1.1.1.1"],
///         strategy: .ipIfNonMatch
///     )
/// )
///
/// // Get current log level
/// let level = XrayTunnelSettings.logLevel
///
/// // Reset to defaults
/// XrayTunnelSettings.resetToDefaults()
/// ```
public struct XrayTunnelSettings {
	
	private static let preferences = TunnelPreferences()
	
	// MARK: - Configuration
	
	/// Configure the App Group for shared data storage.
	/// Must be called before using any other methods.
	/// - Parameter appGroup: The App Group identifier
	public static func configure(appGroup: String) {
		DefaultsSuite.configure(appGroup: appGroup)
	}
	
	// MARK: - Getters
	
	/// The tunnel listening address (default: "::1")
	public static var tunnelAddress: String {
		preferences.tunnelAddress
	}
	
	/// DNS configuration settings
	public static var dns: StorageDNS {
		preferences.dns
	}
	
	/// Routing configuration settings
	public static var route: StorageRoute {
		preferences.route
	}
	
	/// Inbound sniffing configuration
	public static var sniffing: StorageSniffing {
		preferences.sniffing
	}
	
	/// Logging level (default: .debug)
	public static var logLevel: LogLevel {
		preferences.logLevel
	}
	
	/// Whether DNS logging is enabled (default: false)
	public static var dnsLogEnabled: Bool {
		preferences.dnsLogEnabled
	}
	
	/// GeoData source configuration (default: Loyalsoldier)
	public static var geoDataConfig: GeoDataManager.Configuration {
		preferences.geoDataConfig
	}
	
	// MARK: - Setters
	
	/// Sets the tunnel listening address
	/// - Parameter address: IP address to bind tunnel to
	public static func setTunnelAddress(_ address: String) {
		preferences.tunnelAddress = address
	}
	
	/// Sets DNS configuration
	/// - Parameter dns: DNS configuration to apply
	public static func setDNS(_ dns: StorageDNS) {
		preferences.dns = dns
	}
	
	/// Sets routing configuration
	/// - Parameter route: Routing configuration to apply
	public static func setRoute(_ route: StorageRoute) {
		preferences.route = route
	}
	
	/// Sets inbound sniffing configuration
	/// - Parameter sniffing: Sniffing configuration to apply
	public static func setSniffing(_ sniffing: StorageSniffing) {
		preferences.sniffing = sniffing
	}
	
	/// Sets logging level
	/// - Parameter level: Log level to apply
	public static func setLogLevel(_ level: LogLevel) {
		preferences.logLevel = level
	}
	
	/// Sets DNS logging state
	/// - Parameter enabled: Whether to enable DNS logging
	public static func setDNSLogEnabled(_ enabled: Bool) {
		preferences.dnsLogEnabled = enabled
	}
	
	/// Sets GeoData source configuration
	/// - Parameter config: GeoData configuration to apply
	public static func setGeoDataConfig(_ config: GeoDataManager.Configuration) {
		preferences.geoDataConfig = config
	}
	
	// MARK: - Reset
	
	/// Resets all settings to their default values
	public static func resetToDefaults() {
		preferences.resetToDefaults()
	}
	
	// Prevent instantiation - this is a static-only API
	private init() {}
}
