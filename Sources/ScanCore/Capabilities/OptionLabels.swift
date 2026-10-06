public enum OptionLabels {
    static let values = [
        "Flatbed": "Flatbed",
        "ADF": "Document Feeder",
        "Auto": "Auto",
        "Color": "Color",
        "Gray": "Grayscale",
        "Lineart": "Black and White",
        "Halftone": "Halftone",
    ]

    static let options = [
        "jpeg": "JPEG Compression",
    ]

    static let unitSymbols: [ScannerOptionUnit: String] = [
        .pixel: "px",
        .bit: "bit",
        .millimeter: "mm",
        .dpi: "dpi",
        .percent: "%",
        .microsecond: "µs",
    ]

    public static func label(forValue value: String) -> String {
        values[value] ?? value
    }

    public static func title(forOption name: String) -> String {
        if let title = options[name] { return title }
        return name.split(separator: "-").map(\.localizedCapitalized).joined(separator: " ")
    }

    public static func symbol(for unit: ScannerOptionUnit) -> String {
        unitSymbols[unit] ?? unit.rawValue
    }
}
