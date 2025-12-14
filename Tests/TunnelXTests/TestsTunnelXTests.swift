import Foundation
import Testing
@testable import TunnelX

// MARK: - TunnelX Test Suite
//
// This file serves as the main entry point for TunnelX tests.
// Tests are organized into separate files by component:
//
// - TestHelpers.swift - Common test utilities and mocks
// - LinkParserTests.swift - URL parsing and validation
// - XrayConfigBuilderTests.swift - Configuration generation
// - XrayTunnelControllerTests.swift - Service lifecycle
// - HostResolverServiceTests.swift - DNS resolution
//
// Run tests with: swift test
// Or use Xcode's Test Navigator (Cmd+6)

/// Integration tests for complete TunnelX workflows.
///
/// These tests verify end-to-end functionality by combining
/// multiple components together.
@Suite("TunnelX Integration Tests")
struct TunnelXIntegrationTests {
	
	init() {
		setupTestEnvironment()
	}
	
	// MARK: - Complete Workflow Tests
	
	@Test("Complete workflow: URL to running tunnel")
	func completeWorkflowURLToRunningTunnel() throws {
		// 1. Parse URL
		let url = XrayConfigTestDataBuilder.buildVlessRealityURL()
		let parser = try LinkParser(urlString: url)
		
		#expect(parser.host == "100.100.100.100")
		#expect(parser.port == 8443)
		
		// 2. Build configuration
		let builder = XrayConfigBuilder()
		let writer = XrayConfigurationWriter()
		
		let configData = try builder.build(from: .url(url))
		let json = try parseJSON(configData)
		
		#expect(json["inbounds"] != nil)
		#expect(json["outbounds"] != nil)
		
		// 3. Save configuration
		let configURL = try writer.writeConfiguration(configData, fileName: "config.json")
		#expect(FileManager.default.fileExists(atPath: configURL.path))
		
		// 4. Create SOCKS5 config
		let socksConfigURL = try writer.writeSocks5Config(
			address: XrayTunnelSettings.tunnelAddress,
			port: 10808
		)
		#expect(FileManager.default.fileExists(atPath: socksConfigURL.path))
		
		// 5. Create tunnel controller with mocks
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		// 6. Start tunnel
		let tunnelConfig = TunnelConfig(
			xrayConfigPath: configURL.path,
			socks5Config: .file(path: socksConfigURL),
			geoDataDir: DefaultsSuite.containerURL.path
		)
		
		try controller.startTunnelServices(configs: tunnelConfig)
		
		// 7. Verify everything started
		#expect(mockXray.runCallCount == 1)
		#expect(mockSocks.runCallCount == 1)
		
		// 8. Stop tunnel
		controller.stopTunnelServices()
		
		#expect(mockXray.stopCallCount == 1)
		#expect(mockSocks.quitCallCount == 1)
	}
	
	@Test("Handle invalid URL gracefully in full workflow")
	func handleInvalidURLGracefullyInFullWorkflow() {
		let invalidURL = "not-a-valid-url"
		
		// Should fail at parsing stage
		#expect(throws: TunnelXError.self) {
			try LinkParser(urlString: invalidURL)
		}
		
