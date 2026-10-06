import UniformTypeIdentifiers

public enum ExportFormat: String, CaseIterable, Identifiable, Sendable {
    case pdf
    case png
    case jpeg

    public var id: Self { self }

    public var name: String {
        switch self {
        case .pdf: "PDF"
        case .png: "PNG"
        case .jpeg: "JPEG"
        }
    }

    public var fileExtension: String {
        switch self {
        case .pdf: "pdf"
        case .png: "png"
        case .jpeg: "jpg"
        }
    }

    public var contentType: UTType {
        switch self {
        case .pdf: .pdf
        case .png: .png
        case .jpeg: .jpeg
        }
    }

    public var writesOneFilePerPage: Bool {
        self != .pdf
    }
}
