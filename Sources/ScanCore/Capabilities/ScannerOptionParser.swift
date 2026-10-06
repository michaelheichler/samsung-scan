import Foundation

public enum ScannerOptionParser {
    private static let booleanMarker = "[=(yes|no)]"
    private static let stepPrefix = " (in steps of "
    private static let inactiveMarker = "inactive"
    private static let advancedMarker = "advanced"
    private static let descriptionIndent = 8

    public static func parse(_ output: String) -> [ScannerOption] {
        var options: [ScannerOption] = []
        var group = ""
        var describing = false
        for line in output.split(whereSeparator: \.isNewline) {
            let indent = line.prefix(while: \.isWhitespace).count
            let text = line.trimmingCharacters(in: .whitespaces)
            if describing, indent >= descriptionIndent {
                let last = options.count - 1
                options[last].description += options[last].description.isEmpty ? text : " " + text
                continue
            }
            describing = false
            if text.hasPrefix("-"), let option = option(from: text, group: group) {
                options.append(option)
                describing = true
            } else if indent > 0, text.hasSuffix(":") {
                group = String(text.dropLast())
            }
        }
        return options
    }

    private static func option(from text: String, group: String) -> ScannerOption? {
        var rest = text.drop { $0 == "-" }
        let name = rest.prefix { $0 != " " && $0 != "[" }
        guard !name.isEmpty else { return nil }
        rest = rest.dropFirst(name.count)
        let isBoolean = rest.hasPrefix(booleanMarker)
        if isBoolean {
            rest = rest.dropFirst(booleanMarker.count)
        }
        let tags = trailingTags(of: &rest)
        let (value, unit) = isBoolean ? (.boolean, nil) : constraint(rest.trimmingCharacters(in: .whitespaces))
        return ScannerOption(
            name: String(name),
            group: group,
            description: "",
            value: value,
            unit: unit,
            currentValue: tags.first { $0 != inactiveMarker && $0 != advancedMarker },
            isInactive: tags.contains(inactiveMarker),
            isAdvanced: tags.contains(advancedMarker)
        )
    }

    private static func trailingTags(of text: inout Substring) -> [String] {
        var tags: [String] = []
        while text.hasSuffix("]"), let open = text.range(of: " [", options: .backwards) {
            tags.insert(String(text[open.upperBound..<text.index(before: text.endIndex)]), at: 0)
            text = text[..<open.lowerBound]
        }
        return tags
    }

    private static func constraint(_ text: String) -> (ScannerOptionValue, ScannerOptionUnit?) {
        let (body, step) = splitStep(text)
        if let range = range(body, step: step) {
            return range
        }
        if body.isEmpty || body.hasPrefix("<") {
            return (.unconstrained(body), nil)
        }
        return list(body)
    }

    private static func splitStep(_ text: String) -> (String, Double?) {
        guard text.hasSuffix(")"), let open = text.range(of: stepPrefix, options: .backwards) else {
            return (text, nil)
        }
        let step = Double(text[open.upperBound..<text.index(before: text.endIndex)])
        return (String(text[..<open.lowerBound]), step)
    }

    private static func range(_ text: String, step: Double?) -> (ScannerOptionValue, ScannerOptionUnit?)? {
        let bounds = text.split(separator: "..", omittingEmptySubsequences: false)
        guard bounds.count == 2 else { return nil }
        let (upper, unit) = splitUnit(bounds[1])
        guard let min = Double(bounds[0]), let max = Double(upper) else { return nil }
        return (.range(min: min, max: max, step: step), unit)
    }

    private static func list(_ text: String) -> (ScannerOptionValue, ScannerOptionUnit?) {
        let (body, unit) = splitUnit(Substring(text))
        let items = body.split(separator: "|")
        let numbers = items.compactMap { Double($0) }
        if !numbers.isEmpty, numbers.count == items.count {
            return (.numbers(numbers), unit)
        }
        return (.strings(text.split(separator: "|").map(String.init)), nil)
    }

    private static func splitUnit(_ text: Substring) -> (Substring, ScannerOptionUnit?) {
        guard let unit = ScannerOptionUnit.allCases.first(where: { text.hasSuffix($0.rawValue) }) else {
            return (text, nil)
        }
        return (text.dropLast(unit.rawValue.count), unit)
    }
}
