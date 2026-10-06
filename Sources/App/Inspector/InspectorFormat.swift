import Foundation

enum InspectorFormat {
    static let millimeterNumber = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...1))

    static func dimensions(of region: ScanRegion) -> String {
        let width = region.widthMillimeters.formatted(millimeterNumber)
        let height = Measurement(value: region.heightMillimeters, unit: UnitLength.millimeters)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: millimeterNumber))
        return "\(width) × \(height)"
    }

    static func pixels(_ size: (width: Int, height: Int)) -> String {
        "\(size.width.formatted()) × \(size.height.formatted()) px"
    }

    static func dpi(_ value: Int) -> String {
        "\(value) dpi"
    }

    static func optionValue(_ number: Double, unit: ScannerOptionUnit?) -> String {
        switch unit {
        case nil: number.formatted()
        case .percent: (number / 100).formatted(.percent)
        case let unit?: "\(number.formatted()) \(OptionLabels.symbol(for: unit))"
        }
    }

    static func optionValue(_ text: String, unit: ScannerOptionUnit?) -> String {
        Double(text).map { optionValue($0, unit: unit) } ?? text
    }
}
