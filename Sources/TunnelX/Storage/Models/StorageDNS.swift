import Foundation

public struct StorageDNS: Codable {
	public var disableFallback: Bool
	public var id: String
	public var disableCache: Bool
	public var queryStrategy: DNS.QueryStrategy
	public var disableFallbackIfMatch: Bool
	public var servers: [DNS.Server]
	
	public init(
		disableFallback: Bool,
		id: String,
		disableCache: Bool,
		queryStrategy: DNS.QueryStrategy,
		disableFallbackIfMatch: Bool,
		servers: [DNS.Server]
	) {
		self.disableFallback = disableFallback
		self.id = id
		self.disableCache = disableCache
		self.queryStrategy = queryStrategy
		self.disableFallbackIfMatch = disableFallbackIfMatch
		self.servers = servers
	}
	
	public static var `default`: StorageDNS {
		StorageDNS(
			disableFallback: false,
			id: UUID().uuidString,
			disableCache: false,
			queryStrategy: .useIPv4,
			disableFallbackIfMatch: false,
			servers: [
				DNS.Server(address: "1.1.1.1"),
				DNS.Server(address: "8.8.8.8")
			]
		)
	}
}

extension StorageDNS {
	func toDNS() -> DNS {
		DNS(
			disableFallback: disableFallback,
			id: id,
			disableCache: disableCache,
			queryStrategy: queryStrategy,
			disableFallbackIfMatch: disableFallbackIfMatch,
			servers: servers.map { .server($0) }
		)
	}
}
