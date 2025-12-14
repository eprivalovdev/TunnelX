import Foundation
import LibXray

/// Protocol abstraction over LibXray static functions to enable testing.
protocol XrayLibrary {
	func getFreePorts(_ count: Int32) -> String
	func run(_ base64Config: String) -> String
	func stop() -> String
	func version() -> String
	func shareLinkToJson(_ base64Url: String) -> String
}

struct DefaultXrayLibrary: XrayLibrary {
	init() {}
	
	func getFreePorts(_ count: Int32) -> String { LibXrayGetFreePorts(Int(count)) }
	func run(_ base64Config: String) -> String { LibXrayRunXray(base64Config) }
	func stop() -> String { LibXrayStopXray() }
	func version() -> String { LibXrayXrayVersion() }
	func shareLinkToJson(_ base64Url: String) -> String { LibXrayConvertShareLinksToXrayJson(base64Url) }
}

/// Thin wrapper around LibXray to expose a testable API.
public final class XrayHelper {
	private let lib: XrayLibrary
	
	public init() {
		self.lib = DefaultXrayLibrary()
	}
	
	internal init(lib: XrayLibrary) {
		self.lib = lib
	}
	
	/// Allocates the specified number of free ports.
	public func getFreePorts(_ count: Int) throws -> [Int] {
		let base64JsonResponse = lib.getFreePorts(Int32(count))
		let portsResponse = try XrayPortsResponse(base64String: base64JsonResponse)
		
		if let ports = portsResponse.data?.ports {
			return ports
		} else {
			throw TunnelXError.xrayPortAllocationFailed(response: base64JsonResponse.fromBase64() ?? base64JsonResponse)
		}
	}
	
	/// Runs Xray with the specified configuration.
	public func run(dataDir: String, configPath: String) throws {
		let jsonRequest = try JSONEncoder().encode(XrayRunRequest(datDir: dataDir, configPath: configPath))
		let base64JsonResponse = lib.run(jsonRequest.base64EncodedString())
		let runResponse = try XrayBoolResponse(base64String: base64JsonResponse)
		
		if !runResponse.success {
			throw TunnelXError.xrayCoreStartFailed(response: base64JsonResponse.fromBase64() ?? base64JsonResponse)
		}
	}
	
	/// Stops the running Xray instance.
	public func stop() throws {
		let base64JsonResponse = lib.stop()
		let runResponse = try XrayBoolResponse(base64String: base64JsonResponse)
		
		if !runResponse.success {
			throw TunnelXError.xrayCoreStopFailed(response: base64JsonResponse.fromBase64() ?? base64JsonResponse)
		}
	}
	
	/// Gets the current Xray version.
	public func xrayVersion() throws -> String {
		let base64JsonResponse = lib.version()
		let runResponse = try XrayVersionResponse(base64String: base64JsonResponse)
		
		guard let version = runResponse.data else {
			throw TunnelXError.xrayVersionUnavailable
		}
		
		if !runResponse.success {
			throw TunnelXError.xrayOperationFailed(response: base64JsonResponse.fromBase64() ?? base64JsonResponse)
		}
		
		return version
	}
	
	/// Converts an Xray share link URL to JSON configuration.
	public func xrayShareLinkToJson(url: String) throws -> String {
		let base64JsonResponse = lib.shareLinkToJson(Data(url.utf8).base64EncodedString())
		
		guard
			let jsonResponse = base64JsonResponse.fromBase64(),
			let respData = jsonResponse.data(using: .utf8)
		else {
			throw TunnelXError.xrayShareLinkConversionFailed(response: base64JsonResponse.fromBase64() ?? base64JsonResponse)
		}
		
		guard let json = try JSONSerialization.jsonObject(with: respData, options: []) as? [String: Any] else {
			throw TunnelXError.xrayShareLinkConversionFailed(response: base64JsonResponse.fromBase64() ?? base64JsonResponse)
		}
		
		guard (json["success"] as? Bool) == true else {
			throw TunnelXError.xrayShareLinkConversionFailed(response: base64JsonResponse.fromBase64() ?? base64JsonResponse)
		}
		
		guard let nestedObj = json["data"] as? Dictionary<String, Any> else {
			throw TunnelXError.xrayShareLinkConversionFailed(response: base64JsonResponse.fromBase64() ?? base64JsonResponse)
		}
		
		guard
			let dt = try? JSONSerialization.data(withJSONObject: nestedObj),
			let str = String(data: dt, encoding: .utf8)
		else {
			throw TunnelXError.xrayShareLinkConversionFailed(response: base64JsonResponse.fromBase64() ?? base64JsonResponse)
		}
		
		return str
	}
}
