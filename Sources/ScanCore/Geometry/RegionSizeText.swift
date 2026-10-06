import Foundation

public enum RegionSizeText {
    // Because only the US system measures paper in inches. UK paper uses mm.
    public static func string(for region: ScanRegion, locale: Locale) -> String {
        let usesInches = locale.measurementSystem == .us
        let unit: UnitLength = usesInches ? .inches : .millimeters
        let number = FloatingPointFormatStyle<Double>.number
            .locale(locale)
            .precision(.fractionLength(usesInches ? 0...2 : 0...0))
        let style = Measurement<UnitLength>.FormatStyle(
            width: .abbreviated, locale: locale, usage: .asProvided, numberFormatStyle: number)
        let width = Measurement(value: region.widthMillimeters, unit: UnitLength.millimeters).converted(to: unit)
        let height = Measurement(value: region.heightMillimeters, unit: UnitLength.millimeters).converted(to: unit)
        return "\(width.value.formatted(number)) × \(height.formatted(style))"
    }
}
