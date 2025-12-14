import Foundation

struct TunnelStorage {
	
	enum Key: String {
		case tunnelAddress = "tunnelx.xray.tunnel.storage.tunnel.address"
		case dns = "tunnelx.xray.tunnel.storage.dns.settings.for.xray"
		case route = "tunnelx.xray.tunnel.storage.route.settings.for.xray"
		case sniffing = "tunnelx.xray.tunnel.storage.inbound.sniffing.for.xray"
		case logLevel = "tunnelx.xray.tunnel.storage.logLevel.for.xray"
		case dnsLogEnabled = "tunnelx.xray.tunnel.storage.dns.log.enabled.for.xray"
		case geoDataConfig = "tunnelx.xray.tunnel.storage.geodata.config.for.xray"
	}
	
	@XrayStored(Key.tunnelAddress.rawValue, default: "::1")
	var tunnelAddress: String
	
	@XrayStoredCodable(Key.dns.rawValue, default: StorageDNS.default)
	var dns: StorageDNS
	
	@XrayStoredCodable(Key.route.rawValue, default: StorageRoute.default)
	var route: StorageRoute
	
	@XrayStoredCodable(Key.sniffing.rawValue, default: StorageSniffing.default)
	var sniffing: StorageSniffing
	
	@XrayStored(Key.logLevel.rawValue, default: LogLevel.debug.rawValue)
	var logLevel: String
	
	@XrayStored(Key.dnsLogEnabled.rawValue, default: false)
	var dnsLogEnabled: Bool
	
	@XrayStoredCodable(Key.geoDataConfig.rawValue, default: GeoDataManager.Configuration.default)
	var geoDataConfig: GeoDataManager.Configuration
}
