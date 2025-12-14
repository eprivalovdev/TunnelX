import Foundation

/// Unified error type for TunnelX operations
///
/// All errors in the TunnelX library use this enum to provide consistent error handling
/// with localized descriptions and unique error codes for debugging.
public enum TunnelXError: LocalizedError {
	
	// MARK: - 1xxx: URL & Link Parsing Errors
	
	/// The provided URL string is not a valid URL format
	case invalidURL(String)
	
	/// The URL scheme (protocol) is not supported (expected: vless, vmess, trojan, etc.)
	case unsupportedProtocol(String)
	
	/// The user ID (UUID) is missing from the connection URL
	case missingUserID
	
	/// The host address is missing from the connection URL
	case missingHost
	
	/// The port number is invalid or out of range (1-65535)
	case invalidPort(Int)
	
	/// The network type parameter is missing (ws, grpc, tcp, etc.)
	case missingNetworkType
	
	/// The network type value is not supported
	case unsupportedNetworkType(String)
	
	/// The security type parameter is missing (tls, reality, none)
	case missingSecurityType
	
	/// The security type value is not supported
	case unsupportedSecurityType(String)
	
	/// Required parameter is missing from the URL query parameters
	case missingRequiredParameter(key: String, context: String)
	
	/// Reality public key (pbk) is missing or empty
	case missingRealityPublicKey
	
	/// TLS Server Name Indication (SNI) is missing or empty
	case missingSNI
	
	/// Unsupported or invalid fingerprint value
	case invalidFingerprint(String)
	
	// MARK: - 2xxx: Environment & App Group Errors
	
	/// App Group identifier has not been configured
	case appGroupNotConfigured
	
	/// App Group container directory was not found in the file system
	case appGroupContainerNotFound(String)
	
	/// File system operation failed in the App Group container
	case fileSystemError(path: String, operation: String, underlying: Error)
	
	// MARK: - 3xxx: Xray Core Errors
	
	/// Failed to start the Xray core process
	case xrayCoreStartFailed(response: String)
	
	/// Failed to stop the Xray core process
	case xrayCoreStopFailed(response: String)
	
	/// Unable to retrieve Xray version information
	case xrayVersionUnavailable
	
	/// Failed to allocate free ports for Xray
	case xrayPortAllocationFailed(response: String)
	
	/// Failed to convert share link to JSON configuration
	case xrayShareLinkConversionFailed(response: String)
	
	/// General Xray operation failed
	case xrayOperationFailed(response: String)
	
	// MARK: - 4xxx: GeoData Errors
	
	/// GeoData container directory is unavailable
	case geoDataContainerUnavailable
	
	/// Failed to download GeoData file from remote server
	case geoDataDownloadFailed(url: URL, statusCode: Int)
	
	/// Network error occurred while downloading GeoData
	case geoDataNetworkError(url: URL, underlying: Error)
	
	/// Failed to write GeoData file to disk
	case geoDataWriteFailed(path: String, underlying: Error)
	
	// MARK: - 5xxx: Configuration Errors
	
	/// JSON string is invalid or malformed
	case invalidJSON(details: String)
	
	/// Failed to parse JSON data
	case jsonParsingFailed(underlying: Error)
	
	/// Failed to encode configuration to JSON format
	case jsonEncodingFailed(underlying: Error)
	
	/// Failed to convert string to Data
	case stringToDataConversionFailed
	
	/// Failed to convert Data to string
	case dataToStringConversionFailed
	
	/// Failed to build configuration from the provided source
	case configurationBuildFailed(underlying: Error)
	
	/// Failed to save configuration file to disk
	case configurationSaveFailed(path: String, underlying: Error)
	
	/// Failed to write configuration file
	case configurationWriteFailed(path: String, underlying: Error)
	
	/// Configuration is missing required outbound settings
	case missingOutboundConfiguration
	
	/// Invalid network type for the specified transport protocol
	case invalidNetworkType(expected: String, actual: String)
	
	/// Invalid security type for the specified protocol
	case invalidSecurityType(expected: String, actual: String)
	
	// MARK: - 6xxx: Tunnel Errors
	
	/// Failed to start VPN tunnel
	case tunnelStartFailed(underlying: Error)
	
	/// Tunnel configuration data is missing or invalid
	case invalidTunnelConfiguration
	
	/// Failed to decode tunnel configuration from options
	case tunnelConfigurationDecodeFailed
	
	/// SOCKS5 tunnel failed to start
	case socks5TunnelStartFailed(exitCode: Int32)
	
