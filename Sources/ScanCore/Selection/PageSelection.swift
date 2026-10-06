import Foundation

public struct PageSelection: Hashable, Sendable {
    public private(set) var ids: Set<UUID> = []
    public private(set) var anchor: UUID?

    public init() {}

    public mutating func select(_ id: UUID) {
        ids = [id]
        anchor = id
    }

    public mutating func toggle(_ id: UUID) {
        if ids.remove(id) == nil {
            ids.insert(id)
        }
        anchor = id
    }

    public mutating func extend(to id: UUID, in order: [UUID]) {
        guard let anchor, let start = order.firstIndex(of: anchor), let end = order.firstIndex(of: id) else {
            return select(id)
        }
        ids = Set(order[min(start, end)...max(start, end)])
    }

    public mutating func step(by offset: Int, in order: [UUID]) {
        guard !order.isEmpty else { return clear() }
        guard let anchor, let index = order.firstIndex(of: anchor) else {
            return select(offset < 0 ? order[order.count - 1] : order[0])
        }
        select(order[min(max(index + offset, 0), order.count - 1)])
    }

    public mutating func clear() {
        ids = []
        anchor = nil
    }
}
