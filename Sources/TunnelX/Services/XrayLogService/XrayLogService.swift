import Foundation

/// A service that manages log file paths and directory structure for Xray tunnel operations.
///
/// `XrayLogService` provides centralized management of log files used by the Xray core,
/// including error logs and access logs. It automatically creates the necessary directory
/// structure in the app group container and returns file URLs for log configuration.
///
/// ## Overview
///
/// The service manages two types of log files:
/// - **Error logs** (`xrayError.log`): Contains error messages and debug information
/// - **Access logs** (`xrayAccess.log`): Contains connection and traffic information
///
/// All log files are stored in a dedicated `tunnelxlogFiles` directory within the app group container.
///
/// ## Usage
///
/// ```swift
/// let logService = XrayLogService()
/// let logs = logService.getLogFiles()
///
/// print("Error log: \(logs.error.path)")
/// print("Access log: \(logs.access.path)")
///
/// // Use with XrayConfigBuilder
/// let log = Log(
///     loglevel: .debug,
///     access: logs.access.path,
///     error: logs.error.path
/// )
/// ```
///
/// - Note: The service automatically creates the logs directory if it doesn't exist.
/// - Important: Requires app group configuration via `Xray.configure(appGroup:)` at app launch.
public final class XrayLogService {
	
	/// Represents the available log file types.
	enum LogFile: String {
		/// Error and debug log file
		case error = "xrayError.log"
		/// Access and traffic log file
		case access = "xrayAccess.log"
	}
	
	private let logsDirectoryName = "tunnelxlogFiles"
	
	/// Creates a new instance of the log service.
	///
	/// - Note: No configuration is required during initialization.
	public init() { }
	
	/// Returns the file URLs for error and access log files.
	///
	/// This method ensures that the logs directory exists before returning the file URLs.
	/// If the directory doesn't exist, it will be created automatically.
	///
	/// - Returns: A `LogFiles` structure containing URLs for both error and access log files.
	///
	/// ## Example
	///
	/// ```swift
	/// let service = XrayLogService()
	/// let logs = service.getLogFiles()
	///
	/// // Read error log content
	/// if let content = try? String(contentsOf: logs.error) {
	///     print(content)
	/// }
	/// ```
	///
	/// - Note: The returned URLs point to files that may not exist yet. They will be created
	///         by the Xray core when logging begins.
	public func getLogFiles() -> LogFiles {
		ensureLogsDirectoryExists()
		
		return LogFiles(
			error: fileURL(for: .error),
			access: fileURL(for: .access)
		)
	}
	
	// MARK: - Paths
	private var logsDirectoryURL: URL {
		DefaultsSuite.containerURL
			.appendingPathComponent(logsDirectoryName, isDirectory: true)
	}
	
	private func fileURL(for file: LogFile) -> URL {
		logsDirectoryURL.appendingPathComponent(file.rawValue)
	}
	
	// MARK: - Helpers
	private func ensureLogsDirectoryExists() {
		let fm = FileManager.default
		let url = logsDirectoryURL
		
		if !fm.fileExists(atPath: url.path) {
			try? fm.createDirectory(at: url, withIntermediateDirectories: true)
		}
	}
}
