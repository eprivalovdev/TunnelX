# 🚀 TunnelX

<img src="https://img.shields.io/badge/Platform-iOS%20%7C%20macOS-blue.svg" alt="Platform">
<img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift">
<img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome">

**TunnelX** is a powerful, lightweight Swift framework for building Xray-based VPN tunnels on iOS and macOS. Built on top of NetworkExtension, it provides a type-safe, modern Swift API for creating proxy connections with support for VLESS, VMess, Trojan, and more.

> ⚠️ **Important — NetworkExtension Notice**
>
> TunnelX relies on Apple’s `NetworkExtension` framework to provide VPN functionality.
> Usage of this library **requires special entitlements** and may require **explicit approval from Apple**.
>
> Apps using VPN / Packet Tunnel capabilities may be rejected during App Store review.
> The author of TunnelX is **not responsible** for App Store rejections or entitlement issues.

---

## ✨ Features

- 🎯 **Type-Safe API** — Full Swift type system with compile-time safety
- 🔐 **Multiple Protocols** — VLESS, VMess, Trojan, Shadowsocks, WireGuard
- 🌐 **Transport Options** — WebSocket, gRPC, TCP, KCP, QUIC, HTTP/2, XHTTP
- 🔒 **Security** — TLS, Reality support with fingerprint customization
- ⚡️ **Modern Swift** — Swift Concurrency (async/await), Codable, property wrappers
- 📱 **Network Extension** — Full PacketTunnelProvider integration
- 🗂 **Persistent Settings** — App Group shared storage for main app and extension
- 📊 **Flexible Routing** — Domain and IP-based routing rules
- 🌍 **GeoData Support** — Automatic GeoIP and GeoSite database management
- 📝 **Comprehensive Logging** — Built-in logging with file output
- ⚠️ **Unified Error Handling** — `TunnelXError` with unique error codes
- 🧪 **Testable** — Protocol-based design for easy unit testing

---

## 📦 Requirements

- iOS 16.0+ / macOS 13.0+
- Xcode 15.0+
- Swift 5.9+
- App Groups capability enabled
- Network Extension capability enabled

---

## 🔧 Installation

### Swift Package Manager

Add TunnelX to your project via Xcode:

1. File → Add Package Dependencies...
2. Enter repository URL: `https://github.com/eprivalovdev/TunnelX.git`
3. Select version rule (recommended: "Up to Next Major Version")
4. Add to your target

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/eprivalovdev/TunnelX.git", from: "1.0.0")
]
```

**Alternative options:**

```swift
// Exact version
.package(url: "https://github.com/eprivalovdev/TunnelX.git", exact: "1.0.0")

// Version range
.package(url: "https://github.com/eprivalovdev/TunnelX.git", "1.0.0"..<"2.0.0")

// Latest from branch (not recommended for production)
.package(url: "https://github.com/eprivalovdev/TunnelX.git", branch: "main")
```

---

## 🚀 Quick Start

### Step 1: Configure Capabilities

Enable required capabilities in your project:

**Main App Target:**
- ✅ App Groups
- ✅ Network Extensions

**Network Extension Target:**
- ✅ App Groups  
- ✅ Network Extensions
- ✅ Personal VPN

### Step 2: Configure App Group

**UIKit (AppDelegate):**

```swift
import UIKit
import TunnelX

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure TunnelX on app launch
        Xray.configure(appGroup: "group.com.yourcompany.app")
        
        return true
    }
}
```

**SwiftUI (App):**

```swift
import SwiftUI
import TunnelX

@main
struct MyVPNApp: App {
    
