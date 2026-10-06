import Foundation

enum DiscoveryConfigChecks {
    static func run() {
        endpointChecks()
        configLineChecks()
        mergeChecks()
        configSearchChecks()
        configDirectoryChecks()
        listedChecks()
    }

    static let header = XeroxConfig.discoveryHeader

    static func scanner(_ host: String = "scanner-one.local", port: Int = 9400, addresses: [String] = []) -> DiscoveredScanner {
        DiscoveredScanner(name: "Scanner One", host: host, port: port, addresses: addresses)
    }

    private static func endpointChecks() {
        let plain = TCPEndpoint(configLine: "tcp 192.0.2.20")
        expect(plain?.host == "192.0.2.20" && plain?.port == 9400, "a tcp line without a port uses port 9400")
        expect(TCPEndpoint(configLine: "tcp scanner-one.local 9500")?.port == 9500, "a tcp line with a port keeps that port")
        expect(TCPEndpoint(configLine: "usb 0x04e8 0x3324") == nil, "a usb line is no network address")
        expect(TCPEndpoint(configLine: "tcp scanner-one.local abc") == nil, "a tcp line with a text port is rejected")
        expect(
            TCPEndpoint(host: "Scanner-One.local.", port: 9400) == TCPEndpoint(host: "scanner-one.local", port: 9400),
            "host names match regardless of case and a trailing dot")
    }

    private static func configLineChecks() {
        expect(scanner().configLine == "tcp scanner-one.local", "a scanner on port 9400 gets a line without a port")
        expect(scanner(port: 9401).configLine == "tcp scanner-one.local 9401", "a scanner on another port gets the port in its line")
        expect(scanner("scanner-one.local.").configLine == "tcp scanner-one.local", "a Bonjour host loses its trailing dot")
    }

    private static func mergeChecks() {
        let system = "# Samsung config\nusb 0x04e8 0x3324\n# tcp 192.0.2.99\n"
        let merged = { (system: String, scanners: [DiscoveredScanner]) in XeroxConfig.merged(system: system, discovered: scanners) }
        expect(merged(system, [scanner()]) == system + header + "\ntcp scanner-one.local\n", "a found scanner is added below the unchanged system file")
        expect(merged("", [scanner()]) == header + "\ntcp scanner-one.local\n", "without a system file only the found scanner is listed")
        expect(merged("usb 0x04e8 0x3324", [scanner()]) == "usb 0x04e8 0x3324\n" + header + "\ntcp scanner-one.local\n", "the header starts its own line after a file without a final newline")
        let byAddress = "tcp 192.0.2.20\n"
        expect(merged(byAddress, [scanner(addresses: ["192.0.2.20"])]) == byAddress, "a scanner the system file lists by address is not added again")
        let byName = "tcp Scanner-One.local.\n"
        expect(merged(byName, [scanner()]) == byName, "a scanner the system file lists by name is not added again")
        let otherPort = "tcp 192.0.2.20 9401\n"
        expect(merged(otherPort, [scanner(addresses: ["192.0.2.20"])]) == otherPort + header + "\ntcp scanner-one.local\n", "the same address on another port is a different scanner")
        let twice = [scanner(addresses: ["192.0.2.20"]), scanner(addresses: ["192.0.2.21"])]
        expect(merged("", twice) == header + "\ntcp scanner-one.local\n", "two reports of one host give one line")
        expect(merged(system, []) == system, "a scanner that left Bonjour loses its line on the next write")
        let commented = "#tcp 192.0.2.20\n"
        expect(merged(commented, [scanner(addresses: ["192.0.2.20"])]) == commented + header + "\ntcp scanner-one.local\n", "a commented-out tcp line does not hide a found scanner")
    }

    private static func configSearchChecks() {
        let debug = "[12:00:00.000000] [sanei_config] sanei_config_get_paths: using config directories  /tmp/app/sane.d:.:/opt/example/sane.d"
        expect(SaneConfigSearch.directories(inDebugOutput: "x\n" + debug + "\n") == ["/tmp/app/sane.d", ".", "/opt/example/sane.d"], "the SANE debug line gives the config search path")
        expect(SaneConfigSearch.directories(inDebugOutput: "scanimage (sane-backends) 1.4.0\n") == nil, "output without the debug line gives no search path")
        expect(SaneConfigSearch.directories(inDebugOutput: "sanei_config_get_paths: using config directories  \n") == nil, "a debug line without directories gives no search path")
        let empty = TemporaryFolder.make()
        let first = TemporaryFolder.make()
        let second = TemporaryFolder.make()
        for folder in [first, second] {
            try! "tcp 192.0.2.20\n".write(to: folder.appending(path: "xerox_mfp.conf"), atomically: true, encoding: .utf8)
        }
        let paths = [empty, first, second].map { $0.path(percentEncoded: false) }
        let found = SaneConfigSearch.firstFile(named: "xerox_mfp.conf", in: paths)
        expect(found?.deletingLastPathComponent().standardizedFileURL == first.standardizedFileURL, "the first folder that holds the file wins")
    }

    private static func configDirectoryChecks() {
        let folder = TemporaryFolder.make().appending(path: "sane.d")
        let directory = SaneConfigDirectory(url: folder)
        expect(directory.searchPath == folder.path(percentEncoded: false) + ":", "the search path ends with a colon so SANE adds its defaults")
        try? directory.writeXeroxConfig("tcp 192.0.2.20\n")
        let written = try? String(contentsOf: folder.appending(path: "xerox_mfp.conf"), encoding: .utf8)
        expect(written == "tcp 192.0.2.20\n", "the config folder is created and holds the written xerox_mfp.conf")
    }

    private static func listed(_ name: String, _ scanner: DiscoveredScanner) -> Bool {
        scanner.isListed(in: [ScannerDevice(name: name, model: "Test scanner")])
    }

    private static func listedChecks() {
        let byAddress = scanner(addresses: ["192.0.2.20"])
        expect(listed("xerox_mfp:tcp 192.0.2.20", byAddress), "a device at the scanner address is that scanner")
        expect(listed("xerox_mfp:tcp scanner-one.local", scanner()), "a device at the scanner host name is that scanner")
        expect(!listed("xerox_mfp:tcp scanner-one.local 9401", scanner()), "a device on another port is a different scanner")
        expect(!listed("pixma:04A91234", byAddress), "a device of another backend never matches")
        expect(!listed("xerox_fax:tcp 192.0.2.20", byAddress), "a device of another backend at the same address is not the scanner")
    }
}
