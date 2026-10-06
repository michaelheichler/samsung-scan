public struct DiscoveredScanner: Identifiable, Hashable, Sendable {
    static let xeroxDevicePrefix = "xerox_mfp:"

    public let name: String
    public let host: String
    public let port: Int
    public let addresses: [String]

    public init(name: String, host: String, port: Int, addresses: [String] = []) {
        self.name = name
        self.host = host.hasSuffix(".") ? String(host.dropLast()) : host
        self.port = port
        self.addresses = addresses.sorted()
    }

    public var id: String { "\(host):\(port)" }

    // So that the device name stays short for the port the backend assumes.
    var configLine: String {
        let base = "\(TCPEndpoint.keyword) \(host)"
        return port == TCPEndpoint.xeroxDefaultPort ? base : "\(base) \(port)"
    }

    var endpoints: Set<TCPEndpoint> {
        Set(([host] + addresses).map { TCPEndpoint(host: $0, port: port) })
    }

    public func isListed(in devices: [ScannerDevice]) -> Bool {
        devices.contains { device in
            guard device.name.hasPrefix(Self.xeroxDevicePrefix),
                  let endpoint = TCPEndpoint(configLine: device.name.dropFirst(Self.xeroxDevicePrefix.count))
            else { return false }
            return endpoints.contains(endpoint)
        }
    }
}
