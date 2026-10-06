import Foundation

enum DiscoveryRunnerChecks {
    static func run() async {
        await runConcurrently([
            foundScannerReachesScanimage,
            missingSearchPathKeepsSystemConfig,
        ])
    }

    private static let listing = """
        case "$1" in
            -V) [ -e "$state/system" ] && printf '[12:00:00.000000] [sanei_config] sanei_config_get_paths: using config directories  %s:.\\n' "$state/system" >&2 ;;
            -L) echo "device \\`xerox_mfp:test ${SANE_CONFIG_DIR:-unset}' is a Test scanner" ;;
        esac
        """

    static func foundScannerReachesScanimage() async {
        let scan = FakeScan()
        let system = scan.folder.appending(path: "system")
        try! FileManager.default.createDirectory(at: system, withIntermediateDirectories: true)
        try! "tcp 192.0.2.30\n".write(to: system.appending(path: "xerox_mfp.conf"), atomically: true, encoding: .utf8)
        let config = scan.folder.appending(path: "config")
        let runner = scan.runner(listing, configDirectory: SaneConfigDirectory(url: config))
        let devices = (try? await runner.listDevices(discovered: [DiscoveryConfigChecks.scanner(addresses: ["192.0.2.40"])])) ?? []
        let written = try? String(contentsOf: config.appending(path: "xerox_mfp.conf"), encoding: .utf8)
        let expected = "tcp 192.0.2.30\n" + DiscoveryConfigChecks.header + "\ntcp scanner-one.local\n"
        expect(devices.map(\.name) == ["xerox_mfp:test " + config.path(percentEncoded: false) + ":"], "scanimage reads the app config folder first")
        expect(written == expected, "the app config keeps the system scanner and adds the found one")
    }

    static func missingSearchPathKeepsSystemConfig() async {
        let scan = FakeScan()
        let config = scan.folder.appending(path: "config")
        let runner = scan.runner(listing, configDirectory: SaneConfigDirectory(url: config))
        let devices = (try? await runner.listDevices(discovered: [DiscoveryConfigChecks.scanner()])) ?? []
        expect(devices.map(\.name) == ["xerox_mfp:test unset"], "without a SANE search path scanimage keeps the system config")
        expect(!scan.exists("config/xerox_mfp.conf"), "without a SANE search path the app writes no config")
    }
}
