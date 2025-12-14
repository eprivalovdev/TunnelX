import Foundation

public final class XrayConfiguration: Encodable, Parsable {
	
	public private(set) var log = Log()
	public private(set) var routing: Route?
	public private(set) var inbounds: [Inbound] = []
	public private(set) var outbounds: [Outbound] = []
	public private(set) var dns: DNS?
	
	// MARK: - Initializers
	
	/// Creates an empty Xray configuration
	public init() {}
	
	/// Creates an Xray configuration from a parsed link
	/// - Parameter parser: The link parser containing connection details
	/// - Throws: TunnelXError if configuration building fails
	public init(_ parser: LinkParser) throws {
		self.outbounds = [try Outbound(parser)]
	}
	
	// MARK: - Builder Methods
	
	/// Sets the logging configuration
	/// - Parameter log: Log configuration
	/// - Returns: Self for method chaining
	@discardableResult
	public func log(_ log: Log) -> Self {
		self.log = log
		return self
	}
	
	/// Sets the routing configuration
	/// - Parameter route: Route configuration
	/// - Returns: Self for method chaining
	@discardableResult
	public func routing(_ route: Route) -> Self {
		routing = route
		return self
	}
	
	/// Adds an inbound connection
	/// - Parameter inbound: Inbound configuration to add
	/// - Returns: Self for method chaining
	@discardableResult
	public func inbound(_ inbound: Inbound) -> Self {
		inbounds.append(inbound)
		return self
	}
	
	/// Adds an outbound connection
	/// - Parameter outbound: Outbound configuration to add
	/// - Returns: Self for method chaining
	@discardableResult
	public func outbound(_ outbound: Outbound) -> Self {
		outbounds.append(outbound)
		return self
	}
	
	/// Sets the DNS configuration
	/// - Parameter dns: DNS configuration
	/// - Returns: Self for method chaining
	@discardableResult
	public func dns(_ dns: DNS) -> Self {
		self.dns = dns
		return self
	}
	
	// MARK: - JSON Export
	
	/// Converts the configuration to a JSON string
	/// - Returns: Pretty-printed JSON string representation
	/// - Throws: TunnelXError if encoding fails
	public func toJSON() throws -> String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
		
		let data = try encoder.encode(self)
		
		guard let jsonString = String(data: data, encoding: .utf8) else {
			throw TunnelXError.dataToStringConversionFailed
		}
		
		return jsonString
	}
}