	// MARK: - 7xxx: Host Resolution Errors
	
	/// Failed to resolve hostname to IP address
	case hostResolutionFailed(hostname: String)
	
	// MARK: - Error Description
	
	public var errorDescription: String? {
		switch self {
		// 1xxx: URL & Link Parsing
		case .invalidURL(let url):
			return "Invalid URL format: \(url)"
		case .unsupportedProtocol(let proto):
			return "Unsupported protocol '\(proto)'. Supported protocols: vless, vmess, trojan, shadowsocks, wireguard"
		case .missingUserID:
			return "User ID (UUID) is required in the connection URL"
		case .missingHost:
			return "Host address is required in the connection URL"
		case .invalidPort(let port):
			return "Invalid port number: \(port). Port must be between 1 and 65535"
		case .missingNetworkType:
			return "Network type parameter is required. Supported types: ws, grpc, tcp, kcp, quic, http, httpupgrade, splithttp, xhttp"
		case .unsupportedNetworkType(let type):
			return "Unsupported network type: \(type)"
		case .missingSecurityType:
			return "Security type parameter is required. Supported types: none, tls, reality"
		case .unsupportedSecurityType(let type):
			return "Unsupported security type: \(type)"
		case .missingRequiredParameter(let key, let context):
			return "Required parameter '\(key)' is missing for \(context)"
		case .missingRealityPublicKey:
			return "Reality public key (pbk) is required when using Reality security"
		case .missingSNI:
			return "Server Name Indication (SNI) is required for TLS/Reality connections"
		case .invalidFingerprint(let fp):
			return "Invalid fingerprint value: \(fp). Supported: chrome, firefox, safari, ios, android, edge, 360, qq, random, randomized"
			
		// 2xxx: Environment & App Group
		case .appGroupNotConfigured:
			return "App Group not configured. Call DefaultsSuite.configure(appGroup:) or XrayEnvironmentBootstrapper.configure(appGroup:) before using the library"
		case .appGroupContainerNotFound(let identifier):
			return "App Group container not found for identifier '\(identifier)'. Verify your app's entitlements and provisioning profile"
		case .fileSystemError(let path, let operation, let error):
			return "File system error during '\(operation)' at path '\(path)': \(error.localizedDescription)"
			
		// 3xxx: Xray Core
		case .xrayCoreStartFailed(let response):
			return "Failed to start Xray core. Response: \(response)"
		case .xrayCoreStopFailed(let response):
			return "Failed to stop Xray core. Response: \(response)"
		case .xrayVersionUnavailable:
			return "Unable to retrieve Xray core version information"
		case .xrayPortAllocationFailed(let response):
			return "Failed to allocate free ports for Xray. Response: \(response)"
		case .xrayShareLinkConversionFailed(let response):
			return "Failed to convert share link to Xray configuration. Response: \(response)"
		case .xrayOperationFailed(let response):
			return "Xray operation failed. Response: \(response)"
			
		// 4xxx: GeoData
		case .geoDataContainerUnavailable:
			return "GeoData container directory is unavailable. Ensure App Group is properly configured"
		case .geoDataDownloadFailed(let url, let statusCode):
			return "Failed to download GeoData from '\(url.absoluteString)'. HTTP status code: \(statusCode)"
		case .geoDataNetworkError(let url, let error):
			return "Network error while downloading GeoData from '\(url.absoluteString)': \(error.localizedDescription)"
		case .geoDataWriteFailed(let path, let error):
			return "Failed to write GeoData file to '\(path)': \(error.localizedDescription)"
			
		// 5xxx: Configuration
		case .invalidJSON(let details):
			return "Invalid JSON format: \(details)"
		case .jsonParsingFailed(let error):
			return "Failed to parse JSON data: \(error.localizedDescription)"
		case .jsonEncodingFailed(let error):
			return "Failed to encode configuration to JSON: \(error.localizedDescription)"
		case .stringToDataConversionFailed:
			return "Failed to convert string to Data using UTF-8 encoding"
		case .dataToStringConversionFailed:
			return "Failed to convert Data to string using UTF-8 encoding"
		case .configurationBuildFailed(let error):
			return "Configuration build failed: \(error.localizedDescription)"
		case .configurationSaveFailed(let path, let error):
			return "Failed to save configuration to '\(path)': \(error.localizedDescription)"
		case .configurationWriteFailed(let path, let error):
			return "Failed to write configuration file to '\(path)': \(error.localizedDescription)"
		case .missingOutboundConfiguration:
			return "Configuration is missing required outbound settings"
		case .invalidNetworkType(let expected, let actual):
			return "Invalid network type: expected '\(expected)', but got '\(actual)'"
		case .invalidSecurityType(let expected, let actual):
			return "Invalid security type: expected '\(expected)', but got '\(actual)'"
			
		// 6xxx: Tunnel
		case .tunnelStartFailed(let error):
			return "Failed to start VPN tunnel: \(error.localizedDescription)"
		case .invalidTunnelConfiguration:
			return "Tunnel configuration data is missing or invalid"
		case .tunnelConfigurationDecodeFailed:
			return "Failed to decode tunnel configuration from start options"
		case .socks5TunnelStartFailed(let exitCode):
			return "SOCKS5 tunnel failed to start with exit code: \(exitCode)"
			
		// 7xxx: Host Resolution
		case .hostResolutionFailed(let hostname):
			return "Failed to resolve hostname '\(hostname)' to IP address"
		}
	}
}

