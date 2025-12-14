# 📖 TunnelX Documentation

Complete guide to using TunnelX framework for building Xray-based VPN tunnels on iOS and macOS.

> **Note:** This documentation provides detailed API references and examples.  
> For quick start and basic setup, see the main [README](README.md).

---

## 📋 Table of Contents

- [Link Parser](#1-link-parser)
- [Configuration Builder](#2-configuration-builder)
- [GeoData Management](#3-geodata-management)
- [Tunnel Service](#4-tunnel-service)
- [Network Extension](#5-network-extension)
- [Settings Management](#6-settings-management)
- [Utilities](#7-utilities)
  - [Loopback Address Resolver](#loopback-address-resolver)
  - [Log Service](#log-service)
- [Advanced Usage](#advanced-usage)
  - [Custom Configurations](#custom-configurations)
  - [Routing Rules](#routing-rules)
  - [DNS Configuration](#dns-configuration)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

---

## 1. Link Parser

Parse and validate proxy share links with type-safe Swift API.

### Basic Usage

```swift
import TunnelX

// Parse a VLESS link
let parser = try LinkParser(
    urlString: "vless://uuid@example.com:443?type=ws&security=tls"
)

// Access parsed components
print("Protocol: \(parser.outboundProtocol.rawValue)")  // "vless"
print("Host: \(parser.host)")                           // "example.com"
print("Port: \(parser.port)")                           // 443
print("Network: \(parser.network.rawValue)")            // "ws"
print("Security: \(parser.security.rawValue)")          // "tls"

// Get specific parameters
if let path = parser.parameter(.path) {
    print("WebSocket path: \(path)")
}

// Build configuration from link
let config = try parser.getConfiguration()
```

### Supported Protocols

- `vless://` — VLESS
- `vmess://` — VMess  
- `trojan://` — Trojan
- `shadowsocks://` — Shadowsocks
- `wireguard://` — WireGuard

### Protocol-Specific Examples

**VLESS with WebSocket + TLS:**

```swift
let link = "vless://uuid@server.com:443?type=ws&security=tls&sni=server.com&path=/ws"
let parser = try LinkParser(urlString: link)
```

**VMess with gRPC:**

```swift
let link = "vmess://base64_encoded_config"
let parser = try LinkParser(urlString: link)
```

**Trojan with Reality:**

```swift
let link = "trojan://password@server.com:443?security=reality&pbk=public_key&fp=chrome"
let parser = try LinkParser(urlString: link)
```

---

## 2. Configuration Builder

Build Xray configurations from various sources with a clean, separated API.

### Basic Building (Separated from Saving)

```swift
let builder = XrayConfigBuilder()

// Build configuration data
let configData = try builder.build(
    from: .url("vless://uuid@server.com:443?type=ws&security=tls")
)

// Save using writer
let writer = XrayConfigurationWriter()
let fileURL = try writer.writeConfiguration(configData, fileName: "config.json")

print("Config saved to: \(fileURL.path)")
```

### Convenience Method (Build + Save)

```swift
let builder = XrayConfigBuilder()

// Build and save in one call
let fileURL = try builder.buildAndSave(
    from: .url("vless://uuid@server.com:443?type=ws&security=tls")
)

print("Config saved to: \(fileURL.path)")
```

### Source Types

```swift
// From share link URL
let source1 = XrayConfigBuilder.Source.url("vless://...")

// From JSON string
let jsonConfig = """
{
    "log": {...},
    "inbounds": [...],
    "outbounds": [...]
}
"""
let source2 = XrayConfigBuilder.Source.json(jsonConfig)

// From Outbound model
let outbound = Outbound(
    protocol: .vless,
    tag: "proxy",
    settings: .vless(VlessOutboundConfigurationObject(
        vnext: [VnextObject(
            address: "server.com",
            port: 443,
            users: [User(id: "uuid")]
        )]
    ))
)
let source3 = XrayConfigBuilder.Source.outbound(outbound)
```

### Build from JSON String

```swift
let builder = XrayConfigBuilder()

let jsonConfig = """
{
    "log": { "loglevel": "debug" },
    "inbounds": [...],
    "outbounds": [...]
}
"""

// Option 1: Build only
let data = try builder.build(from: .json(jsonConfig))

// Option 2: Build and save
let fileURL = try builder.buildAndSave(from: .json(jsonConfig))
```

### Build from Outbound

```swift
let builder = XrayConfigBuilder()

// Create custom outbound
let outbound = Outbound(
    protocol: .vless,
    tag: "proxy",
    settings: .vless(VlessOutboundConfigurationObject(
        vnext: [VnextObject(
            address: "example.com",
            port: 443,
            users: [User(id: "your-uuid")]
        )]
    )),
    streamSettings: StreamSettings(
        network: .ws,
        security: .tls,
        wsSettings: StreamSettings.WS(path: "/ws")
    )
)

// Build and save
let fileURL = try builder.buildAndSave(from: .outbound(outbound))
```

### Working with Configuration Data

```swift
// Get configuration as Data
let configData = try builder.build(from: .url("vless://..."))

// Convert to JSON string
if let jsonString = String(data: configData, encoding: .utf8) {
    print(jsonString)
}

// Or use writer separately
let writer = XrayConfigurationWriter()
let fileURL = try writer.writeConfiguration(configData, fileName: "my-config.json")
```

### SOCKS5 Configuration

```swift
// Build and save SOCKS5 config
let socksURL = try builder.buildAndSaveSocks5Config()

// Or use writer directly
let writer = XrayConfigurationWriter()
let socksURL = try writer.writeSocks5Config(
    address: "::1",
    port: 10808,
    fileName: "socks5.yaml"
)
```

---

## 3. GeoData Management

Automatically download and manage GeoIP and GeoSite databases using `GeoDataManager`.

### Basic Download via TunnelService (Recommended)

```swift
let tunnelService = XrayTunnelService()

// Download GeoData using saved configuration
try await tunnelService.downloadGeoData()
```

### Using GeoDataManager Directly

```swift
// Use default configuration (Loyalsoldier)
let geoDataManager = GeoDataManager(
    appGroup: "group.com.yourcompany.app"
)
try await geoDataManager.downloadAndSaveGeoFiles()

// Use alternative configuration (v2fly)
let geoDataManager = GeoDataManager(
    appGroup: "group.com.yourcompany.app",
    configuration: .v2fly
)
try await geoDataManager.downloadAndSaveGeoFiles()

// Use custom URLs
let customConfig = GeoDataManager.Configuration(
    geoIPURL: URL(string: "https://example.com/geoip.dat")!,
    geoSiteURL: URL(string: "https://example.com/geosite.dat")!
)
let geoDataManager = GeoDataManager(
    appGroup: "group.com.yourcompany.app",
    configuration: customConfig
)
try await geoDataManager.downloadAndSaveGeoFiles()
```

### Available Configurations

**Built-in Configurations:**
- `.default` — Loyalsoldier's GeoIP + v2fly's GeoSite (default)
- `.v2fly` — Official v2fly repositories for both files

**Custom Configuration:**
```swift
let config = GeoDataManager.Configuration(
    geoIPURL: URL(string: "https://example.com/geoip.dat")!,
    geoSiteURL: URL(string: "https://example.com/geosite.dat")!
)
```

### Configure GeoData Sources

```swift
// Set v2fly as default source
XrayTunnelSettings.setGeoDataConfig(.v2fly)

// Or use custom URLs
let customConfig = GeoDataManager.Configuration(
    geoIPURL: URL(string: "https://example.com/geoip.dat")!,
    geoSiteURL: URL(string: "https://example.com/geosite.dat")!
)
XrayTunnelSettings.setGeoDataConfig(customConfig)

// Download will now use saved configuration
let tunnelService = XrayTunnelService()
try await tunnelService.downloadGeoData()
```

### Get GeoData Directory Path

```swift
let geoDataManager = GeoDataManager(appGroup: "group.com.yourcompany.app")
if let geoDataPath = geoDataManager.geoDataDirectoryPath() {
    print("GeoData directory: \(geoDataPath.path)")
}
```

---

## 4. Tunnel Service

High-level facade for managing VPN tunnel lifecycle.

### Basic Usage

```swift
import TunnelX
import NetworkExtension

let tunnelService = XrayTunnelService()
let vpnManager = NEVPNManager.shared()

// Load VPN configuration
try await vpnManager.loadFromPreferences()

// Start tunnel
try tunnelService.start(
    manager: vpnManager,
    source: .url("vless://uuid@server.com:443")
) { error in
    if let error = error {
        print("❌ Tunnel start failed: \(error)")
    } else {
        print("✅ Tunnel started!")
    }
}

// Stop tunnel
tunnelService.stop(manager: vpnManager)
```

### Access Log Files

```swift
let tunnelService = XrayTunnelService()

// Get log file URLs
let logs = tunnelService.logFiles
print("Access log: \(logs.access.path)")
print("Error log: \(logs.error.path)")

// Read log content
if let accessLog = try? String(contentsOf: logs.access) {
    print("Access log content:\n\(accessLog)")
}

// Or use XrayLogService directly
let logService = XrayLogService()
let logFiles = logService.getLogFiles()
```

### Synchronous Start (without completion handler)

```swift
// For use in async contexts
try tunnelService.start(
    manager: vpnManager,
    source: .url("vless://uuid@server.com:443")
)
```

### With GeoData Download

```swift
// Download GeoData before connecting
try await tunnelService.downloadGeoData()

// Then start tunnel
try tunnelService.start(
    manager: vpnManager,
    source: .url("vless://uuid@server.com:443")
)
```

### Connection Status Monitoring

```swift
class VPNStatusMonitor {
    private var statusObserver: NSObjectProtocol?
    
    func startMonitoring(manager: NEVPNManager) {
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: manager.connection,
            queue: .main
        ) { notification in
            guard let connection = notification.object as? NEVPNConnection else { return }
            
            switch connection.status {
            case .connected:
                print("✅ Connected")
            case .connecting:
                print("🔄 Connecting...")
            case .disconnected:
                print("⭕️ Disconnected")
            case .disconnecting:
                print("🔄 Disconnecting...")
            case .reasserting:
                print("🔄 Reasserting...")
            case .invalid:
                print("❌ Invalid")
            @unknown default:
                break
            }
        }
    }
    
    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
```

---

## 5. Network Extension

Implement PacketTunnelProvider for VPN functionality.

### PacketTunnelProvider Implementation

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

---

## 6. Settings Management

Persistent storage for VPN settings using App Group.

### Configure Settings

```swift
// Configure app group (required)
// This should be done at app launch via Xray.configure()
XrayTunnelSettings.configure(appGroup: "group.com.yourcompany.app")
```

### Tunnel Address

```swift
// Get current tunnel address (default: "::1")
let address = XrayTunnelSettings.tunnelAddress

// Set tunnel address
XrayTunnelSettings.setTunnelAddress("127.0.0.1")
```

### DNS Settings

```swift
// Get current DNS settings
let currentDNS = XrayTunnelSettings.dns
print("DNS servers: \(currentDNS.servers)")

// Set DNS configuration
let dns = StorageDNS(
    servers: ["1.1.1.1", "8.8.8.8"],
    strategy: .ipIfNonMatch,
    queryStrategy: .useIPv4
)
XrayTunnelSettings.setDNS(dns)

// Enable/disable DNS logging
XrayTunnelSettings.setDNSLogEnabled(true)
let isDNSLogEnabled = XrayTunnelSettings.dnsLogEnabled
```

### Routing Settings

```swift
// Get current routing settings
let currentRoute = XrayTunnelSettings.route
print("Domain strategy: \(currentRoute.domainStrategy)")

// Set routing configuration
let route = StorageRoute(
    domainStrategy: .ipIfNonMatch,
    rules: [
        StorageRoute.Rule(
            domain: ["geosite:cn"],
            outboundTag: "direct"
        )
    ]
)
XrayTunnelSettings.setRoute(route)
```

### Sniffing Configuration

```swift
// Get current sniffing settings
let currentSniffing = XrayTunnelSettings.sniffing

// Set sniffing configuration
let sniffing = StorageSniffing(
    enabled: true,
    destOverride: ["http", "tls", "quic"],
    metadataOnly: false,
    routeOnly: true
)
XrayTunnelSettings.setSniffing(sniffing)
```

### Logging Configuration

```swift
// Get current log level
let level = XrayTunnelSettings.logLevel
print("Current log level: \(level)")

// Set log level
XrayTunnelSettings.setLogLevel(.warning)
```

### GeoData Configuration

```swift
// Get current GeoData configuration
let currentConfig = XrayTunnelSettings.geoDataConfig

// Set GeoData source (v2fly)
XrayTunnelSettings.setGeoDataConfig(.v2fly)

// Set custom GeoData sources
let customConfig = GeoDataManager.Configuration(
    geoIPURL: URL(string: "https://example.com/geoip.dat")!,
    geoSiteURL: URL(string: "https://example.com/geosite.dat")!
)
XrayTunnelSettings.setGeoDataConfig(customConfig)
```

### Reset to Defaults

```swift
// Reset all settings to default values
XrayTunnelSettings.resetToDefaults()
```

---

## 7. Utilities

### Loopback Address Resolver

Automatically detect which loopback address (IPv4 or IPv6) is reachable for connecting to local proxy.

```swift
import TunnelX

@MainActor
class NetworkSetup {
    func configureLoopbackAddress() async {
        let resolver = LoopbackAddressResolver()
        
        // Resolve best loopback address
        await resolver.resolve(port: 10808) { address in
            print("Detected address: \(address)")
            
            // Set as tunnel address
            XrayTunnelSettings.setTunnelAddress(address)
        }
    }
}
```

**How it works:**
- Tests connectivity to both `127.0.0.1` (IPv4) and `::1` (IPv6)
- Returns the first address that successfully connects
- Falls back to `::1` if neither responds within 1.5 seconds

**Use cases:**
- Systems with IPv6 disabled
- Environments where IPv4 is preferred
- Automatic network configuration

**Important:**
- Must be used from `@MainActor` context
- Default port is `10808` (SOCKS5 proxy port)

### Log Service

Manage Xray log files in the App Group container.

```swift
import TunnelX

let logService = XrayLogService()

// Get log file URLs
let logs = logService.getLogFiles()
print("Error log: \(logs.error.path)")
print("Access log: \(logs.access.path)")

// Read error log
if let errorContent = try? String(contentsOf: logs.error) {
    print("Error log:\n\(errorContent)")
}

// Read access log
if let accessContent = try? String(contentsOf: logs.access) {
    print("Access log:\n\(accessContent)")
}

// Clear log files
try? FileManager.default.removeItem(at: logs.error)
try? FileManager.default.removeItem(at: logs.access)
```

**Log files:**
- `xrayError.log` — Error messages and debug information
- `xrayAccess.log` — Connection and traffic logs

**Location:**
- Stored in App Group container under `tunnelxlogFiles/` directory
- Accessible from both main app and Network Extension

---

## Advanced Usage

### Custom Configurations

Build complex Xray configurations programmatically using `XrayConfiguration`:

```swift
// Create configuration
let config = XrayConfiguration()

// Add logging
config.log(Log(
    loglevel: .debug,
    access: "/path/to/access.log",
    error: "/path/to/error.log"
))

// Add inbound (SOCKS5)
config.inbound(Inbound(
    listen: "127.0.0.1",
    port: 10808,
    protocol: .socks,
    settings: .socks(SocksInboundConfigurationObject(
        auth: .noauth,
        udp: true
    )),
    tag: "socks-in"
))

// Add outbound (VLESS with WebSocket + TLS)
config.outbound(Outbound(
    protocol: .vless,
    tag: "proxy",
    settings: .vless(VlessOutboundConfigurationObject(
        vnext: [VnextObject(
            address: "example.com",
            port: 443,
            users: [User(
                id: "your-uuid",
                flow: .xtls_rprx_vision
            )]
        )]
    )),
    streamSettings: StreamSettings(
        network: .ws,
        security: .tls,
        wsSettings: StreamSettings.WS(
            path: "/websocket",
            host: "example.com"
        ),
        tlsSettings: StreamSettings.TLS(
            serverName: "example.com",
            allowInsecure: false,
            alpn: [.h2, .http1_1],
            fingerprint: .chrome
        )
    )
))

// Add direct outbound
config.outbound(Outbound(
    protocol: .freedom,
    tag: "direct"
))

// Add block outbound
config.outbound(Outbound(
    protocol: .blackhole,
    tag: "block"
))

// Add DNS
config.dns(DNS(
    servers: ["1.1.1.1", "8.8.8.8"],
    queryStrategy: .useIPv4
))

// Add routing
config.routing(Route(
    domainStrategy: .ipIfNonMatch,
    rules: [
        Route.Rule(
            domain: ["geosite:category-ads-all"],
            outboundTag: "block"
        ),
        Route.Rule(
            domain: ["geosite:cn"],
            outboundTag: "direct"
        ),
        Route.Rule(
            ip: ["geoip:cn", "geoip:private"],
            outboundTag: "direct"
        )
    ]
))

// Convert to JSON string
let jsonString = try config.toJSON()
print(jsonString)

// Or build using XrayConfigBuilder
let builder = XrayConfigBuilder()
let outbound = Outbound(
    protocol: .vless,
    tag: "proxy",
    settings: .vless(VlessOutboundConfigurationObject(
        vnext: [VnextObject(
            address: "example.com",
            port: 443,
            users: [User(id: "your-uuid")]
        )]
    ))
)
let configData = try builder.build(from: .outbound(outbound))
```

### Routing Rules

Create sophisticated routing rules to control traffic flow:

```swift
// Create routing configuration
let route = Route(
    domainStrategy: .ipIfNonMatch,
    domainMatcher: .hybrid,
    rules: [
        // Block ads and tracking domains
        Route.Rule(
            domain: [
                "geosite:category-ads-all",
                "domain:doubleclick.net",
                "domain:googleadservices.com"
            ],
            outboundTag: "block"
        ),
        
        // Direct connection for Chinese domains
        Route.Rule(
            domain: [
                "geosite:cn",
                "geosite:geolocation-cn"
            ],
            outboundTag: "direct"
        ),
        
        // Direct connection for private and Chinese IPs
        Route.Rule(
            ip: [
                "geoip:private",
                "geoip:cn"
            ],
            outboundTag: "direct"
        ),
        
        // Direct connection for specific ports (NTP, DNS)
        Route.Rule(
            port: "123,53",
            outboundTag: "direct"
        ),
        
        // Everything else goes through proxy
        Route.Rule(
            outboundTag: "proxy"
        )
    ]
)

// Save routing configuration
XrayTunnelSettings.setRoute(StorageRoute(
    domainStrategy: route.domainStrategy ?? .ipIfNonMatch,
    rules: route.rules.map { rule in
        StorageRoute.Rule(
            domain: rule.domain,
            ip: rule.ip,
            port: rule.port,
            outboundTag: rule.outboundTag ?? "proxy"
        )
    }
))
```

**Domain Matching Patterns:**
- `geosite:category` — Use GeoSite database
- `domain:example.com` — Match exact domain
- `full:example.com` — Match full domain only
- `regexp:.*\.example\.com$` — Regular expression match
- `keyword:example` — Match if domain contains keyword

**IP Matching Patterns:**
- `geoip:cn` — Use GeoIP database for country
- `geoip:private` — Private IP ranges
- `1.2.3.4/24` — CIDR notation
- `1.2.3.4` — Exact IP match

**Domain Strategy Options:**
- `.asIs` — Use domain as-is
- `.ipIfNonMatch` — Resolve to IP if no rule matches (recommended)
- `.ipOnDemand` — Resolve to IP when needed

**Domain Matcher Options:**
- `.hybrid` — Balanced performance (default)
- `.linear` — Simple linear matching

### DNS Configuration

Configure DNS with multiple servers and routing-aware resolution:

```swift
// Create DNS configuration with multiple servers
let dns = DNS(
    servers: [
        // Primary DNS server (for all queries)
        DNSServerObject(
            address: "1.1.1.1",
            port: 53,
            skipFallback: false
        ),
        // China-specific DNS (for Chinese domains)
        DNSServerObject(
            address: "223.5.5.5",
            port: 53,
            domains: ["geosite:cn"],
            expectIPs: ["geoip:cn"]
        ),
        // Local DNS for specific domains
        DNSServerObject(
            address: "localhost",
            skipFallback: true
        )
    ],
    queryStrategy: .useIPv4v6,
    disableCache: false,
    disableFallback: false
)

// Save DNS configuration to settings
XrayTunnelSettings.setDNS(StorageDNS(
    servers: dns.servers.map { $0.address },
    strategy: .ipIfNonMatch,
    queryStrategy: dns.queryStrategy ?? .useIPv4
))

// Or use simple DNS configuration
let simpleDNS = StorageDNS(
    servers: ["1.1.1.1", "8.8.8.8"],
    strategy: .ipIfNonMatch,
    queryStrategy: .useIPv4
)
XrayTunnelSettings.setDNS(simpleDNS)
```

**DNS Query Strategies:**
- `.useIPv4` — Query IPv4 addresses only
- `.useIPv6` — Query IPv6 addresses only  
- `.useIPv4v6` — Query both IPv4 and IPv6 (default)

**DNS Domain Strategies:**
- `.asIs` — Use domain as-is without resolution
- `.ipIfNonMatch` — Resolve to IP if no routing rule matches (recommended)
- `.ipOnDemand` — Resolve to IP when needed

---

## Error Handling

TunnelX uses a unified `TunnelXError` enum for all error cases.

### Basic Error Handling

```swift
import TunnelX

do {
    let parser = try LinkParser(urlString: "invalid-url")
    let config = try parser.getConfiguration()
} catch let error as TunnelXError {
    switch error {
    case .invalidURL(let url):
        print("Invalid URL: \(url)")
        
    case .unsupportedProtocol(let proto):
        print("Unsupported protocol: \(proto)")
        
    case .missingHost:
        print("Host is required")
        
    case .invalidPort(let port):
        print("Invalid port: \(port)")
        
    case .xrayCoreStartFailed(let response):
        print("Xray core failed to start: \(response)")
        
    case .geoDataDownloadFailed(let url, let statusCode):
        print("Failed to download GeoData from \(url): HTTP \(statusCode)")
        
    case .tunnelStartFailed(let underlying):
        print("Tunnel start failed: \(underlying)")
        
    default:
        print("Error: \(error.localizedDescription)")
    }
}
```

### Error Categories

| Code Range | Category | Examples |
|------------|----------|----------|
| 1xxx | URL & Link Parsing | invalidURL, unsupportedProtocol, missingHost |
| 2xxx | Environment & App Group | appGroupNotConfigured, containerNotFound |
| 3xxx | Xray Core | xrayCoreStartFailed, xrayVersionUnavailable |
| 4xxx | GeoData | geoDataDownloadFailed, geoDataNetworkError |
| 5xxx | Configuration | invalidJSON, configurationBuildFailed |
| 6xxx | Tunnel | tunnelStartFailed, invalidTunnelConfiguration |
| 7xxx | Host Resolution | hostResolutionFailed |

### Error Codes Reference

**1xxx - URL & Link Parsing:**
- `1001` — Invalid URL format
- `1002` — Unsupported protocol
- `1003` — Missing host
- `1004` — Invalid port
- `1005` — Missing required parameter
- `1006` — Invalid parameter value
- `1007` — Failed to decode Base64
- `1008` — Invalid VMess JSON

**2xxx - Environment & App Group:**
- `2001` — App Group not configured
- `2002` — Container URL not found
- `2003` — Failed to create directory
- `2004` — File operation failed

**3xxx - Xray Core:**
- `3001` — Failed to start Xray core
- `3002` — Failed to stop Xray core
- `3003` — Xray version unavailable
- `3004` — Xray configuration invalid

**4xxx - GeoData:**
- `4001` — GeoData download failed
- `4002` — GeoData network error
- `4003` — GeoData file not found
- `4004` — GeoData validation failed

**5xxx - Configuration:**
- `5001` — Invalid JSON
- `5002` — Configuration build failed
- `5003` — Missing required field
- `5004` — Failed to encode configuration

**6xxx - Tunnel:**
- `6001` — Tunnel start failed
- `6002` — Tunnel stop failed
- `6003` — Invalid tunnel configuration
- `6004` — Tunnel connection timeout

**7xxx - Host Resolution:**
- `7001` — Host resolution failed
- `7002` — DNS lookup timeout
- `7003` — No route to host

---

## Best Practices

### 1. Always Configure App Group First

```swift
// ❌ Bad - will crash
let service = XrayTunnelService()

// ✅ Good
Xray.configure(appGroup: "group.com.yourcompany.app")
let service = XrayTunnelService()
```

### 2. Download GeoData Before First Connection

```swift
// In your app's first launch or settings screen
if !hasDownloadedGeoData {
    try await tunnelService.downloadGeoData()
    UserDefaults.standard.set(true, forKey: "hasDownloadedGeoData")
}
```

### 3. Handle VPN Manager State Changes

```swift
class VPNStatusObserver {
    private var statusObserver: NSObjectProtocol?
    
    func startObserving(manager: NEVPNManager) {
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: manager.connection,
            queue: .main
        ) { notification in
            guard let connection = notification.object as? NEVPNConnection else { return }
            
            switch connection.status {
            case .connected:
                print("✅ Connected")
            case .connecting:
                print("🔄 Connecting...")
            case .disconnected:
                print("⭕️ Disconnected")
            case .disconnecting:
                print("🔄 Disconnecting...")
            case .reasserting:
                print("🔄 Reasserting...")
            case .invalid:
                print("❌ Invalid")
            @unknown default:
                break
            }
        }
    }
}
```

### 4. Properly Handle Async Operations

```swift
// Use Task for async operations in sync contexts
func connect(shareLink: String) {
    Task {
        do {
            try await tunnelService.start(manager: manager, source: .url(shareLink))
        } catch {
            // Handle error
            await MainActor.run {
                showError(error)
            }
        }
    }
}
```

### 5. Clean Up Resources

```swift
class TunnelManager {
    deinit {
        // Always stop tunnel when manager is deallocated
        XrayTunnelProvider.stopTunnel()
    }
}
```

### 6. Validate Share Links

```swift
func validateAndConnect(shareLink: String) async throws {
    // Validate link first
    guard let parser = try? LinkParser(urlString: shareLink) else {
        throw TunnelXError.invalidURL(shareLink)
    }
    
    // Check protocol is supported
    guard parser.outboundProtocol != .unknown else {
        throw TunnelXError.unsupportedProtocol(shareLink)
    }
    
    // Connect using validated URL
    try await tunnelService.start(
        manager: vpnManager,
        source: .url(shareLink)
    )
}
```

### 7. Handle Network Changes

```swift
class NetworkMonitor {
    private var pathMonitor: NWPathMonitor?
    
    func startMonitoring() {
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("✅ Network available")
            } else {
                print("❌ Network unavailable")
                // Optionally reconnect tunnel
            }
        }
        pathMonitor?.start(queue: .global())
    }
}
```

### 8. Implement Retry Logic

```swift
func connectWithRetry(
    shareLink: String,
    maxRetries: Int = 3
) async throws {
    var lastError: Error?
    
    for attempt in 1...maxRetries {
        do {
            try await tunnelService.start(
                manager: vpnManager,
                source: .url(shareLink)
            )
            return
        } catch {
            lastError = error
            print("Attempt \(attempt) failed: \(error)")
            
            if attempt < maxRetries {
                try await Task.sleep(nanoseconds: UInt64(attempt * 1_000_000_000))
            }
        }
    }
    
    throw lastError ?? TunnelXError.tunnelStartFailed(nil)
}
```

### 9. Use Proper Logging

```swift
// Get log file paths from XrayLogService
let logService = XrayLogService()
let logFiles = logService.getLogFiles()

print("Access log: \(logFiles.access.path)")
print("Error log: \(logFiles.error.path)")

// Set log level
XrayTunnelSettings.setLogLevel(.warning)

// Enable DNS logging
XrayTunnelSettings.setDNSLogEnabled(true)
```

### 10. Test with Different Scenarios

```swift
func runTests() async {
    // Test various protocols
    let testLinks = [
        "vless://uuid@server.com:443?type=ws&security=tls",
        "vmess://base64_config",
        "trojan://password@server.com:443"
    ]
    
    for link in testLinks {
        do {
            let parser = try LinkParser(urlString: link)
            print("✅ Parsed: \(parser.outboundProtocol.rawValue)")
        } catch {
            print("❌ Failed to parse: \(link)")
        }
    }
}
```

---
