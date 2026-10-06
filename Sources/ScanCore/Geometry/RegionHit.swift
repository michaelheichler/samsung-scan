public enum RegionHit: Hashable, Sendable {
    case resize(RegionHandle)
    case move
    case draw
}
