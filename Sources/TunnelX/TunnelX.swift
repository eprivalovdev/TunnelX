// The Swift Programming Language
// https://docs.swift.org/swift-book

@_exported import NetworkExtension

/// TunnelX - Swift Xray Tunnel Framework
///
/// A lightweight Xray client library for iOS and macOS.
///
/// ## Quick Start
///
/// ```swift
/// // 1. Bootstrap environment
/// let bootstrapper = XrayEnvironmentBootstrapper(appGroup: "group.com.app")
/// bootstrapper.configureAndBootstrap()
///
/// // 2. Start tunnel
/// let service = XrayTunnelService()
/// try service.start(manager: vpnManager, source: .url("vless://..."))
/// ```
public enum TunnelX {
	/// Current library version
	public static let version = "1.0.0"
	
	/// Minimum iOS version required
	public static let minimumIOSVersion = "16.0"
	
	/// Minimum macOS version required
	public static let minimumMacOSVersion = "13.0"
}
