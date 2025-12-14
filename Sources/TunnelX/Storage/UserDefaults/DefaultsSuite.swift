import Foundation

enum DefaultsSuite {
	private static var suite: UserDefaults?
	private static var appGroup: String?
	private static var overriddenContainerURL: URL?
	
	static func configure(appGroup: String) {
		self.suite = UserDefaults(suiteName: appGroup)
		self.appGroup = appGroup
	}
	
	static var current: UserDefaults {
		suite ?? .standard
	}
	
	static var currentAppGroup: String {
		appGroup ?? ""
	}
	
	static var containerURL: URL {
		if let override = overriddenContainerURL {
			return override
		}
		
		guard let appGroup else {
			fatalError("❌ DefaultsSuite not configured! Call XrayEnvironmentBootstrapper(appGroup: your.app.group.name) at app start.")
		}
		
		guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
			fatalError("❌ App Group container not found at \(appGroup)")
		}
		
		return url
	}
	
	/// Testing-only helper to bypass container resolution.
	static func configureForTesting(appGroup: String, containerURL: URL) {
		self.appGroup = appGroup
		self.suite = UserDefaults(suiteName: appGroup)
		self.overriddenContainerURL = containerURL
	}
}
