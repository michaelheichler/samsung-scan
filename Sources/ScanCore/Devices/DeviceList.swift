import Foundation

public enum DeviceList {
    public static func parse(_ output: String) -> [ScannerDevice] {
        output.split(whereSeparator: \.isNewline).compactMap { line in
            guard let open = line.firstIndex(of: "`"),
                  let close = line[line.index(after: open)...].firstIndex(of: "'")
            else { return nil }
            let name = String(line[line.index(after: open)..<close])
            var model = line[line.index(after: close)...].trimmingCharacters(in: .whitespaces)
            if model.hasPrefix("is a ") {
                model.removeFirst("is a ".count)
            }
            return ScannerDevice(name: name, model: model)
        }
    }
}
