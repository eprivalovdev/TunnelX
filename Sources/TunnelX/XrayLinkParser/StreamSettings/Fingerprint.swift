import Foundation

// MARK: - TLS Fingerprint

/// Browser fingerprint emulation for TLS connections.
///
/// Mimics TLS handshake characteristics of different browsers to avoid detection.
///
/// - SeeAlso: [Xray uTLS](https://github.com/XTLS/Xray-core/issues/91)
public enum Fingerprint: String, Encodable, Parsable, CaseIterable {
	/// Google Chrome fingerprint (recommended).
	case chrome = "chrome"
	
	/// Mozilla Firefox fingerprint.
	case firefox = "firefox"
	
	/// Safari fingerprint.
	case safari = "safari"
	
	/// iOS Safari fingerprint.
	case ios = "ios"
	
	/// Android Chrome fingerprint.
	case android = "android"
	
	/// Microsoft Edge fingerprint.
	case edge = "edge"
	
	/// 360 Browser fingerprint.
	case _360 = "360"
	
	/// QQ Browser fingerprint.
	case qq = "qq"
	
	/// Random fingerprint from available options.
	case random = "random"
	
	/// Randomized fingerprint on each connection.
	case randomized = "randomized"
	
	// MARK: - Parsable
	
	/// Creates fingerprint from parsed link (defaults to Chrome if not specified).
	public init(_ parser: LinkParser) throws {
		guard let raw = parser.parametersMap["fp"], !raw.isEmpty else {
			self = .chrome
			return
		}
		
		guard let value = Fingerprint(rawValue: raw) else {
			throw TunnelXError.invalidFingerprint(raw)
		}
		
		self = value
	}
}
