import Foundation

/// Manages downloading and storage of GeoIP and GeoSite databases
public final class GeoDataManager {
	
	// MARK: - Configuration
	
	/// Configuration for GeoData sources
	public struct Configuration: Codable, Equatable {
		public let geoIPURL: URL
		public let geoSiteURL: URL
		
		public init(geoIPURL: URL, geoSiteURL: URL) {
			self.geoIPURL = geoIPURL
			self.geoSiteURL = geoSiteURL
		}
		
		/// Default configuration using Loyalsoldier repositories
		public static let `default` = Configuration(
			geoIPURL: URL(string: "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat")!,
			geoSiteURL: URL(string: "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat")!
		)
		
		/// Alternative configuration using v2fly repositories
		public static let v2fly = Configuration(
			geoIPURL: URL(string: "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat")!,
			geoSiteURL: URL(string: "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat")!
		)
	}
	
	// MARK: - Properties
	
	private let appGroup: String
	private let configuration: Configuration
	
	// MARK: - Init
	
	/// Initialize GeoData fetcher
	/// - Parameters:
	///   - appGroup: App Group identifier for storage
	///   - configuration: Source URLs for GeoData files (default: Loyalsoldier)
	public init(appGroup: String, configuration: Configuration = .default) {
		self.appGroup = appGroup
		self.configuration = configuration
	}
	
	// MARK: - Public API
	
	/// Get the directory path where GeoData is stored
	/// - Returns: URL to GeoData directory, or nil if App Group is unavailable
	public func geoDataDirectoryPath() -> URL? {
		guard let containerURL = FileManager.default.containerURL(
			forSecurityApplicationGroupIdentifier: appGroup
		) else {
			return nil
		}
		return containerURL.appendingPathComponent("GeoData", isDirectory: true)
	}
	
	/// Download and save GeoIP and GeoSite files
	/// - Throws: TunnelXError if download or save fails
	public func downloadAndSaveGeoFiles() async throws {
		let files: [(url: URL, name: String)] = [
			(configuration.geoIPURL, "geoip.dat"),
			(configuration.geoSiteURL, "geosite.dat")
		]
		
		guard let saveDirectory = geoDataDirectoryPath() else {
			throw TunnelXError.geoDataContainerUnavailable
		}
		
		// Create directory if needed
		try createDirectoryIfNeeded(at: saveDirectory)
		
		// Download files sequentially
		try await downloadFiles(files, to: saveDirectory)
	}
	
	// MARK: - Private
	
	/// Creates directory at specified path if it doesn't exist
	private func createDirectoryIfNeeded(at url: URL) throws {
		do {
			try FileManager.default.createDirectory(
				at: url,
				withIntermediateDirectories: true
			)
		} catch {
			throw TunnelXError.configurationSaveFailed(
				path: url.path,
				underlying: error
			)
		}
	}
	
	/// Downloads multiple files to specified directory
	private func downloadFiles(_ files: [(url: URL, name: String)], to directory: URL) async throws {
		for file in files {
			try await downloadFile(
				from: file.url,
				to: directory.appendingPathComponent(file.name)
			)
		}
	}
	
	private func downloadFile(from url: URL, to destination: URL) async throws {
		do {
			let (data, response) = try await URLSession.shared.data(from: url)
			
			guard let httpResponse = response as? HTTPURLResponse else {
				throw TunnelXError.geoDataNetworkError(
					url: url,
					underlying: NSError(domain: "Invalid response", code: -1)
				)
			}
			
			guard httpResponse.statusCode == 200 else {
				throw TunnelXError.geoDataDownloadFailed(
					url: url,
					statusCode: httpResponse.statusCode
				)
			}
			
			do {
				try data.write(to: destination)
			} catch {
				throw TunnelXError.geoDataWriteFailed(
					path: destination.path,
					underlying: error
				)
			}
		} catch let error as TunnelXError {
			throw error
		} catch {
			throw TunnelXError.geoDataNetworkError(url: url, underlying: error)
		}
	}
}
