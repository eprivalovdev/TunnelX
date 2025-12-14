// swift-tools-version: 5.9
import PackageDescription

let package = Package(
	name: "TunnelX",
	platforms: [
		.iOS(.v16),
		.macOS(.v13)
	],
	products: [
		.library(
			name: "TunnelX",
			targets: ["TunnelX"]
		),
	],
	targets: [
		.binaryTarget(
			name: "HevSocks5Tunnel",
			path: "Frameworks/HevSocks5Tunnel.xcframework"
		),
		.binaryTarget(
			name: "LibXray",
			url: "https://github.com/eprivalovdev/LibXray/releases/download/25.10.15/LibXray.xcframework.zip",
			checksum: "3f1384a80e566a43aa1aa5cbe4b448baf82abda6c4ab4cffaaec3a761c6fe07a"
		),
		.target(
			name: "TunnelX",
			dependencies: [
				"HevSocks5Tunnel",
				"LibXray"
			],
			path: "Sources/TunnelX",
			linkerSettings: [
				.linkedLibrary("resolv")
			]
		),
		.testTarget(
			name: "TunnelXTests",
			dependencies: ["TunnelX"],
			path: "Tests/TunnelXTests"
		),
	]
)
