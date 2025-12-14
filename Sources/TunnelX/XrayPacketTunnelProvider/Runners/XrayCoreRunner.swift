import Foundation

/// Abstraction for running Xray core to simplify testing.
protocol XrayCoreRunner {
	func run(dataDir: String, configPath: String) throws
	func stop() throws
}

struct DefaultXrayCoreRunner: XrayCoreRunner {
	private let helper: XrayHelper
	
	init(helper: XrayHelper = XrayHelper()) {
		self.helper = helper
	}
	
	func run(dataDir: String, configPath: String) throws {
		try helper.run(dataDir: dataDir, configPath: configPath)
	}
	
	func stop() throws {
		try helper.stop()
	}
}
