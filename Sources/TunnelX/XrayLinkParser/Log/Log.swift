import Foundation

// MARK: - Log Configuration

/// Logging configuration for Xray core.
///
/// Controls verbosity and output destinations for Xray logs.
///
/// ## Example
/// ```swift
/// let log = Log(
///     loglevel: .warning,
///     access: "/var/log/xray/access.log",
///     error: "/var/log/xray/error.log"
/// )
/// ```
///
/// - SeeAlso: [Xray Log Configuration](https://xtls.github.io/en/config/log)
public struct Log: Encodable {
	
	// MARK: - Properties
	
	/// Log verbosity level.
	public var loglevel: LogLevel
	
	/// Access log file path (optional).
	///
	/// If specified, access logs are written to this file.
	/// Use "" to disable or "stdout"/"stderr" for console output.
	public var access: String?
	
	/// Error log file path (optional).
	///
	/// If specified, error logs are written to this file.
	/// Use "" to disable or "stdout"/"stderr" for console output.
	public var error: String?
	
	/// Enable DNS query logging.
	public var dnsLog: Bool
	
	/// Mask pattern for sensitive addresses in logs.
	///
	/// Example: `"*"` masks all addresses.
	public var maskAddress: String
	
	// MARK: - Initializers
	
	public init(
		loglevel: LogLevel = .info,
		access: String? = nil,
		error: String? = nil,
		dnsLog: Bool = false,
		maskAddress: String = ""
	) {
		self.loglevel = loglevel
		self.access = access
		self.error = error
		self.dnsLog = dnsLog
		self.maskAddress = maskAddress
	}
}

