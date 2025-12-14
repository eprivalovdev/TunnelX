import Foundation

public struct StorageRoute: Codable {
	public var domainStrategy: Route.DomainStrategy
	public var domainMatcher: Route.DomainMatcher?
	public var rules: [Route.Rule]
	public var balancers: [Route.Balancer]?
	
	public init(
		domainStrategy: Route.DomainStrategy,
		domainMatcher: Route.DomainMatcher? = nil,
		rules: [Route.Rule],
		balancers: [Route.Balancer]? = nil
	) {
		self.domainStrategy = domainStrategy
		self.domainMatcher = domainMatcher
		self.rules = rules
		self.balancers = balancers
	}
	
	public static var `default`: StorageRoute {
		StorageRoute(
			domainStrategy: .asIs,
			domainMatcher: nil,
			rules: [
				.init(
					inboundTag: ["socks"],
					outboundTag: .proxy
				)
			],
			balancers: nil
		)
	}
}

extension StorageRoute {
	func toRoute() -> Route {
		Route(
			domainStrategy: domainStrategy,
			domainMatcher: domainMatcher,
			rules: rules,
			balancers: balancers
		)
	}
}
