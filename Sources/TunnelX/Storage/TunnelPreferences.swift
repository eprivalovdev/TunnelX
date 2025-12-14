import Foundation

/// Thin wrapper around persisted tunnel settings stored in UserDefaults.
final class TunnelPreferences {
	private var storage = TunnelStorage()
	
	var tunnelAddress: String {
		get { storage.tunnelAddress }
		set { storage.tunnelAddress = newValue }
	}
	
	var dns: StorageDNS {
		get { storage.dns }
		set { storage.dns = newValue }
	}
	
	var route: StorageRoute {
		get { storage.route }
		set { storage.route = newValue }
	}
	
	var sniffing: StorageSniffing {
		get { storage.sniffing }
		set { storage.sniffing = newValue }
	}
	
	var logLevel: LogLevel {
		get { LogLevel(rawValue: storage.logLevel) ?? .debug }
		set { storage.logLevel = newValue.rawValue }
	}
	
	var dnsLogEnabled: Bool {
		get { storage.dnsLogEnabled }
		set { storage.dnsLogEnabled = newValue }
	}
	
	var geoDataConfig: GeoDataManager.Configuration {
		get { storage.geoDataConfig }
		set { storage.geoDataConfig = newValue }
	}
	
	func resetToDefaults() {
		storage.tunnelAddress = "::1"
		storage.dns = .default
		storage.route = .default
		storage.sniffing = .default
		storage.logLevel = LogLevel.debug.rawValue
		storage.dnsLogEnabled = false
		storage.geoDataConfig = .default
	}
}

