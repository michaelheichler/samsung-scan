public enum ResolutionHint: String, CaseIterable, Sendable {
    case draft = "Draft"
    case document = "Document"
    case photo = "Photo"

    static let documentStart = 200
    static let photoStart = 600

    public init(dpi: Int) {
        switch dpi {
        case ..<Self.documentStart: self = .draft
        case ..<Self.photoStart: self = .document
        default: self = .photo
        }
    }

    public var title: String { rawValue }

    public func choices(in resolutions: [Int]) -> [Int] {
        resolutions.filter { Self(dpi: $0) == self }
    }
}
