import Foundation
import Testing
@testable import TunnelX

// MARK: - Test Helpers

/// Extracts a strongly-typed dictionary from Any.
///
/// - Parameter value: The value to cast to dictionary
/// - Returns: Dictionary with string keys
/// - Throws: `TestError.typeMismatch` if value is not a dictionary
func requireDictionary(_ value: Any?) throws -> [String: Any] {
	guard let dict = value as? [String: Any] else {
		throw TestError.typeMismatch(
			expected: "Dictionary",
			actual: String(describing: type(of: value))
		)
	}
	return dict
}

/// Extracts a strongly-typed array from Any.
///
/// - Parameter value: The value to cast to array
/// - Returns: Array of Any
/// - Throws: `TestError.typeMismatch` if value is not an array
func requireArray(_ value: Any?) throws -> [Any] {
	guard let array = value as? [Any] else {
		throw TestError.typeMismatch(
			expected: "Array",
			actual: String(describing: type(of: value))
		)
	}
	return array
}

/// Parses JSON data into a dictionary.
///
/// - Parameter data: JSON data to parse
/// - Returns: Dictionary representation
/// - Throws: JSONSerialization or type casting errors
func parseJSON(_ data: Data) throws -> [String: Any] {
	let object = try JSONSerialization.jsonObject(with: data)
	return try requireDictionary(object)
}

/// Configures test environment with temporary app group.
///
/// Creates a temporary directory for test isolation and configures
/// DefaultsSuite to use it instead of real app group container.
///
/// - Returns: URL of the temporary test directory
@discardableResult
func setupTestEnvironment() -> URL {
	let testDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
		.appendingPathComponent("tunnelx-tests-\(UUID().uuidString)", isDirectory: true)
	
	try? FileManager.default.createDirectory(
		at: testDirectory,
		withIntermediateDirectories: true
	)
	
	DefaultsSuite.configureForTesting(
		appGroup: "test.tunnelx.group",
		containerURL: testDirectory
	)
	
	return testDirectory
}

/// Cleans up test directory.
///
/// - Parameter url: Directory URL to remove
func cleanupTestEnvironment(_ url: URL) {
	try? FileManager.default.removeItem(at: url)
}

// MARK: - Test Errors

/// Errors that can occur during test execution.
enum TestError: Error, CustomStringConvertible {
	/// Expected a specific type but got another
	case typeMismatch(expected: String, actual: String)
	
	/// Expected value not found in collection
	case valueNotFound(String)
	
	/// General assertion failure
	case assertionFailure(String)
	
	var description: String {
		switch self {
		case .typeMismatch(let expected, let actual):
			return "Type mismatch: expected \(expected) but got \(actual)"
		case .valueNotFound(let description):
			return "Value not found: \(description)"
		case .assertionFailure(let message):
			return "Assertion failed: \(message)"
		}
	}
}

// MARK: - JSON Assertion Helpers

/// Asserts that a JSON path exists and returns the value.
///
/// - Parameters:
///   - json: Root JSON dictionary
///   - path: Dot-separated path (e.g., "routing.rules[0].inboundTag")
/// - Returns: Value at the specified path
/// - Throws: `TestError` if path is invalid
func jsonValue(at path: String, in json: [String: Any]) throws -> Any {
	let components = path.split(separator: ".").map(String.init)
	var current: Any = json
	
	for component in components {
		if component.hasSuffix("]") {
			// Array access: "rules[0]"
			let parts = component.split(separator: "[")
			guard parts.count == 2,
				  let key = parts.first,
				  let indexStr = parts.last?.dropLast(),
				  let index = Int(indexStr) else {
				throw TestError.assertionFailure("Invalid array syntax: \(component)")
			}
			
			let dict = try requireDictionary(current)
			let array = try requireArray(dict[String(key)])
			
			guard index < array.count else {
				throw TestError.valueNotFound("Index \(index) out of bounds in \(key)")
			}
			
			current = array[index]
		} else {
			// Dictionary access
			let dict = try requireDictionary(current)
			
			guard let value = dict[component] else {
				throw TestError.valueNotFound("Key '\(component)' in path '\(path)'")
			}
			
			current = value
		}
	}
	
	return current
}

// MARK: - Mock Implementations

