import Testing
import Foundation
@testable import TunnelX

/// Comprehensive test suite for LinkParser - Xray share link parser
///
/// Tests cover:
/// - Valid URL parsing for all supported protocols
/// - Type-safe parameter access
/// - Invalid URL error handling
/// - Edge cases and boundary conditions
@Suite("LinkParser Comprehensive Tests")
struct LinkParserTests {
	
	// MARK: - Valid URL Parsing Tests
	
	@Test("Parse valid VLESS link with WebSocket and TLS")
	func parseValidVlessWebSocketTLS() throws {
		let url = "vless://550e8400-e29b-41d4-a716-446655440000@example.com:443?type=ws&security=tls&path=/websocket&host=example.com#MyConnection"
		
		let parser = try LinkParser(urlString: url)
		
		#expect(parser.outboundProtocol == .vless)
		#expect(parser.userID == "550e8400-e29b-41d4-a716-446655440000")
		#expect(parser.host == "example.com")
		#expect(parser.port == 443)
		#expect(parser.network == .ws)
		#expect(parser.security == .tls)
		#expect(parser.fragment == "MyConnection")
		
		// Test type-safe parameter access
		#expect(parser.parameter(.path) == "/websocket")
		#expect(parser.parameter(.host) == "example.com")
	}
	
	@Test("Parse valid VLESS link with gRPC and Reality")
	func parseValidVlessGRPCReality() throws {
		let url = "vless://550e8400-e29b-41d4-a716-446655440000@example.com:443?type=grpc&security=reality&pbk=publicKeyHere&serviceName=grpcService&sni=example.com"
		
		let parser = try LinkParser(urlString: url)
		
		#expect(parser.outboundProtocol == .vless)
		#expect(parser.network == .grpc)
		#expect(parser.security == .reality)
		
		// Test type-safe parameter access
		#expect(parser.parameter(.pbk) == "publicKeyHere")
		#expect(parser.parameter(.serviceName) == "grpcService")
		#expect(parser.parameter(.sni) == "example.com")
	}
	
	@Test("Parse valid Trojan link with TCP")
	func parseValidTrojanURL() throws {
		let url = "trojan://password123@server.com:443?type=tcp&security=tls"
		
		let parser = try LinkParser(urlString: url)
		
		#expect(parser.outboundProtocol == .trojan)
		#expect(parser.userID == "password123")
		#expect(parser.host == "server.com")
		#expect(parser.port == 443)
		#expect(parser.network == .tcp)
		#expect(parser.security == .tls)
	}
	
	@Test("Parse valid VMess link with HTTP/2")
	func parseValidVMessHTTP() throws {
		let url = "vmess://uuid-here@proxy.example.com:8443?type=http&security=tls&path=/vmess&method=POST"
		
		let parser = try LinkParser(urlString: url)
		
		#expect(parser.outboundProtocol == .vmess)
		#expect(parser.network == .http)
		
		// Test type-safe parameter access
		#expect(parser.parameter(.path) == "/vmess")
		#expect(parser.parameter(.method) == "POST")
	}
	
	@Test("Parse link without fragment")
	func parseURLWithoutFragment() throws {
		let url = "vless://uuid@example.com:443?type=ws&security=none"
		
		let parser = try LinkParser(urlString: url)
		
		#expect(parser.fragment.isEmpty)
	}
	
	@Test("Parse link ignores empty query parameter values")
	func parseURLWithEmptyQueryValues() throws {
		let url = "vless://uuid@example.com:443?type=ws&security=tls&emptyParam="
		
		let parser = try LinkParser(urlString: url)
		
		// Empty parameters should be filtered out
		#expect(parser.parameter(.type) == "ws")
		#expect(parser.parametersMap["emptyParam"] == nil)
	}
	
	// MARK: - Type-Safe Parameter Access Tests
	
	@Test("Type-safe parameter access returns correct values")
	func typeSafeParameterAccess() throws {
		let url = "vless://uuid@example.com:443?type=grpc&security=reality&pbk=key123&serviceName=test"
		
		let parser = try LinkParser(urlString: url)
		
		// Using enum keys for type safety
		#expect(parser.parameter(.pbk) == "key123")
		#expect(parser.parameter(.serviceName) == "test")
		#expect(parser.parameter(.flow) == nil)  // Not present
	}
	
