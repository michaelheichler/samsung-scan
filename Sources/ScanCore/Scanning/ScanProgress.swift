public struct ScanProgress: Equatable, Sendable {
    // So that the first noisy seconds of a page never produce an estimate.
    public static let estimateThreshold = 0.05

    public private(set) var page = 1
    public private(set) var pagesSoFar = 0
    public private(set) var fraction: Double?
    public private(set) var remaining: Duration?
    public var isStalled = false
    private var startFraction = 0.0
    private var startInstant: ContinuousClock.Instant?

    public init() {}

    public mutating func record(page: Int, fraction: Double, at instant: ContinuousClock.Instant) {
        guard page >= self.page else { return }
        if page != self.page || startInstant == nil {
            self.page = page
            startFraction = fraction
            startInstant = instant
        }
        self.fraction = fraction
        isStalled = false
        remaining = startInstant.flatMap { start in
            Self.estimate(fraction: fraction, startFraction: startFraction, elapsed: instant - start)
        }
    }

    public mutating func pageDelivered() {
        pagesSoFar += 1
        isStalled = false
        guard pagesSoFar >= page else { return }
        page = pagesSoFar + 1
        fraction = nil
        remaining = nil
        startInstant = nil
    }

    static func estimate(fraction: Double, startFraction: Double, elapsed: Duration) -> Duration? {
        let done = fraction - startFraction
        guard fraction >= estimateThreshold, done > 0 else { return nil }
        return elapsed * ((1 - fraction) / done)
    }
}
