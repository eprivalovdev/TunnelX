import Foundation
import Testing
@testable import TunnelX

/// Comprehensive test suite for HostResolverService.
///
/// Tests cover:
/// - IPv4/IPv6 address detection
/// - DNS resolution
/// - Recursive JSON structure traversal
/// - Change tracking
/// - Edge cases and error handling
@Suite("HostResolverService Tests")
struct HostResolverServiceTests {
	
	// MARK: - IPv4 Address Detection
	
	@Test("Detect valid IPv4 addresses")
	func detectValidIPv4Addresses() {
		let resolver = HostResolverService()
		
		let ipv4Addresses = [
			"192.168.1.1",
			"10.0.0.1",
			"172.16.0.1",
			"8.8.8.8",
			"255.255.255.255",
			"0.0.0.0",
			"127.0.0.1"
		]
		
		for address in ipv4Addresses {
			var changes: [(host: String, ip: String)] = []
			let input: [String: Any] = ["address": address]
			
			let output = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
			let dict = try? requireDictionary(output)
			
			// IPv4 should remain unchanged
			#expect(dict?["address"] as? String == address)
			// No changes should be recorded for IP addresses
			#expect(changes.isEmpty)
		}
	}
	
	@Test("Detect invalid IPv4 patterns")
	func detectInvalidIPv4Patterns() {
		let resolver = HostResolverService()
		
		let invalidPatterns = [
			"999.999.999.999",  // Out of range
			"192.168.1",        // Incomplete
			"192.168.1.1.1",    // Too many octets
			"192.168.01.1",     // Leading zeros (not valid in strict sense)
		]
		
		// These should NOT be detected as IP addresses
		// and should attempt resolution (which may fail)
		for pattern in invalidPatterns {
			var changes: [(host: String, ip: String)] = []
			let input: [String: Any] = ["address": pattern]
			
			_ = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
			
			// If resolved, changes would be recorded
			// If not resolved, original value preserved
		}
	}
	
	// MARK: - IPv6 Address Detection
	
	@Test("Detect valid IPv6 addresses")
	func detectValidIPv6Addresses() {
		let resolver = HostResolverService()
		
		let ipv6Addresses = [
			"2001:db8::1",
			"fe80::1",
			"::1",
			"2001:0db8:85a3:0000:0000:8a2e:0370:7334",
			"2001:db8:85a3::8a2e:370:7334",
			"::",
			"::ffff:192.0.2.1"
		]
		
		for address in ipv6Addresses {
			var changes: [(host: String, ip: String)] = []
			let input: [String: Any] = ["address": address]
			
			let output = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
			let dict = try? requireDictionary(output)
			
			// IPv6 should remain unchanged
			#expect(dict?["address"] as? String == address)
			// No changes for IP addresses
			#expect(changes.isEmpty)
		}
	}
	
	// MARK: - Hostname Resolution
	
	@Test("Resolve localhost hostname")
	func resolveLocalhostHostname() {
		let resolver = HostResolverService()
		
		let resolved = resolver.resolveHost("localhost")
		
		// Should resolve to either ::1 or 127.0.0.1
		#expect(resolved != nil)
		#expect(resolved == "::1" || resolved == "127.0.0.1")
	}
	
	@Test("Return nil for non-existent hostname")
	func returnNilForNonExistentHostname() {
		let resolver = HostResolverService()
		
		let nonExistent = "this-domain-definitely-does-not-exist-12345.invalid"
		let resolved = resolver.resolveHost(nonExistent)
		
		#expect(resolved == nil)
	}
	
	// MARK: - Recursive Resolution Tests
	
	@Test("Preserve numeric addresses in nested structures")
	func preserveNumericAddressesInNestedStructures() {
		let resolver = HostResolverService()
		var changes: [(host: String, ip: String)] = []
		
		let input: [String: Any] = [
			"address": "100.100.100.100",
			"nested": [
				"address": "fe80::1",
				"deeplyNested": [
					"address": "192.168.1.1"
				]
			]
		]
		
		let output = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
		let dict = try? requireDictionary(output)
		
		// All numeric addresses should be preserved
		#expect(dict?["address"] as? String == "100.100.100.100")
		
		let nested = try? requireDictionary(dict?["nested"])
		#expect(nested?["address"] as? String == "fe80::1")
		
		let deeplyNested = try? requireDictionary(nested?["deeplyNested"])
		#expect(deeplyNested?["address"] as? String == "192.168.1.1")
		
		// No changes should be recorded
		#expect(changes.isEmpty)
	}
	
