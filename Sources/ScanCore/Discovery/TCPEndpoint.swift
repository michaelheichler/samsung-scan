struct TCPEndpoint: Hashable, Sendable {
    static let xeroxDefaultPort = 9400
    static let keyword = "tcp"

    let host: String
    let port: Int

    // So that "Scanner.local." and "scanner.local" count as one host.
    init(host: String, port: Int) {
        var normalized = host.lowercased()
        if normalized.hasSuffix(".") { normalized.removeLast() }
        self.host = normalized
        self.port = port
    }

    init?(configLine line: some StringProtocol) {
        let words = line.split(whereSeparator: \.isWhitespace)
        guard words.count >= 2, words[0] == Self.keyword else { return nil }
        let port = words.count > 2 ? Int(words[2]) : Self.xeroxDefaultPort
        guard let port else { return nil }
        self.init(host: String(words[1]), port: port)
    }
}