// MARK: - NSError Bridge

extension NSError {
	/// Creates an NSError from a TunnelXError
	///
	/// This allows TunnelXError to be used in APIs that require NSError,
	/// such as Network Extension callbacks.
	///
	/// - Parameter error: The TunnelXError to convert
	/// - Returns: An NSError with the same domain, code, and localized description
	public static func tunnelX(_ error: TunnelXError) -> NSError {
		NSError(
			domain: "com.tunnelx.error",
			code: error.errorCode,
			userInfo: [
				NSLocalizedDescriptionKey: error.localizedDescription,
				NSLocalizedFailureReasonErrorKey: error.failureReason ?? ""
			]
		)
	}
}

// MARK: - Error Codes

private extension TunnelXError {
	/// Unique error code for each error case
	///
	/// Error codes are organized by category:
	/// - 1xxx: URL & Link Parsing errors
	/// - 2xxx: Environment & App Group errors
	/// - 3xxx: Xray Core errors
	/// - 4xxx: GeoData errors
	/// - 5xxx: Configuration errors
	/// - 6xxx: Tunnel errors
	/// - 7xxx: Host Resolution errors
	var errorCode: Int {
		switch self {
		// 1xxx: URL & Link Parsing
		case .invalidURL: return 1001
		case .unsupportedProtocol: return 1002
		case .missingUserID: return 1003
		case .missingHost: return 1004
		case .invalidPort: return 1005
		case .missingNetworkType: return 1006
		case .unsupportedNetworkType: return 1007
		case .missingSecurityType: return 1008
		case .unsupportedSecurityType: return 1009
		case .missingRequiredParameter: return 1010
		case .missingRealityPublicKey: return 1011
		case .missingSNI: return 1012
		case .invalidFingerprint: return 1013
			
		// 2xxx: Environment & App Group
		case .appGroupNotConfigured: return 2001
		case .appGroupContainerNotFound: return 2002
		case .fileSystemError: return 2003
			
		// 3xxx: Xray Core
		case .xrayCoreStartFailed: return 3001
		case .xrayCoreStopFailed: return 3002
		case .xrayVersionUnavailable: return 3003
		case .xrayPortAllocationFailed: return 3004
		case .xrayShareLinkConversionFailed: return 3005
		case .xrayOperationFailed: return 3006
			
		// 4xxx: GeoData
		case .geoDataContainerUnavailable: return 4001
		case .geoDataDownloadFailed: return 4002
		case .geoDataNetworkError: return 4003
		case .geoDataWriteFailed: return 4004
			
		// 5xxx: Configuration
		case .invalidJSON: return 5001
		case .jsonParsingFailed: return 5002
		case .jsonEncodingFailed: return 5003
		case .stringToDataConversionFailed: return 5004
		case .dataToStringConversionFailed: return 5005
		case .configurationBuildFailed: return 5006
		case .configurationSaveFailed: return 5007
		case .configurationWriteFailed: return 5008
		case .missingOutboundConfiguration: return 5009
		case .invalidNetworkType: return 5010
		case .invalidSecurityType: return 5011
			
		// 6xxx: Tunnel
		case .tunnelStartFailed: return 6001
		case .invalidTunnelConfiguration: return 6002
		case .tunnelConfigurationDecodeFailed: return 6003
		case .socks5TunnelStartFailed: return 6004
			
		// 7xxx: Host Resolution
		case .hostResolutionFailed: return 7001
		}
	}
}
