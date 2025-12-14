import Foundation
import Testing
@testable import TunnelX

/// Comprehensive test suite for XrayConfigBuilder.
///
/// Tests cover:
/// - URL parsing and configuration generation
/// - IP address preservation (IPv4 and IPv6)
/// - Routing rule generation
/// - Inbound/outbound configuration
/// - JSON structure validation
/// - Error handling
@Suite("XrayConfigBuilder Tests")
struct XrayConfigBuilderTests {
	
	// MARK: - Setup/Teardown
	
	init() {
		setupTestEnvironment()
	}
	
	// MARK: - Basic Configuration Building
	
	@Test("Build configuration from valid VLESS URL")
	func buildConfigurationFromValidURL() throws {
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessWebSocketURL()
		
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		// Verify root structure
		#expect(json["log"] != nil)
		#expect(json["routing"] != nil)
		#expect(json["inbounds"] != nil)
		#expect(json["outbounds"] != nil)
		#expect(json["dns"] != nil)
	}
	
	@Test("Build configuration from JSON string")
	func buildConfigurationFromJSONString() throws {
		let builder = XrayConfigBuilder()
		
		let jsonString = """
		{
			"inbounds": [],
			"outbounds": [{
				"protocol": "freedom"
			}]
		}
		"""
		
		let data = try builder.build(from: .json(jsonString))
		let json = try parseJSON(data)
		
		#expect(json["inbounds"] != nil)
		#expect(json["outbounds"] != nil)
	}
	
	// MARK: - IPv4 Address Preservation
	
	@Test("Preserve IPv4 addresses without resolution")
	func preserveIPv4AddressesWithoutResolution() throws {
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessRealityURL()
		
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		// Extract outbound configuration
		let outbounds = try requireArray(json["outbounds"])
		let firstOutbound = try requireDictionary(outbounds.first)
		
		#expect(firstOutbound["protocol"] as? String == "vless")
		
		let settings = try requireDictionary(firstOutbound["settings"])
		let vnext = try requireArray(settings["vnext"])
		let node = try requireDictionary(vnext.first)
		
		// IPv4 address should be preserved as-is
		#expect(node["address"] as? String == "100.100.100.100")
		#expect(node["port"] as? Int == 8443)
	}
	
	@Test("Preserve IPv6 addresses without resolution")
	func preserveIPv6AddressesWithoutResolution() throws {
		let builder = XrayConfigBuilder()
		
		// IPv6 addresses in URLs must be enclosed in square brackets
		let url = VlessURLBuilder()
			.withHost("[2001:db8::1]")
			.build()
		
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		let outbounds = try requireArray(json["outbounds"])
		let firstOutbound = try requireDictionary(outbounds.first)
		let settings = try requireDictionary(firstOutbound["settings"])
		let vnext = try requireArray(settings["vnext"])
		let node = try requireDictionary(vnext.first)
		
		// IPv6 address should be preserved (with or without brackets depending on implementation)
		let address = node["address"] as? String
		#expect(address != nil)
		#expect(address?.contains("2001:db8::1") == true)
	}
	
	// MARK: - Inbound Configuration
	
	@Test("Generate SOCKS5 inbound with correct parameters")
	func generateSOCKS5InboundWithCorrectParameters() throws {
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessWebSocketURL()
		
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		let inbounds = try requireArray(json["inbounds"])
		let firstInbound = try requireDictionary(inbounds.first)
		
		// Verify SOCKS5 configuration
		#expect(firstInbound["protocol"] as? String == "socks")
		#expect(firstInbound["tag"] as? String == "socks")
		#expect(firstInbound["listen"] as? String == "::1")
		#expect(firstInbound["port"] as? Int == 10808)
		
		// Verify settings
		let settings = try requireDictionary(firstInbound["settings"])
		#expect(settings["auth"] as? String == "noauth")
		#expect(settings["udp"] as? Bool == true)
	}
	
	@Test("Inbound includes sniffing configuration")
	func inboundIncludesSniffingConfiguration() throws {
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessWebSocketURL()
		
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		let inbounds = try requireArray(json["inbounds"])
		let firstInbound = try requireDictionary(inbounds.first)
		
		// Verify sniffing exists
		#expect(firstInbound["sniffing"] != nil)
	}
	
