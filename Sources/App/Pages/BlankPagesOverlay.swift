import SwiftUI

struct BlankPagesOverlay: View {
    private static let edgeInset = 12.0
    private static let fadeDuration = 0.2
    // So that the floating bar never covers the last row of tiles.
    static let reservedHeight = BlankPagesBar.height + 2 * edgeInset

    let session: ScanSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var count: Int {
        session.blankPages.count
    }

    private var fade: Animation? {
        reduceMotion ? nil : .easeOut(duration: Self.fadeDuration)
    }

    var body: some View {
        ZStack {
            if count > 0 {
                BlankPagesBar(count: count, canRemove: session.canEditPages, remove: session.removeBlankPages)
                    .padding(Self.edgeInset)
                    .transition(.opacity)
            }
        }
        .animation(fade, value: count > 0)
    }
}