	@Test("Resolve hostnames in nested dictionaries")
	func resolveHostnamesInNestedDictionaries() {
		let resolver = HostResolverService()
		var changes: [(host: String, ip: String)] = []
		
		let input: [String: Any] = [
			"server": [
				"address": "localhost",
				"port": 443
			]
		]
		
		let output = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
		let dict = try? requireDictionary(output)
		let server = try? requireDictionary(dict?["server"])
		
		// localhost should be resolved
		let address = server?["address"] as? String
		#expect(address != nil)
		#expect(address != "localhost")  // Should be IP now
		
		// Port should remain unchanged
		#expect(server?["port"] as? Int == 443)
		
		// Change should be tracked
		#expect(changes.count == 1)
		#expect(changes.first?.host == "localhost")
	}
	
	@Test("Handle arrays in JSON structure")
	func handleArraysInJSONStructure() {
		let resolver = HostResolverService()
		var changes: [(host: String, ip: String)] = []
		
		let input: [String: Any] = [
			"servers": [
				["address": "192.168.1.1", "port": 443],
				["address": "10.0.0.1", "port": 8443]
			]
		]
		
		let output = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
		let dict = try? requireDictionary(output)
		let servers = try? requireArray(dict?["servers"])
		
		#expect(servers?.count == 2)
		
		let firstServer = try? requireDictionary(servers?[0])
		#expect(firstServer?["address"] as? String == "192.168.1.1")
		
		let secondServer = try? requireDictionary(servers?[1])
		#expect(secondServer?["address"] as? String == "10.0.0.1")
		
		// No changes for IP addresses
		#expect(changes.isEmpty)
	}
	
	@Test("Preserve non-address keys unchanged")
	func preserveNonAddressKeysUnchanged() {
		let resolver = HostResolverService()
		var changes: [(host: String, ip: String)] = []
		
		let input: [String: Any] = [
			"address": "192.168.1.1",
			"host": "example.com",  // Different key, not "address"
			"port": 443,
			"protocol": "vless",
			"settings": [
				"address": "10.0.0.1",
				"host": "another.example.com"
			]
		]
		
		let output = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
		let dict = try? requireDictionary(output)
		
		// "address" keys should be processed
		#expect(dict?["address"] as? String == "192.168.1.1")
		
		// Other keys remain unchanged
		#expect(dict?["host"] as? String == "example.com")
		#expect(dict?["port"] as? Int == 443)
		#expect(dict?["protocol"] as? String == "vless")
		
		// No resolution for IPs
		#expect(changes.isEmpty)
	}
	
	// MARK: - Change Tracking Tests
	
	@Test("Track hostname resolution changes")
	func trackHostnameResolutionChanges() {
		let resolver = HostResolverService()
		var changes: [(host: String, ip: String)] = []
		
		let input: [String: Any] = [
			"primary": ["address": "localhost"],
			"secondary": ["address": "192.168.1.1"]
		]
		
		_ = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
		
		// Should track only the hostname resolution, not IP
		#expect(changes.count == 1)
		#expect(changes.first?.host == "localhost")
		#expect(changes.first?.ip != nil)
	}
	
	@Test("Track multiple hostname resolutions")
	func trackMultipleHostnameResolutions() {
		let resolver = HostResolverService()
		var changes: [(host: String, ip: String)] = []
		
		let input: [String: Any] = [
			"servers": [
				["address": "localhost"],
				["address": "localhost"]  // Duplicate
			]
		]
		
		_ = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
		
		// Both should be tracked separately
		#expect(changes.count == 2)
		#expect(changes.allSatisfy { $0.host == "localhost" })
	}
	
	// MARK: - Edge Cases
	
	@Test("Handle empty dictionary")
	func handleEmptyDictionary() {
		let resolver = HostResolverService()
		var changes: [(host: String, ip: String)] = []
		
		let input: [String: Any] = [:]
		
		let output = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
		let dict = try? requireDictionary(output)
		
		#expect(dict?.isEmpty == true)
		#expect(changes.isEmpty)
	}
	
	@Test("Handle empty array")
	func handleEmptyArray() {
		let resolver = HostResolverService()
		var changes: [(host: String, ip: String)] = []
		
		let input: [String: Any] = ["servers": []]
		
		let output = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
		let dict = try? requireDictionary(output)
		let servers = try? requireArray(dict?["servers"])
		
		#expect(servers?.isEmpty == true)
		#expect(changes.isEmpty)
	}
	
