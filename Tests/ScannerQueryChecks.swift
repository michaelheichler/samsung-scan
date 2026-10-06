import Foundation

enum ScannerQueryChecks {
    static func run() async {
        await runConcurrently([
            deviceListComesFromStandardOutput,
            capabilitiesComeFromOptionListing,
            capabilitiesForModeAskForThatMode,
            busyScannerFailsDeviceListAfterThreeAttempts,
        ])
    }

    static func deviceListComesFromStandardOutput() async {
        let runner = FakeScan().runner("""
            echo "device \\`xerox_mfp:tcp 192.0.2.10' is a Samsung C48x Series multi-function peripheral"
            """)
        let devices = (try? await runner.listDevices()) ?? []
        expect(devices.map(\.name) == ["xerox_mfp:tcp 192.0.2.10"], "listDevices reads the device name from scanimage")
        expect(devices.map(\.model) == ["Samsung C48x Series multi-function peripheral"], "listDevices reads the model from scanimage")
    }

    static func capabilitiesComeFromOptionListing() async {
        let scan = FakeScan()
        let runner = scan.runner("""
            printf '%s\\n' "$@" > "$state/arguments"
            cat '\(fixtureURL("c48x-flatbed").path(percentEncoded: false))'
            """)
        let capabilities = try? await runner.capabilities(device: "xerox_mfp:tcp 192.0.2.10", source: "Flatbed")
        let expected = ScannerCapabilities(options: ScannerOptionParser.parse(fixture("c48x-flatbed")))
        expect(capabilities == expected, "capabilities match the parsed option listing")
        expect(
            scan.lines(of: "arguments") == ["--device-name=xerox_mfp:tcp 192.0.2.10", "--source=Flatbed", "-A"],
            "capabilities ask scanimage for the options of one device and source")
    }

    static func capabilitiesForModeAskForThatMode() async {
        let scan = FakeScan()
        let runner = scan.runner("""
            printf '%s\\n' "$@" > "$state/arguments"
            """)
        _ = try? await runner.capabilities(device: "xerox_mfp:tcp 192.0.2.10", source: "Flatbed", mode: "Lineart")
        expect(
            scan.lines(of: "arguments") == ["--device-name=xerox_mfp:tcp 192.0.2.10", "--source=Flatbed", "--mode=Lineart", "-A"],
            "capabilities for a mode ask scanimage for the options in that mode")
    }

    static func busyScannerFailsDeviceListAfterThreeAttempts() async {
        let runner = FakeScan().runner("""
            echo "scanimage: open of device xerox_mfp:tcp 192.0.2.10 failed: Invalid argument" >&2
            exit 1
            """)
        let error = await caughtError { _ = try await runner.listDevices() }
        expect(error as? ScanImageError == .scannerBusy(attempts: 3), "listDevices on a scanner that stays busy gives up after 3 attempts")
    }
}
