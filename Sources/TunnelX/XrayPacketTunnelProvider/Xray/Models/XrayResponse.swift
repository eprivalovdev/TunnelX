import Foundation

public struct XrayResponse<T: Decodable>: Decodable {
	public let success: Bool
	public let data: T?
	
	public init(base64String: String) throws {
		let plainStr = base64String.fromBase64() ?? ""
		let selfCopy = try JSONDecoder().decode(XrayResponse<T>.self, from: plainStr.data(using: .utf8) ?? Data())
		success = selfCopy.success
		data = selfCopy.data
	}
}

public struct XrayPortsResponseBody: Codable {
	public let ports: [Int]
}

public typealias XrayPortsResponse = XrayResponse<XrayPortsResponseBody>
public typealias XrayVersionResponse = XrayResponse<String>
public typealias XrayBoolResponse = XrayResponse<Bool>