/// Mock implementation of XrayCoreRunner for testing.
///
/// Tracks all method calls and provides controllable behavior.
final class MockXrayCoreRunner: XrayCoreRunner {
	
	// MARK: - Call Tracking
	
	private(set) var runCallCount = 0
	private(set) var stopCallCount = 0
	private(set) var lastRunDataDir: String?
	private(set) var lastRunConfigPath: String?
	
	// MARK: - Behavior Control
	
	var shouldThrowOnRun: Error?
	var shouldThrowOnStop: Error?
	var runDelay: TimeInterval = 0
	
	// MARK: - XrayCoreRunner
	
	func run(dataDir: String, configPath: String) throws {
		runCallCount += 1
		lastRunDataDir = dataDir
		lastRunConfigPath = configPath
		
		if runDelay > 0 {
			Thread.sleep(forTimeInterval: runDelay)
		}
		
		if let error = shouldThrowOnRun {
			throw error
		}
	}
	
	func stop() throws {
		stopCallCount += 1
		
		if let error = shouldThrowOnStop {
			throw error
		}
	}
	
	// MARK: - Reset
	
	func reset() {
		runCallCount = 0
		stopCallCount = 0
		lastRunDataDir = nil
		lastRunConfigPath = nil
		shouldThrowOnRun = nil
		shouldThrowOnStop = nil
		runDelay = 0
	}
}

/// Mock implementation of SocksTunnelRunner for testing.
///
/// Tracks all method calls and provides controllable behavior.
final class MockSocksTunnelRunner: SocksTunnelRunner {
	
	// MARK: - Call Tracking
	
	private(set) var runCallCount = 0
	private(set) var quitCallCount = 0
	private(set) var statsCallCount = 0
	private(set) var lastConfig: HevSocks5TunnelConfig?
	private(set) var lastCompletionResult: Int32?
	
	// MARK: - Behavior Control
	
	var completionResult: Int32 = 0
	var statsResult = (txPackets: 100, txBytes: 1024, rxPackets: 200, rxBytes: 2048)
	var runDelay: TimeInterval = 0
	
	// MARK: - SocksTunnelRunner
	
	func run(config: HevSocks5TunnelConfig, completion: ((Int32) -> Void)?) {
		runCallCount += 1
		lastConfig = config
		
		if runDelay > 0 {
			Thread.sleep(forTimeInterval: runDelay)
		}
		
		lastCompletionResult = completionResult
		completion?(completionResult)
	}
	
	func quit() {
		quitCallCount += 1
	}
	
	func stats() -> (txPackets: Int, txBytes: Int, rxPackets: Int, rxBytes: Int) {
		statsCallCount += 1
		return statsResult
	}
	
	// MARK: - Reset
	
	func reset() {
		runCallCount = 0
		quitCallCount = 0
		statsCallCount = 0
		lastConfig = nil
		lastCompletionResult = nil
		completionResult = 0
		statsResult = (100, 1024, 200, 2048)
		runDelay = 0
	}
}

// MARK: - Test Data Builders

/// Builder for creating test VLESS URLs with various configurations.
///
/// Uses a fluent API pattern for easy test URL construction.
///
/// # Example
/// ```swift
/// let url = VlessURLBuilder()
///     .withHost("example.com")
///     .withPort(443)
///     .withPath("/websocket")
///     .withSNI("example.com")
///     .build()
/// ```
struct VlessURLBuilder {
	var userID: String
	var host: String
	var port: Int
	var networkType: String
	var security: String
	var fragment: String?
	
	private var parameters: [String: String]
	
	init(
		userID: String = "550e8400-e29b-41d4-a716-446655440000",
		host: String = "example.com",
		port: Int = 443,
		networkType: String = "ws",
		security: String = "tls",
		fragment: String? = nil,
		parameters: [String: String] = [:]
	) {
		self.userID = userID
		self.host = host
		self.port = port
		self.networkType = networkType
		self.security = security
		self.fragment = fragment
		
		// Initialize parameters with defaults
		var params = parameters
		params["type"] = networkType
		params["security"] = security
		self.parameters = params
	}
	
	/// Adds a custom parameter to the URL.
	func withParameter(_ key: String, value: String) -> VlessURLBuilder {
		var copy = self
		copy.parameters[key] = value
		return copy
	}
	
