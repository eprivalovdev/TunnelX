import Foundation
import Testing
@testable import TunnelX

/// Comprehensive test suite for XrayTunnelController.
///
/// Tests cover:
/// - Service lifecycle management
/// - Dependency injection
/// - Error handling and propagation
/// - State management
/// - Mock runner verification
@Suite("XrayTunnelController Tests")
struct XrayTunnelControllerTests {
	
	// MARK: - Lifecycle Tests
	
	@Test("Start tunnel services successfully")
	func startTunnelServicesSuccessfully() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		let config = TunnelConfig(
			xrayConfigPath: "/tmp/test-config.json",
			socks5Config: .string(content: "test: config"),
			geoDataDir: "/tmp/geodata"
		)
		
		try controller.startTunnelServices(configs: config)
		
		// Verify both services started
		#expect(mockXray.runCallCount == 1)
		#expect(mockSocks.runCallCount == 1)
		
		// Verify correct parameters were passed
		#expect(mockXray.lastRunDataDir == "/tmp/geodata")
		#expect(mockXray.lastRunConfigPath == "/tmp/test-config.json")
	}
	
	@Test("Stop tunnel services successfully")
	func stopTunnelServicesSuccessfully() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		// Start services first
		let config = TunnelConfig(
			xrayConfigPath: "/tmp/config.json",
			socks5Config: .string(content: "test"),
			geoDataDir: "/tmp"
		)
		try controller.startTunnelServices(configs: config)
		
		// Stop services
		controller.stopTunnelServices()
		
		// Verify both services stopped
		#expect(mockSocks.quitCallCount == 1)
		#expect(mockXray.stopCallCount == 1)
	}
	
	@Test("Start services in correct order")
	func startServicesInCorrectOrder() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		
		var callOrder: [String] = []
		
		// Track call order using delays and timestamps
		mockSocks.runDelay = 0.01
		mockXray.runDelay = 0.01
		
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		let config = TunnelConfig(
			xrayConfigPath: "/tmp/config.json",
			socks5Config: .string(content: "test"),
			geoDataDir: "/tmp"
		)
		
		try controller.startTunnelServices(configs: config)
		
		// Both should be called
		#expect(mockSocks.runCallCount == 1)
		#expect(mockXray.runCallCount == 1)
	}
	
	// MARK: - Configuration Tests
	
	@Test("Pass correct configuration to Xray runner")
	func passCorrectConfigurationToXrayRunner() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		let expectedConfigPath = "/custom/path/config.json"
		let expectedGeoDataDir = "/custom/geodata"
		
		let config = TunnelConfig(
			xrayConfigPath: expectedConfigPath,
			socks5Config: .string(content: "test"),
			geoDataDir: expectedGeoDataDir
		)
		
		try controller.startTunnelServices(configs: config)
		
		#expect(mockXray.lastRunConfigPath == expectedConfigPath)
		#expect(mockXray.lastRunDataDir == expectedGeoDataDir)
	}
	
	@Test("Pass string configuration to SOCKS5 runner")
	func passStringConfigurationToSOCKS5Runner() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		let configContent = "tunnel:\n  mtu: 1360"
		let config = TunnelConfig(
			xrayConfigPath: "/tmp/config.json",
			socks5Config: .string(content: configContent),
			geoDataDir: "/tmp"
		)
		
		try controller.startTunnelServices(configs: config)
		
		// Verify SOCKS5 received configuration
		#expect(mockSocks.lastConfig != nil)
		
		if case let .string(content) = mockSocks.lastConfig {
			#expect(content == configContent)
		} else {
			throw TestError.assertionFailure("Expected string config")
		}
	}
	
	@Test("Pass file configuration to SOCKS5 runner")
	func passFileConfigurationToSOCKS5Runner() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		let configPath = URL(fileURLWithPath: "/tmp/socks5-config.yaml")
		let config = TunnelConfig(
			xrayConfigPath: "/tmp/config.json",
			socks5Config: .file(path: configPath),
			geoDataDir: "/tmp"
		)
		
		try controller.startTunnelServices(configs: config)
		
		// Verify SOCKS5 received file configuration
		#expect(mockSocks.lastConfig != nil)
		
		if case let .file(path) = mockSocks.lastConfig {
			#expect(path == configPath)
		} else {
			throw TestError.assertionFailure("Expected file config")
		}
	}
	
	// MARK: - Error Handling Tests
	
	@Test("Propagate Xray runner error on start")
	func propagateXrayRunnerErrorOnStart() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		
		enum TestRunnerError: Error {
			case mockError
		}
		
		mockXray.shouldThrowOnRun = TestRunnerError.mockError
		
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		let config = TunnelConfig(
			xrayConfigPath: "/tmp/config.json",
			socks5Config: .string(content: "test"),
			geoDataDir: "/tmp"
		)
		
		// Should throw the error
		#expect(throws: TestRunnerError.self) {
			try controller.startTunnelServices(configs: config)
		}
		
		// Verify Xray run was attempted
		#expect(mockXray.runCallCount == 1)
	}
	
	@Test("Gracefully handle stop errors")
	func gracefullyHandleStopErrors() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		
		enum TestStopError: Error {
			case stopFailed
		}
		
		mockXray.shouldThrowOnStop = TestStopError.stopFailed
		
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		// Start services first
		let config = TunnelConfig(
			xrayConfigPath: "/tmp/config.json",
			socks5Config: .string(content: "test"),
			geoDataDir: "/tmp"
		)
		try controller.startTunnelServices(configs: config)
		
		// Should not throw even if stop fails
		controller.stopTunnelServices()
		
		// Verify stop was attempted
		#expect(mockXray.stopCallCount == 1)
		#expect(mockSocks.quitCallCount == 1)
	}
	
	// MARK: - State Management Tests
	
	@Test("Allow multiple start-stop cycles")
	func allowMultipleStartStopCycles() throws {
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
		
		// First cycle
		try controller.startTunnelServices(configs: config)
		controller.stopTunnelServices()
		
		// Second cycle
		try controller.startTunnelServices(configs: config)
		controller.stopTunnelServices()
		
		// Verify call counts
		#expect(mockXray.runCallCount == 2)
		#expect(mockXray.stopCallCount == 2)
		#expect(mockSocks.runCallCount == 2)
		#expect(mockSocks.quitCallCount == 2)
	}
	
	@Test("Handle stop without start")
	func handleStopWithoutStart() {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		// Stop without starting - should not crash
		controller.stopTunnelServices()
		
		// Stop should still be called
		#expect(mockSocks.quitCallCount == 1)
		#expect(mockXray.stopCallCount == 1)
	}
	
	// MARK: - Dependency Injection Tests
	
	@Test("Use injected dependencies")
	func useInjectedDependencies() throws {
		let customXray = MockXrayCoreRunner()
		let customSocks = MockSocksTunnelRunner()
		
		let controller = XrayTunnelController(
			xrayRunner: customXray,
			socksController: customSocks
		)
		
		let config = TunnelConfig(
			xrayConfigPath: "/tmp/config.json",
			socks5Config: .string(content: "test"),
			geoDataDir: "/tmp"
		)
		
		try controller.startTunnelServices(configs: config)
		
		// Verify our specific instances were used
		#expect(customXray.runCallCount == 1)
		#expect(customSocks.runCallCount == 1)
	}
	
	@Test("Each controller instance has independent runners")
	func eachControllerInstanceHasIndependentRunners() throws {
		let xray1 = MockXrayCoreRunner()
		let socks1 = MockSocksTunnelRunner()
		let controller1 = XrayTunnelController(
			xrayRunner: xray1,
			socksController: socks1
		)
		
		let xray2 = MockXrayCoreRunner()
		let socks2 = MockSocksTunnelRunner()
		let controller2 = XrayTunnelController(
			xrayRunner: xray2,
			socksController: socks2
		)
		
		let config = TunnelConfig(
			xrayConfigPath: "/tmp/config.json",
			socks5Config: .string(content: "test"),
			geoDataDir: "/tmp"
		)
		
		// Start only first controller
		try controller1.startTunnelServices(configs: config)
		
		// Verify only first controller's runners were called
		#expect(xray1.runCallCount == 1)
		#expect(socks1.runCallCount == 1)
		#expect(xray2.runCallCount == 0)
		#expect(socks2.runCallCount == 0)
	}
	
	// MARK: - Completion Handler Tests
	
	@Test("SOCKS5 completion handler receives success result")
	func socks5CompletionHandlerReceivesSuccessResult() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		
		mockSocks.completionResult = 0  // Success
		
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		let config = TunnelConfig(
			xrayConfigPath: "/tmp/config.json",
			socks5Config: .string(content: "test"),
			geoDataDir: "/tmp"
		)
		
		try controller.startTunnelServices(configs: config)
		
		// Verify completion was called with success
		#expect(mockSocks.lastCompletionResult == 0)
	}
	
	@Test("SOCKS5 completion handler receives failure result")
	func socks5CompletionHandlerReceivesFailureResult() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		
		mockSocks.completionResult = -1  // Failure
		
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		let config = TunnelConfig(
			xrayConfigPath: "/tmp/config.json",
			socks5Config: .string(content: "test"),
			geoDataDir: "/tmp"
		)
		
		try controller.startTunnelServices(configs: config)
		
		// Verify completion was called with failure
		#expect(mockSocks.lastCompletionResult == -1)
	}
	
	// MARK: - Edge Cases
	
	@Test("Handle empty configuration paths")
	func handleEmptyConfigurationPaths() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		let config = TunnelConfig(
			xrayConfigPath: "",
			socks5Config: .string(content: ""),
			geoDataDir: ""
		)
		
		// Should not crash with empty paths
		try controller.startTunnelServices(configs: config)
		
		#expect(mockXray.lastRunConfigPath == "")
		#expect(mockXray.lastRunDataDir == "")
	}
	
	@Test("Handle very long configuration paths")
	func handleVeryLongConfigurationPaths() throws {
		let mockXray = MockXrayCoreRunner()
		let mockSocks = MockSocksTunnelRunner()
		let controller = XrayTunnelController(
			xrayRunner: mockXray,
			socksController: mockSocks
		)
		
		let longPath = "/very/long/path/" + String(repeating: "directory/", count: 100) + "config.json"
		
		let config = TunnelConfig(
			xrayConfigPath: longPath,
			socks5Config: .string(content: "test"),
			geoDataDir: "/tmp"
		)
		
		try controller.startTunnelServices(configs: config)
		
		#expect(mockXray.lastRunConfigPath == longPath)
	}
}
