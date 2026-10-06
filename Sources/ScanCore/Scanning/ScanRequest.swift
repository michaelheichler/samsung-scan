import Foundation

public struct ScanRequest: Hashable, Sendable {
    public static let pageFileStem = "page%03d"
    // Because PDFWriter embeds the scanned JPEG data without decoding it.
    static let pageFormat = "jpeg"
    static let pageFileExtension = "jpg"

    public var deviceName: String
    public var source: String
    public var mode: String
    public var resolution: Int
    public var region: ScanRegion
    public var extraOptionValues: [String: String]
    public var pageLimit: Int?

    public init(
        deviceName: String,
        source: String,
        mode: String,
        resolution: Int,
        region: ScanRegion,
        extraOptionValues: [String: String] = [:],
        pageLimit: Int? = nil
    ) {
        self.deviceName = deviceName
        self.source = source
        self.mode = mode
        self.resolution = resolution
        self.region = region
        self.extraOptionValues = extraOptionValues
        self.pageLimit = pageLimit
    }

    public func arguments(batchFolder: URL) -> [String] {
        let pageFile = batchFolder.appending(path: "\(Self.pageFileStem).\(Self.pageFileExtension)")
        var arguments = [
            "--device-name=\(deviceName)",
            "--source=\(source)",
            "--mode=\(mode)",
            "--resolution=\(resolution)",
            "-l", Self.millimeters(region.leftMillimeters),
            "-t", Self.millimeters(region.topMillimeters),
            "-x", Self.millimeters(region.widthMillimeters),
            "-y", Self.millimeters(region.heightMillimeters),
            "--format=\(Self.pageFormat)",
            "--batch=\(pageFile.path(percentEncoded: false))",
        ]
        if let pageLimit {
            arguments.append("--batch-count=\(pageLimit)")
        }
        for (name, value) in extraOptionValues.sorted(by: { $0.key < $1.key }) {
            arguments += name.count == 1 ? ["-\(name)", value] : ["--\(name)=\(value)"]
        }
        return arguments
    }

    // So that a German locale never turns 210.5 into "210,5".
    private static let millimeterStyle = FloatingPointFormatStyle<Double>.number
        .locale(Locale(identifier: "en_US_POSIX"))
        .grouping(.never)
        .precision(.fractionLength(0...3))

    static func millimeters(_ value: Double) -> String {
        value.formatted(millimeterStyle)
    }
}
