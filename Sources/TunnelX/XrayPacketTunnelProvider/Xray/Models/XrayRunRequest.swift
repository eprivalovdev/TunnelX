public struct XrayRunRequest: Codable {
	public let datDir: String
	public let configPath: String
	
	public enum CodingKeys: String, CodingKey {
		case datDir = "datDir"
		case configPath = "configPath"
	}
}