		// Should also fail at builder stage
		let builder = XrayConfigBuilder()
		#expect(throws: TunnelXError.self) {
			try builder.build(from: .url(invalidURL))
		}
	}
	
	@Test("Multiple connections can be parsed and configured")
	func multipleConnectionsCanBeParsedAndConfigured() throws {
		let urls = [
			XrayConfigTestDataBuilder.buildVlessRealityURL(),
			XrayConfigTestDataBuilder.buildVlessWebSocketURL(),
			XrayConfigTestDataBuilder.buildVlessGRPCURL()
		]
		
		let builder = XrayConfigBuilder()
		let writer = XrayConfigurationWriter()
		
		for (index, url) in urls.enumerated() {
			// Parse each URL
			let parser = try LinkParser(urlString: url)
			#expect(parser.outboundProtocol == .vless)
			
			// Build config for each
			let data = try builder.build(from: .url(url))
			let json = try parseJSON(data)
			
			#expect(json["outbounds"] != nil)
			
			// Save with unique name
			let fileURL = try writer.writeConfiguration(
				data,
				fileName: "config-\(index).json"
			)
			
			#expect(FileManager.default.fileExists(atPath: fileURL.path))
		}
	}
	
	// MARK: - Configuration Compatibility Tests
	
	@Test("Generated config is valid JSON")
	func generatedConfigIsValidJSON() throws {
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessWebSocketURL()
		
		let data = try builder.build(from: .url(url))
		
		// Should be parseable as JSON
		let json = try JSONSerialization.jsonObject(with: data)
		#expect(json is [String: Any])
		
		// Should be re-serializable
		let reserializedData = try JSONSerialization.data(withJSONObject: json)
		#expect(reserializedData.count > 0)
	}
	
	@Test("Config includes all required Xray fields")
	func configIncludesAllRequiredXrayFields() throws {
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessRealityURL()
		
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		// Required top-level fields
		let requiredFields = ["log", "routing", "inbounds", "outbounds", "dns"]
		
		for field in requiredFields {
			#expect(json[field] != nil, "Missing required field: \(field)")
		}
	}
	
	// MARK: - Error Recovery Tests
	
	@Test("Recover from failed service start")
	func recoverFromFailedServiceStart() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		
		enum TestError: Error {
			case startFailed
		}
		
		// First attempt fails
		mockXray.shouldThrowOnRun = TestError.startFailed
		
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		let config = TunnelConfig(
			xrayConfigPath: "/tmp/config.json",
			socks5Config: .string(content: "test"),
			geoDataDir: "/tmp"
		)
		
		// First attempt should fail
		#expect(throws: TestError.self) {
			try controller.startTunnelServices(configs: config)
		}
		
		// Reset error condition
		mockXray.shouldThrowOnRun = nil
		mockXray.reset()
		mockSocks.reset()
		
		// Second attempt should succeed
		try controller.startTunnelServices(configs: config)
		
		#expect(mockXray.runCallCount == 1)
		#expect(mockSocks.runCallCount == 1)
	}
	
	// MARK: - Stress Tests
	
	@Test("Handle rapid start-stop cycles")
	func handleRapidStartStopCycles() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		let config = TunnelConfig(
			xrayConfigPath: "/tmp/config.json",
			socks5Config: .string(content: "test"),
			geoDataDir: "/tmp"
		)
		
		// Perform 10 rapid cycles
		for _ in 0..<10 {
			try controller.startTunnelServices(configs: config)
			controller.stopTunnelServices()
		}
		
		// Should have completed all cycles
		#expect(mockXray.runCallCount == 10)
		#expect(mockXray.stopCallCount == 10)
		#expect(mockSocks.runCallCount == 10)
		#expect(mockSocks.quitCallCount == 10)
	}
}

// MARK: - Test Configuration Validation

/// Validates test environment setup and prerequisites.
@Suite("Test Environment Validation")
struct TestEnvironmentValidationTests {
	
	@Test("Test directory is writable")
	func testDirectoryIsWritable() throws {
		let testDir = setupTestEnvironment()
		defer { cleanupTestEnvironment(testDir) }
		
		let testFile = testDir.appendingPathComponent("test.txt")
		let testData = "test".data(using: .utf8)!
		
		try testData.write(to: testFile)
		
		#expect(FileManager.default.fileExists(atPath: testFile.path))
		
		// Cleanup
		try? FileManager.default.removeItem(at: testFile)
	}
	
	@Test("DefaultsSuite is properly configured for testing")
	func defaultsSuiteIsProperlyConfiguredForTesting() {
		let testDir = setupTestEnvironment()
		defer { cleanupTestEnvironment(testDir) }
		
		let containerURL = DefaultsSuite.containerURL
		
		#expect(containerURL.path.contains("tunnelx-tests"))
		#expect(FileManager.default.fileExists(atPath: containerURL.path))
	}
	
	@Test("Mock runners behave correctly")
	func mockRunnersBehaveCorrectly() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		
		// Initial state
		#expect(mockXray.runCallCount == 0)
		#expect(mockSocks.runCallCount == 0)
		
		// After operations
		try mockXray.run(dataDir: "/tmp", configPath: "/tmp/config.json")
		mockSocks.run(config: .string(content: "test"), completion: nil)
		
		#expect(mockXray.runCallCount == 1)
		#expect(mockSocks.runCallCount == 1)
		
		// After reset
		mockXray.reset()
		mockSocks.reset()
		
		#expect(mockXray.runCallCount == 0)
		#expect(mockSocks.runCallCount == 0)
	}
}

// MARK: - Performance Benchmarks

/// Performance benchmarks for critical operations.
@Suite("Performance Benchmarks")
struct PerformanceBenchmarkTests {
	
	@Test("URL parsing performance")
	func urlParsingPerformance() throws {
		let url = XrayConfigTestDataBuilder.buildVlessRealityURL()
		
		let startTime = Date()
		
		for _ in 0..<1000 {
			_ = try LinkParser(urlString: url)
		}
		
		let duration = Date().timeIntervalSince(startTime)
		
		// Should parse 1000 URLs in under 1 second
		#expect(duration < 1.0)
	}
	
	@Test("Configuration building performance")
	func configurationBuildingPerformance() throws {
		setupTestEnvironment()
		
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessWebSocketURL()
		
		let startTime = Date()
		
		for _ in 0..<100 {
			_ = try builder.build(from: .url(url))
		}
		
		let duration = Date().timeIntervalSince(startTime)
		
		// Should build 100 configs in under 2 seconds
		#expect(duration < 2.0)
	}
}
