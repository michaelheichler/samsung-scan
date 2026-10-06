public enum RegionHandle: CaseIterable, Hashable, Sendable {
    case topLeft
    case topRight
    case bottomRight
    case bottomLeft
    case top
    case right
    case bottom
    case left

    public var unitX: Double {
        switch self {
        case .topLeft, .left, .bottomLeft: 0
        case .top, .bottom: 0.5
        case .topRight, .right, .bottomRight: 1
        }
    }

    public var unitY: Double {
        switch self {
        case .topLeft, .top, .topRight: 0
        case .left, .right: 0.5
        case .bottomLeft, .bottom, .bottomRight: 1
        }
    }
}
