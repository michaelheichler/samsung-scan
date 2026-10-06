import Network

public actor ScannerBrowser {
    public static let serviceType = "_scanner._tcp"
    static let resolveTimeout: Duration = .seconds(5)

    private let resolver = BonjourResolver()
    private var resolved: [Bonjour.Endpoint.ID: DiscoveredScanner] = [:]
    private var reported: [DiscoveredScanner]?

    public init() {}

    public nonisolated func scanners() -> AsyncStream<[DiscoveredScanner]> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: [DiscoveredScanner].self, bufferingPolicy: .bufferingNewest(1))
        let task = Task {
            try? await NetworkBrowser(for: .bonjour(Self.serviceType)).run { endpoints in
                if let changed = await self.update(endpoints) { continuation.yield(changed) }
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }

    private func update(_ endpoints: [Bonjour.Endpoint]) async -> [DiscoveredScanner]? {
        let current = Set(endpoints.map(\.id))
        resolved = resolved.filter { current.contains($0.key) }
        for endpoint in endpoints where resolved[endpoint.id] == nil {
            resolved[endpoint.id] = await resolver.resolve(
                name: endpoint.name, type: endpoint.type, domain: endpoint.domain, timeout: Self.resolveTimeout)
        }
        let scanners = Set(resolved.values).sorted { ($0.name, $0.id) < ($1.name, $1.id) }
        guard scanners != reported else { return nil }
        reported = scanners
        return scanners
    }
}
