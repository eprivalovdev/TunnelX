import Foundation

// MARK: - Log Level

/// Logging verbosity level.
///
/// Controls how much information Xray outputs to logs.
///
/// - SeeAlso: [Xray Log Configuration](https://xtls.github.io/en/config/log)
public enum LogLevel: String, Encodable, CaseIterable {
	/// Debug level - very verbose, for development.
	case debug = "debug"
	
	/// Info level - general information (default).
	case info = "info"
	
	/// Warning level - warnings and errors only.
	case warning = "warning"
	
	/// Error level - errors only.
	case error = "error"
	
	/// No logging.
	case none = "none"
}

