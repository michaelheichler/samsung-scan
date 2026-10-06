import Foundation

@main
struct ScanCoreChecks {
    static func main() async {
        CapabilitiesChecks.run()
        PaperCatalogChecks.run()
        PaperMatchingChecks.run()
        PageFormatChecks.run()
        PageSelectionChecks.run()
        OptionLabelsChecks.run()
        CapabilityChoicesChecks.run()
        ScanRegionPaperChecks.run()
        ExtraOptionValueChecks.run()
        CanvasMappingChecks.run()
        RegionHitChecks.run()
        RegionEditingChecks.run()
        RegionSizeTextChecks.run()
        ScanProgressReaderChecks.run()
        ScanProgressChecks.run()
        ScanRequestChecks.run()
        ScanImageErrorChecks.run()
        ScanImageLocatorChecks.run()
        BatchFolderWatcherChecks.run()
        PDFWriterChecks.run()
        PageExtentChecks.run()
        PageExporterChecks.run()
        PDFLayoutChecks.run()
        DiscoveryConfigChecks.run()
        LanguageModelAvailabilityChecks.run()
        DocumentFieldSchemaChecks.run()
        DocumentFactsSummaryChecks.run()
        deviceListReadsNameAndModel()
        deviceListIgnoresUnrelatedLines()
        await runConcurrently([
            ScanImageRunnerChecks.run, ScanCancelChecks.run, ScannerQueryChecks.run, ScanEventChecks.run,
            ExportCancelChecks.run, DiscoveryRunnerChecks.run, ModelInputCutChecks.run,
            TextRecognizerChecks.run, PageTextRecognitionChecks.run, VisionFactsChecks.run,
            DocumentFactReaderChecks.run, DocumentFactsTrackerChecks.run,
        ])
        exit(CheckLog.passed ? 0 : 1)
    }

    static func deviceListReadsNameAndModel() {
        let devices = DeviceList.parse(
            "device `xerox_mfp:tcp 192.0.2.10' is a Samsung C48x Series multi-function peripheral\n")
        expect(devices.map(\.name) == ["xerox_mfp:tcp 192.0.2.10"], "device list reads the SANE name")
        expect(devices.first?.model == "Samsung C48x Series multi-function peripheral", "device list reads the model")
    }

    static func deviceListIgnoresUnrelatedLines() {
        let output = "\nNo scanners were identified. If you were expecting something different,\n"
        expect(DeviceList.parse(output).isEmpty, "device list ignores lines without a device")
    }
}