    init() {
        // Configure TunnelX
        Xray.configure(appGroup: "group.com.yourcompany.app")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Step 3: Connect to VPN

```swift
import TunnelX
import NetworkExtension

class VPNManager {
    private let tunnelService = XrayTunnelService()
    private let vpnManager = NEVPNManager.shared()
    
    func connect(shareLink: String) async throws {
        // Load VPN configuration
        try await vpnManager.loadFromPreferences()
        
        // Start tunnel with share link
        let source = XrayConfigBuilder.Source.url(shareLink)
        try tunnelService.start(
            manager: vpnManager,
            source: source
        ) { error in
            if let error = error {
                print("❌ Failed to start tunnel: \(error)")
            } else {
                print("✅ Tunnel started successfully!")
            }
        }
    }
    
    func disconnect() {
        tunnelService.stop(manager: vpnManager)
    }
}
```

### Step 4: Setup Network Extension

Create a `PacketTunnelProvider.swift` in your Network Extension target:

```swift
import NetworkExtension
import TunnelX

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    override func startTunnel(
        options: [String: NSObject]?,
        completionHandler: @escaping (Error?) -> Void
    ) {
        // Configure settings with App Group
        XrayTunnelSettings.configure(appGroup: "group.com.yourcompany.app")
        
        // Configure network settings
        configureNetworkSettings { [weak self] error in
            guard let self else { return }
            
            if let error {
                completionHandler(error)
                return
            }
            
            // Start Xray tunnel
            Task {
                do {
                    try await XrayTunnelProvider.startTunnel(options: options)
                    completionHandler(nil)
                } catch {
                    completionHandler(error)
                }
            }
        }
    }
    
    override func stopTunnel(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {
        XrayTunnelProvider.stopTunnel()
        completionHandler()
    }
    
    private func configureNetworkSettings(
        completion: @escaping (Error?) -> Void
    ) {
        let tunnelAddress = XrayTunnelSettings.tunnelAddress
        let settings = NEPacketTunnelNetworkSettings(
            tunnelRemoteAddress: tunnelAddress
        )
        
        // IPv4 settings
        settings.ipv4Settings = NEIPv4Settings(
            addresses: ["10.231.0.2"],
            subnetMasks: ["255.255.255.255"]
        )
        settings.ipv4Settings?.includedRoutes = [NEIPv4Route.default()]
        
        // IPv6 settings
        settings.ipv6Settings = NEIPv6Settings(
            addresses: ["2001:db8::1"],
            networkPrefixLengths: [64]
        )
        settings.ipv6Settings?.includedRoutes = [NEIPv6Route.default()]
        
        // DNS settings
        settings.dnsSettings = NEDNSSettings(
            servers: ["1.1.1.1", "8.8.8.8"]
        )
        settings.dnsSettings?.matchDomains = [""]
        
        setTunnelNetworkSettings(settings, completionHandler: completion)
    }
}
```

### Step 5: Use it!

```swift
let manager = VPNManager()

// Connect using VLESS share link
let vlessLink = "vless://uuid@server.com:443?type=ws&security=tls&sni=server.com&path=/ws"
try await manager.connect(shareLink: vlessLink)

// Disconnect
manager.disconnect()
```

---

## 📖 Documentation

For detailed documentation, advanced usage, and examples, see [DOCUMENTATION.md](./DOCUMENTATION.md).

**Topics covered:**
- Link Parser
- Configuration Builder
- GeoData Management
- Tunnel Service
- Network Extension
- Settings Management
- Advanced Configurations
- Routing Rules
- DNS Configuration
- Error Handling
- Best Practices

---

## 🏗 Architecture

TunnelX follows a layered architecture:

```
┌─────────────────────────────────────────────┐
│           Your App / UI Layer               │
├─────────────────────────────────────────────┤
│         XrayTunnelService (Facade)          │
├─────────────────────────────────────────────┤
│  XrayConfigBuilder │ XrayConfigurationWriter│
│  GeoDataManager    │ LoopbackAddressResolver│
├─────────────────────────────────────────────┤
│            Network Extension                │
│         (PacketTunnelProvider)              │
├─────────────────────────────────────────────┤
│      XrayTunnelProvider (Static API)        │
├─────────────────────────────────────────────┤
│   XrayCore │ SOCKS5 Tunnel │ LibXray        │
└─────────────────────────────────────────────┘
```

**Key Components:**

- **Xray** — Entry point (`Xray.configure()`)
- **XrayTunnelService** — High-level facade for tunnel operations
- **LinkParser** — Parses and validates proxy share links
- **XrayConfigBuilder** — Builds Xray JSON configurations
- **XrayConfigurationWriter** — Writes configurations to disk
- **GeoDataManager** — Downloads and manages GeoIP/GeoSite databases
- **XrayTunnelSettings** — Persistent settings storage
- **XrayTunnelProvider** — Network Extension integration
- **TunnelXError** — Unified error handling

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Reporting Issues

- Use GitHub Issues to report bugs
- Include code samples and error messages
- Specify iOS/macOS version and device model

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Swift API Design Guidelines
- Add unit tests for new features
- Document public APIs with DocC comments

---

## 🙏 Acknowledgments

- [XTLS Project](https://github.com/XTLS) — Xray core
- [v2fly](https://github.com/v2fly) — GeoIP and GeoSite data
- [Loyalsoldier](https://github.com/Loyalsoldier) — Alternative GeoData sources
- [hev-socks5-tunnel](https://github.com/heiher/hev-socks5-tunnel) — SOCKS5 implementation

---

## 📞 Support

- 💬 Discussions: [GitHub Discussions](https://github.com/eprivalovdev/TunnelX/discussions)
- 🐛 Issues: [GitHub Issues](https://github.com/eprivalovdev/TunnelX/issues)
- 📖 Documentation: [Full Docs](https://eprivalovdev.github.io/TunnelX)

---

Made with ❤️