	@Test("Required parameter throws error when missing")
	func requireParameterThrowsWhenMissing() throws {
		let url = "vless://uuid@example.com:443?type=ws&security=tls"
		
		let parser = try LinkParser(urlString: url)
		
		// Should throw when required parameter is missing
		#expect(throws: TunnelXError.self) {
			_ = try parser.requireParameter(.pbk, or: .missingSecurityType)
		}
	}
	
	@Test("Required parameter returns value when present")
	func requireParameterReturnsValueWhenPresent() throws {
		let url = "vless://uuid@example.com:443?type=ws&security=reality&pbk=mykey"
		
		let parser = try LinkParser(urlString: url)
		
		let publicKey = try parser.requireParameter(.pbk, or: .missingSecurityType)
		#expect(publicKey == "mykey")
	}
	
	// MARK: - Invalid URL Error Handling Tests
	
	@Test("Throw error on completely invalid URL")
	func throwsOnInvalidURL() {
		let invalidURL = "this is not a URL :-)"
		
		#expect(throws: TunnelXError.self) {
			try LinkParser(urlString: invalidURL)
		}
	}
	
	@Test("Throw error on missing protocol scheme")
	func throwsOnMissingProtocol() {
		let url = "://uuid@example.com:443?type=ws&security=tls"
		
		#expect(throws: TunnelXError.self) {
			try LinkParser(urlString: url)
		}
	}
	
	@Test("Throw error on unsupported protocol")
	func throwsOnUnsupportedProtocol() {
		let url = "http://uuid@example.com:443?type=ws&security=tls"
		
		#expect(throws: TunnelXError.self) {
			try LinkParser(urlString: url)
		}
	}
	
	@Test("Throw error on missing user ID")
	func throwsOnMissingUserID() {
		let url = "vless://@example.com:443?type=ws&security=tls"
		
		#expect(throws: TunnelXError.self) {
			try LinkParser(urlString: url)
		}
	}
	
	@Test("Throw error on missing host")
	func throwsOnMissingHost() {
		let url = "vless://uuid@:443?type=ws&security=tls"
		
		#expect(throws: TunnelXError.self) {
			try LinkParser(urlString: url)
		}
	}
	
	@Test("Throw error on missing port")
	func throwsOnMissingPort() {
		let url = "vless://uuid@example.com?type=ws&security=tls"
		
		#expect(throws: TunnelXError.self) {
			try LinkParser(urlString: url)
		}
	}
	
	@Test("Throw error on invalid port - too low")
	func throwsOnInvalidPortTooLow() {
		let url = "vless://uuid@example.com:0?type=ws&security=tls"
		
		#expect(throws: TunnelXError.self) {
			try LinkParser(urlString: url)
		}
	}
	
	@Test("Throw error on invalid port - too high")
	func throwsOnInvalidPortTooHigh() {
		let url = "vless://uuid@example.com:65536?type=ws&security=tls"
		
		#expect(throws: TunnelXError.self) {
			try LinkParser(urlString: url)
		}
	}
	
	@Test("Throw error on missing network type parameter")
	func throwsOnMissingNetworkType() {
		let url = "vless://uuid@example.com:443?security=tls"
		
		#expect(throws: TunnelXError.self) {
			try LinkParser(urlString: url)
		}
	}
	
	@Test("Throw error on missing security type parameter")
	func throwsOnMissingSecurityType() {
		let url = "vless://uuid@example.com:443?type=ws"
		
		#expect(throws: TunnelXError.self) {
			try LinkParser(urlString: url)
		}
	}
	
	@Test("Throw error on unsupported network type")
	func throwsOnUnsupportedNetworkType() {
		let url = "vless://uuid@example.com:443?type=unknown&security=tls"
		
		#expect(throws: TunnelXError.self) {
			try LinkParser(urlString: url)
		}
	}
	
	@Test("Throw error on unsupported security type")
	func throwsOnUnsupportedSecurityType() {
		let url = "vless://uuid@example.com:443?type=ws&security=unknown"
		
		#expect(throws: TunnelXError.self) {
			try LinkParser(urlString: url)
		}
	}
	
	// MARK: - Boundary Condition Tests
	
	@Test("Parse URL with minimum valid port (1)")
	func parseURLWithMinimumPort() throws {
		let url = "vless://uuid@example.com:1?type=ws&security=tls"
		
		let parser = try LinkParser(urlString: url)
		
		#expect(parser.port == 1)
	}
	
	@Test("Parse URL with maximum valid port (65535)")
	func parseURLWithMaximumPort() throws {
		let url = "vless://uuid@example.com:65535?type=ws&security=tls"
		
		let parser = try LinkParser(urlString: url)
		
		#expect(parser.port == 65535)
	}
	
	@Test("Parse URL with very long fragment")
	func parseURLWithLongFragment() throws {
		let longFragment = String(repeating: "A", count: 1000)
		let url = "vless://uuid@example.com:443?type=ws&security=tls#\(longFragment)"
		
		let parser = try LinkParser(urlString: url)
		
		#expect(parser.fragment == longFragment)
		#expect(parser.fragment.count == 1000)
	}
	
	// MARK: - CustomStringConvertible Tests
	
	@Test("Description output contains all essential fields")
	func descriptionContainsAllFields() throws {
		let url = "vless://uuid@example.com:443?type=ws&security=tls&path=/test#TestConnection"
		let parser = try LinkParser(urlString: url)
		
		let description = parser.description
		
		#expect(description.contains("vless"))
		#expect(description.contains("example.com"))
		#expect(description.contains("443"))
		#expect(description.contains("ws"))
		#expect(description.contains("tls"))
		#expect(description.contains("TestConnection"))
	}
	
	@Test("Description shows <empty> for missing fragment")
	func descriptionShowsEmptyForMissingFragment() throws {
		let url = "vless://uuid@example.com:443?type=ws&security=tls"
		let parser = try LinkParser(urlString: url)
		
		let description = parser.description
		
		#expect(description.contains("<empty>"))
	}
	
	// MARK: - Equatable Tests
	
	@Test("Two parsers with identical URLs are equal")
	func equalityWithIdenticalURLs() throws {
		let url = "vless://uuid@example.com:443?type=ws&security=tls#Test"
		
		let parser1 = try LinkParser(urlString: url)
		let parser2 = try LinkParser(urlString: url)
		
		#expect(parser1 == parser2)
	}
	
	@Test("Two parsers with different hosts are not equal")
	func inequalityWithDifferentHosts() throws {
		let url1 = "vless://uuid@example1.com:443?type=ws&security=tls"
		let url2 = "vless://uuid@example2.com:443?type=ws&security=tls"
		
		let parser1 = try LinkParser(urlString: url1)
		let parser2 = try LinkParser(urlString: url2)
		
		#expect(parser1 != parser2)
	}
	
	// MARK: - Hashable Tests
	
	@Test("Identical parsers produce same hash")
	func hashableIdenticalParsers() throws {
		let url = "vless://uuid@example.com:443?type=ws&security=tls"
		
		let parser1 = try LinkParser(urlString: url)
		let parser2 = try LinkParser(urlString: url)
		
		#expect(parser1.hashValue == parser2.hashValue)
	}
	
	@Test("Parsers can be stored in Set and deduplicated")
	func parsersCanBeStoredInSet() throws {
		let url1 = "vless://uuid@example.com:443?type=ws&security=tls"
		let url2 = "vless://uuid@other.com:443?type=grpc&security=reality&pbk=key"
		
		let parser1 = try LinkParser(urlString: url1)
		let parser2 = try LinkParser(urlString: url2)
		let parser3 = try LinkParser(urlString: url1)  // Duplicate of parser1
		
		let set: Set = [parser1, parser2, parser3]
		
		// Should only contain 2 unique parsers
		#expect(set.count == 2)
	}
	
	// MARK: - Configuration Building Tests
	
	@Test("Successfully build configuration from parser")
	func buildConfigurationSuccessfully() throws {
		let url = "vless://550e8400-e29b-41d4-a716-446655440000@example.com:443?type=ws&security=tls&path=/websocket"
		
		let parser = try LinkParser(urlString: url)
		let config = try parser.getConfiguration()
		
		#expect(config.outbounds.count > 0)
	}
	
	// MARK: - All ParameterKey Values Tests
	
	@Test("All ParameterKey enum cases are accessible")
	func allParameterKeysAccessible() {
		// This test ensures all enum cases compile and are accessible
		let allKeys: [LinkParser.ParameterKey] = [
			.type, .security, .path, .sni, .host, .pbk, .sid, .spx,
			.serviceName, .authority, .fp, .alpn, .flow, .method,
			.headers, .quicSecurity, .key, .headerType, .mode, .mtu,
			.tti, .uplinkCapacity, .downlinkCapacity, .congestion,
			.readBufferSize, .writeBufferSize, .seed, .multiMode,
			.idle_timeout, .health_check_timeout, .initial_windows_size
		]
		
		#expect(allKeys.count == LinkParser.ParameterKey.allCases.count)
	}
}