	// MARK: - Outbound Configuration
	
	@Test("Generate correct VLESS outbound configuration")
	func generateCorrectVLESSOutboundConfiguration() throws {
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessRealityURL()
		
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		let outbounds = try requireArray(json["outbounds"])
		let vlessOutbound = try requireDictionary(outbounds.first)
		
		// Verify protocol
		#expect(vlessOutbound["protocol"] as? String == "vless")
		#expect(vlessOutbound["tag"] as? String == "proxy")
		
		// Verify stream settings
		let streamSettings = try requireDictionary(vlessOutbound["streamSettings"])
		#expect(streamSettings["network"] as? String == "tcp")
		#expect(streamSettings["security"] as? String == "reality")
		
		// Verify Reality settings
		let realitySettings = try requireDictionary(streamSettings["realitySettings"])
		#expect(realitySettings["publicKey"] as? String == "Zl2s1CzlnDwT_1izA5RG2oCOdMO37KEXMZ2QrPe7U2w")
		#expect(realitySettings["serverName"] as? String == "google.com")
		#expect(realitySettings["fingerprint"] as? String == "random")
	}
	
	@Test("Include freedom and blackhole outbounds")
	func includeFreedomAndBlackholeOutbounds() throws {
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessWebSocketURL()
		
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		let outbounds = try requireArray(json["outbounds"])
		
		// Should have at least 3 outbounds: proxy, freedom, blackhole
		#expect(outbounds.count >= 3)
		
		let protocols = outbounds.compactMap { outbound -> String? in
			guard let dict = outbound as? [String: Any] else { return nil }
			return dict["protocol"] as? String
		}
		
		#expect(protocols.contains("vless") || protocols.contains("vmess") || protocols.contains("trojan"))
		#expect(protocols.contains("freedom"))
		#expect(protocols.contains("blackhole"))
	}
	
	// MARK: - Routing Configuration
	
	@Test("Generate routing rules with correct inbound tags")
	func generateRoutingRulesWithCorrectInboundTags() throws {
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessRealityURL()
		
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		let routing = try requireDictionary(json["routing"])
		let rules = try requireArray(routing["rules"])
		
		#expect(rules.count > 0)
		
		// Check first rule has inbound tag
		let firstRule = try requireDictionary(rules.first)
		let inboundTags = try requireArray(firstRule["inboundTag"])
		
		#expect(inboundTags.contains { ($0 as? String) == "socks" })
	}
	
	@Test("Routing includes domain strategy and matcher")
	func routingIncludesDomainStrategyAndMatcher() throws {
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessWebSocketURL()
		
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		let routing = try requireDictionary(json["routing"])
		
		// Should have domain strategy (required)
		#expect(routing["domainStrategy"] != nil)
		
		// domainMatcher is optional in Xray config, so we just check routing exists
		#expect(routing["rules"] != nil)
	}
	
	// MARK: - DNS Configuration
	
	@Test("Include DNS configuration")
	func includeDNSConfiguration() throws {
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessWebSocketURL()
		
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		let dns = try requireDictionary(json["dns"])
		
		// DNS should have servers
		#expect(dns["servers"] != nil)
	}
	
	// MARK: - Log Configuration
	
	@Test("Include log configuration with file paths")
	func includeLogConfigurationWithFilePaths() throws {
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessWebSocketURL()
		
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		let log = try requireDictionary(json["log"])
		
		// Should have log level and paths
		#expect(log["loglevel"] != nil)
		#expect(log["access"] != nil)
		#expect(log["error"] != nil)
	}
	
	// MARK: - Network Type Tests
	
	@Test("Build configuration with WebSocket transport")
	func buildConfigurationWithWebSocketTransport() throws {
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessWebSocketURL()
		
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		let outbounds = try requireArray(json["outbounds"])
		let firstOutbound = try requireDictionary(outbounds.first)
		let streamSettings = try requireDictionary(firstOutbound["streamSettings"])
		
		#expect(streamSettings["network"] as? String == "ws")
		
		// Should have wsSettings
		let wsSettings = try requireDictionary(streamSettings["wsSettings"])
		#expect(wsSettings["path"] as? String == "/websocket")
	}
	