	/// Sets the WebSocket or HTTP path.
	func withPath(_ path: String) -> VlessURLBuilder {
		withParameter("path", value: path)
	}
	
	/// Sets the Server Name Indication for TLS.
	func withSNI(_ sni: String) -> VlessURLBuilder {
		withParameter("sni", value: sni)
	}
	
	/// Sets the TLS/Reality fingerprint.
	func withFingerprint(_ fp: String) -> VlessURLBuilder {
		withParameter("fp", value: fp)
	}
	
	/// Sets the flow control type.
	func withFlow(_ flow: String) -> VlessURLBuilder {
		withParameter("flow", value: flow)
	}
	
	/// Sets the connection name (URL fragment).
	func withFragment(_ fragment: String) -> VlessURLBuilder {
		var copy = self
		copy.fragment = fragment
		return copy
	}
	
	/// Sets the host address.
	func withHost(_ host: String) -> VlessURLBuilder {
		var copy = self
		copy.host = host
		return copy
	}
	
	/// Sets the port number.
	func withPort(_ port: Int) -> VlessURLBuilder {
		var copy = self
		copy.port = port
		return copy
	}
	
	/// Sets the network type.
	func withNetworkType(_ networkType: String) -> VlessURLBuilder {
		var copy = self
		copy.networkType = networkType
		copy.parameters["type"] = networkType
		return copy
	}
	
	/// Sets the security type.
	func withSecurity(_ security: String) -> VlessURLBuilder {
		var copy = self
		copy.security = security
		copy.parameters["security"] = security
		return copy
	}
	
	/// Builds the final VLESS URL string.
	func build() -> String {
		// Ensure type and security are set
		var params = parameters
		params["type"] = networkType
		params["security"] = security
		
		let queryString = params
			.sorted { $0.key < $1.key }  // Consistent ordering
			.map { "\($0.key)=\($0.value)" }
			.joined(separator: "&")
		
		var url = "vless://\(userID)@\(host):\(port)?\(queryString)"
		
		if let fragment = fragment {
			url += "#\(fragment)"
		}
		
		return url
	}
}

/// Builder for creating realistic Xray configuration test data.
///
/// Provides pre-configured URLs for common test scenarios.
struct XrayConfigTestDataBuilder {
	
	/// Builds a VLESS URL with Reality security over TCP.
	///
	/// Configuration includes:
	/// - Protocol: VLESS
	/// - Network: TCP
	/// - Security: Reality
	/// - Host: 100.100.100.100 (IPv4)
	/// - Port: 8443
	/// - Flow: xtls-rprx-vision
	static func buildVlessRealityURL() -> String {
		VlessURLBuilder()
			.withHost("100.100.100.100")
			.withPort(8443)
			.withNetworkType("tcp")
			.withSecurity("reality")
			.withParameter("pbk", value: "Zl2s1CzlnDwT_1izA5RG2oCOdMO37KEXMZ2QrPe7U2w")
			.withParameter("encryption", value: "none")
			.withSNI("google.com")
			.withFingerprint("random")
			.withParameter("sid", value: "1d206afc18")
			.withFlow("xtls-rprx-vision")
			.build()
	}
	
	/// Builds a VLESS URL with TLS security over WebSocket.
	///
	/// Configuration includes:
	/// - Protocol: VLESS
	/// - Network: WebSocket (ws)
	/// - Security: TLS
	/// - Host: example.com
	/// - Port: 443
	/// - Path: /websocket
	/// - Connection name: MyConnection
	static func buildVlessWebSocketURL() -> String {
		VlessURLBuilder()
			.withNetworkType("ws")
			.withSecurity("tls")
			.withPath("/websocket")
			.withSNI("example.com")
			.withFragment("MyConnection")
			.build()
	}
	
	/// Builds a VLESS URL with TLS security over gRPC.
	///
	/// Configuration includes:
	/// - Protocol: VLESS
	/// - Network: gRPC
	/// - Security: TLS
	/// - Host: example.com
	/// - Port: 443
	/// - Service Name: grpcService
	static func buildVlessGRPCURL() -> String {
		VlessURLBuilder()
			.withNetworkType("grpc")
			.withSecurity("tls")
			.withParameter("serviceName", value: "grpcService")
			.withSNI("grpc.example.com")
			.build()
	}
}
