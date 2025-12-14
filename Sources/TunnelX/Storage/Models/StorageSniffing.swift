import Foundation

public struct StorageSniffing: Codable, Hashable {
	public var enabled: Bool
	public var destOverride: [String]
	public var metadataOnly: Bool
	public var routeOnly: Bool
	public var domainsExcluded: [String]
	
	public init(
		enabled: Bool,
		destOverride: [String],
		metadataOnly: Bool,
		routeOnly: Bool,
		domainsExcluded: [String]
	) {
		self.enabled = enabled
		self.destOverride = destOverride
		self.metadataOnly = metadataOnly
		self.routeOnly = routeOnly
		self.domainsExcluded = domainsExcluded
	}
	
	public static let `default` = StorageSniffing(
		enabled: false,
		destOverride: ["http", "tls", "quic"],
		metadataOnly: false,
		routeOnly: true,
		domainsExcluded: []
	)
}