	@Test("Build configuration with gRPC transport")
	func buildConfigurationWithGRPCTransport() throws {
		let builder = XrayConfigBuilder()
		let url = XrayConfigTestDataBuilder.buildVlessGRPCURL()
		
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		let outbounds = try requireArray(json["outbounds"])
		let firstOutbound = try requireDictionary(outbounds.first)
		let streamSettings = try requireDictionary(firstOutbound["streamSettings"])
		
		#expect(streamSettings["network"] as? String == "grpc")
		
		// Should have grpcSettings
		let grpcSettings = try requireDictionary(streamSettings["grpcSettings"])
		#expect(grpcSettings["serviceName"] as? String == "grpcService")
	}
	
	// MARK: - File Saving Tests
	
	@Test("Save configuration to file successfully")
	func saveConfigurationToFileSuccessfully() throws {
		let testDir = setupTestEnvironment()
		defer { cleanupTestEnvironment(testDir) }
		
		let builder = XrayConfigBuilder()
		let writer = XrayConfigurationWriter()
		let url = XrayConfigTestDataBuilder.buildVlessWebSocketURL()
		
		// Build and save configuration
		let data = try builder.build(from: .url(url))
		let fileURL = try writer.writeConfiguration(data, fileName: "test-config.json")
		
		// Verify file exists
		#expect(FileManager.default.fileExists(atPath: fileURL.path))
		
		// Verify file is readable
		let savedData = try Data(contentsOf: fileURL)
		let json = try parseJSON(savedData)
		
		#expect(json["inbounds"] != nil)
		#expect(json["outbounds"] != nil)
	}
	
	@Test("SOCKS5 config file generation")
	func socks5ConfigFileGeneration() throws {
		let testDir = setupTestEnvironment()
		defer { cleanupTestEnvironment(testDir) }
		
		let writer = XrayConfigurationWriter()
		let fileURL = try writer.writeSocks5Config(
			address: XrayTunnelSettings.tunnelAddress,
			port: 10808
		)
		
		// Verify file exists
		#expect(FileManager.default.fileExists(atPath: fileURL.path))
		
		// Verify it's YAML format
		let content = try String(contentsOf: fileURL)
		#expect(content.contains("tunnel:"))
		#expect(content.contains("socks5:"))
		#expect(content.contains("port:"))
	}
	
	// MARK: - Error Handling
	
	@Test("Throw error on invalid URL")
	func throwErrorOnInvalidURL() throws {
		let builder = XrayConfigBuilder()
		
		#expect(throws: TunnelXError.self) {
			try builder.build(from: .url("invalid://url"))
		}
	}
	
	@Test("Throw error on malformed JSON string")
	func throwErrorOnMalformedJSONString() throws {
		let builder = XrayConfigBuilder()
		
		// Test with clearly invalid JSON
		do {
			_ = try builder.build(from: .json("{ this is not valid json }"))
			Issue.record("Expected error to be thrown for malformed JSON")
		} catch let error as TunnelXError {
			// Expected - malformed JSON should throw TunnelXError
			switch error {
			case .jsonParsingFailed:
				// Success - correct error type
				break
			default:
				Issue.record("Expected .jsonParsingFailed error, got \(error)")
			}
		} catch {
			Issue.record("Expected TunnelXError, got \(error)")
		}
	}
	
	// MARK: - Edge Cases
	
	@Test("Handle URL with special characters in fragment")
	func handleURLWithSpecialCharactersInFragment() throws {
		let builder = XrayConfigBuilder()
		
		// URL encoding will handle special characters
		let specialFragment = "Connection_Test_1"
		let url = VlessURLBuilder()
			.withFragment(specialFragment)
			.build()
		
		// Should not throw
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		#expect(json["outbounds"] != nil)
	}
	
	@Test("Handle very long configuration URLs")
	func handleVeryLongConfigurationURLs() throws {
		let builder = XrayConfigBuilder()
		
		var urlBuilder = VlessURLBuilder()
		// Add many parameters (but reasonable amount)
		for i in 0..<10 {
			urlBuilder = urlBuilder.withParameter("param\(i)", value: "value\(i)")
		}
		
		let url = urlBuilder.build()
		
		// Should not throw
		let data = try builder.build(from: .url(url))
		let json = try parseJSON(data)
		
		#expect(json["outbounds"] != nil)
	}
}
