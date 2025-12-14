import Foundation

/// Service responsible for writing Xray configuration files to App Group storage.
public struct XrayConfigurationWriter {
	
	// MARK: - Constants
	
	public enum Constants {
		public static let defaultConfigFileName = "config.json"
		public static let defaultSocks5FileName = "socks5_config.yaml"
	}
	
	// MARK: - Init
	
	public init() {}
	
	// MARK: - Public API
	
	/// Saves JSON configuration data to App Group container.
	/// - Parameters:
	///   - data: JSON configuration data
	///   - fileName: The file name (default: "config.json")
	/// - Returns: URL of the saved file
	/// - Throws: TunnelXError if writing fails
	@discardableResult
	public func writeConfiguration(_ data: Data, fileName: String = Constants.defaultConfigFileName) throws -> URL {
		let containerURL = DefaultsSuite.containerURL
		
		guard FileManager.default.fileExists(atPath: containerURL.path) else {
			throw TunnelXError.appGroupContainerNotFound(containerURL.path)
		}
		
		let fileURL = containerURL.appendingPathComponent(fileName)
		
		guard let jsonString = String(data: data, encoding: .utf8) else {
			throw TunnelXError.dataToStringConversionFailed
		}
		
		do {
			try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
			return fileURL
		} catch {
			throw TunnelXError.configurationWriteFailed(path: fileURL.path, underlying: error)
		}
	}
	
	/// Creates and writes SOCKS5 YAML configuration file.
	/// - Parameters:
	///   - address: SOCKS5 listen address
	///   - port: SOCKS5 listen port (default: 10808)
	///   - fileName: The file name (default: "socks5_config.yaml")
	/// - Returns: URL of the saved file
	/// - Throws: TunnelXError if writing fails
	@discardableResult
	public func writeSocks5Config(
		address: String,
		port: Int = 10808,
		fileName: String = Constants.defaultSocks5FileName
	) throws -> URL {
		let yaml = buildSocks5YAML(address: address, port: port)
		
		let containerURL = DefaultsSuite.containerURL
		let fileURL = containerURL.appendingPathComponent(fileName)
		
		do {
			try yaml.write(to: fileURL, atomically: true, encoding: .utf8)
			return fileURL
		} catch {
			throw TunnelXError.configurationWriteFailed(path: fileURL.path, underlying: error)
		}
	}
	
	// MARK: - Private
	
	private func buildSocks5YAML(address: String, port: Int) -> String {
		"""
		tunnel:
		  mtu: 1360
		
		socks5:
		  port: \(port)
		  address: \(address)
		  udp: 'udp'
		
		misc:
		  task-stack-size: 20480
		  tcp-buffer-size: 4096
		  connect-timeout: 15000
		  read-write-timeout: 120000
		  log-file: stderr
		  log-level: debug
		  limit-nofile: 65535
		  tcp-keepalive: 30s
		  tcp-nodelay: true
		  tcp-fast-open: false
		  retry: 2
		  retry-interval: 1000
		"""
	}
}
