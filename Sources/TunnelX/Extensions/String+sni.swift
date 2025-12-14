import Foundation

extension String {
	/// Extracts Server Name Indication (SNI) from the parser.
	///
	/// If the SNI parameter is explicitly provided, it will be used.
	/// Otherwise, the host will be used as the default SNI.
	///
	/// - Parameter parser: The link parser to extract SNI from
	/// - Returns: The SNI value
	/// - Throws: `TunnelXError` if SNI is explicitly provided but empty
	static func sni(_ parser: LinkParser) throws -> String {
		if let value = parser.parameter(.sni) {
			guard !value.isEmpty else {
				throw TunnelXError.missingSNI
			}
			return value
		} else {
			return parser.host
		}
	}
}