	@Test("Handle deeply nested structures")
	func handleDeeplyNestedStructures() {
		let resolver = HostResolverService()
		var changes: [(host: String, ip: String)] = []
		
		let input: [String: Any] = [
			"level1": [
				"level2": [
					"level3": [
						"level4": [
							"level5": [
								"address": "192.168.1.1"
							]
						]
					]
				]
			]
		]
		
		let output = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
		
		// Should successfully traverse and preserve deep structure
		let dict = try? requireDictionary(output)
		#expect(dict != nil)
		
		// Navigate to deepest level
		let level1 = try? requireDictionary(dict?["level1"])
		let level2 = try? requireDictionary(level1?["level2"])
		let level3 = try? requireDictionary(level2?["level3"])
		let level4 = try? requireDictionary(level3?["level4"])
		let level5 = try? requireDictionary(level4?["level5"])
		
		#expect(level5?["address"] as? String == "192.168.1.1")
		#expect(changes.isEmpty)
	}
	
	@Test("Handle mixed types in structure")
	func handleMixedTypesInStructure() {
		let resolver = HostResolverService()
		var changes: [(host: String, ip: String)] = []
		
		let input: [String: Any] = [
			"address": "192.168.1.1",
			"port": 443,
			"enabled": true,
			"timeout": 30.5,
			"tags": ["proxy", "secure"],
			"metadata": NSNull(),
			"nested": ["address": "10.0.0.1"]
		]
		
		let output = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
		let dict = try? requireDictionary(output)
		
		// All types should be preserved
		#expect(dict?["address"] as? String == "192.168.1.1")
		#expect(dict?["port"] as? Int == 443)
		#expect(dict?["enabled"] as? Bool == true)
		#expect(dict?["timeout"] as? Double == 30.5)
		#expect((dict?["tags"] as? [String])?.count == 2)
		#expect(dict?["metadata"] is NSNull)
		
		let nested = try? requireDictionary(dict?["nested"])
		#expect(nested?["address"] as? String == "10.0.0.1")
	}
	
	@Test("Handle string values that are not addresses")
	func handleStringValuesThatAreNotAddresses() {
		let resolver = HostResolverService()
		var changes: [(host: String, ip: String)] = []
		
		let input: [String: Any] = [
			"address": "192.168.1.1",
			"name": "My Server",
			"description": "Primary proxy server"
		]
		
		let output = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
		let dict = try? requireDictionary(output)
		
		// Only "address" key should be processed
		#expect(dict?["address"] as? String == "192.168.1.1")
		#expect(dict?["name"] as? String == "My Server")
		#expect(dict?["description"] as? String == "Primary proxy server")
		
		#expect(changes.isEmpty)
	}
	
	@Test("Handle very long hostname")
	func handleVeryLongHostname() {
		let resolver = HostResolverService()
		var changes: [(host: String, ip: String)] = []
		
		// Create a very long (but invalid) hostname
		let longHostname = String(repeating: "subdomain.", count: 50) + "example.com"
		
		let input: [String: Any] = ["address": longHostname]
		
		let output = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
		let dict = try? requireDictionary(output)
		
		// Should not crash, even if resolution fails
		#expect(dict != nil)
	}
	
	@Test("Handle hostname with special characters")
	func handleHostnameWithSpecialCharacters() {
		let resolver = HostResolverService()
		var changes: [(host: String, ip: String)] = []
		
		let input: [String: Any] = [
			"address": "xn--e1afmkfd.xn--p1ai"  // IDN domain (пример.рф)
		]
		
		let output = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
		let dict = try? requireDictionary(output)
		
		// Should handle internationalized domains
		#expect(dict != nil)
	}
	
	// MARK: - Performance Tests
	
	@Test("Handle large JSON structure efficiently")
	func handleLargeJSONStructureEfficiently() {
		let resolver = HostResolverService()
		var changes: [(host: String, ip: String)] = []
		
		// Create a large structure with many servers
		var servers: [[String: Any]] = []
		for i in 0..<100 {
			servers.append([
				"address": "192.168.\(i % 256).\(i % 256)",
				"port": 8000 + i,
				"protocol": "vless"
			])
		}
		
		let input: [String: Any] = [
			"servers": servers,
			"metadata": [
				"count": 100,
				"version": "1.0"
			]
		]
		
		let startTime = Date()
		let output = resolver.resolveAddressesWithLogging(in: input, changes: &changes)
		let duration = Date().timeIntervalSince(startTime)
		
		// Should complete quickly (under 1 second)
		#expect(duration < 1.0)
		
		let dict = try? requireDictionary(output)
		let outputServers = try? requireArray(dict?["servers"])
		
		#expect(outputServers?.count == 100)
		#expect(changes.isEmpty)  // All IPs, no resolutions
	}
}
