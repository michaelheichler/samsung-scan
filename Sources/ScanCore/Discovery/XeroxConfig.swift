public enum XeroxConfig {
    public static let fileName = "xerox_mfp.conf"
    static let discoveryHeader = "# Samsung Scan found these scanners through Bonjour."

    // Because SANE reads only the first xerox_mfp.conf it finds.
    public static func merged(system: String, discovered: [DiscoveredScanner]) -> String {
        var known = Set(system.split(whereSeparator: \.isNewline).compactMap(TCPEndpoint.init(configLine:)))
        var added: [String] = []
        for scanner in discovered where known.isDisjoint(with: scanner.endpoints) {
            known.formUnion(scanner.endpoints)
            added.append(scanner.configLine)
        }
        guard !added.isEmpty else { return system }
        let base = system.isEmpty || system.hasSuffix("\n") ? system : system + "\n"
        return base + ([discoveryHeader] + added).joined(separator: "\n") + "\n"
    }
}
