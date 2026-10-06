import SwiftUI

struct FlatbedStage: View {
    static let padding = 20.0
    private static let handleHitRadius = 9.0
    private static let dragThreshold = 2.0
    private static let minimumSideMillimeters = 5.0
    private static let nudgeMillimeters = (small: 1.0, large: 10.0)
    private static let arrowKeys: Set<KeyEquivalent> = [.upArrow, .downArrow, .leftArrow, .rightArrow]

    let area: ScanArea
    let region: ScanRegion
    let isCustom: Bool
    let picture: PreviewPicture?
    let isBusy: Bool
    let commit: @MainActor (ScanRegion) -> Void
    let clear: @MainActor () -> Void
    let preview: @MainActor () -> Void

    @GestureState private var liveRegion: ScanRegion?
    @ViewState private var hover = RegionHit.draw
    @FocusState private var isFocused: Bool
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var customRegion: ScanRegion? { isCustom ? region : nil }

    private var showsPrompt: Bool { picture == nil && !isBusy }

    var body: some View {
        GeometryReader { proxy in
            // Because drawing and the drag gesture must share one mapping.
            let bounds = CGRect(origin: .zero, size: proxy.size).insetBy(dx: Self.padding, dy: Self.padding)
            let mapping = CanvasMapping(area: area, bounds: bounds)
            let shown = liveRegion ?? region
            ZStack {
                GlassSurface(mapping: mapping, picture: picture)
                SelectionOverlay(mapping: mapping, region: shown, isEditable: isCustom || liveRegion != nil, dimsOutside: true)
                    .animation(reduceMotion ? nil : .snappy, value: region)
                    .accessibilityElement()
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel(isCustom ? "Custom scan region" : "Paper size outline")
                    .accessibilityValue(RegionSizeText.string(for: region, locale: locale))
                    .accessibilityHint("Drag on the glass to choose the area. Arrow keys move it.")
                    .accessibilityAction(named: "Clear Custom Region", clear)
                if let liveRegion {
                    RegionSizeLabel(
                        text: RegionSizeText.string(for: liveRegion, locale: locale),
                        selection: mapping.rect(for: liveRegion),
                        bounds: proxy.size)
                }
                EmptyGlassPrompt(preview: preview)
                    .frame(maxWidth: mapping.glass.width)
                    .position(x: mapping.glass.midX, y: mapping.glass.midY)
                    .opacity(showsPrompt ? 1 : 0)
                    .allowsHitTesting(showsPrompt)
                    .accessibilityHidden(!showsPrompt)
            }
            .contentShape(.rect)
            .gesture(drag(in: mapping))
            .onContinuousHover { phase in track(phase, in: mapping) }
            .pointerStyle(hover.pointerStyle)
        }
        .focusable(!isBusy)
        .focused($isFocused)
        .onKeyPress(keys: Self.arrowKeys, action: nudge)
        .onKeyPress(.escape, action: clearCustomRegion)
        .disabled(isBusy)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Scanner glass")
    }

    private func drag(in mapping: CanvasMapping) -> some Gesture {
        DragGesture(minimumDistance: Self.dragThreshold)
            .updating($liveRegion) { value, state, _ in
                state = dragged(value, in: mapping)
            }
            .onEnded { value in
                finishDrag(value, in: mapping)
            }
    }

    private func dragged(_ value: DragGesture.Value, in mapping: CanvasMapping) -> ScanRegion {
        let hit = mapping.hit(value.startLocation, on: customRegion, radius: Self.handleHitRadius)
        return mapping.region(
            dragging: hit, of: region, from: value.startLocation, to: value.location,
            minimumSide: Self.minimumSideMillimeters)
    }

    private func finishDrag(_ value: DragGesture.Value, in mapping: CanvasMapping) {
        isFocused = true
        let next = dragged(value, in: mapping)
        guard next.isAtLeast(Self.minimumSideMillimeters), next != region else { return }
        commit(next)
    }

    private func track(_ phase: HoverPhase, in mapping: CanvasMapping) {
        let next = switch phase {
        case .active(let location): mapping.hit(location, on: customRegion, radius: Self.handleHitRadius)
        case .ended: RegionHit.draw
        }
        if next != hover { hover = next }
    }

    private func nudge(_ press: KeyPress) -> KeyPress.Result {
        let step = press.modifiers.contains(.shift) ? Self.nudgeMillimeters.large : Self.nudgeMillimeters.small
        let offset: (dx: Double, dy: Double) = switch press.key {
        case .leftArrow: (-step, 0)
        case .rightArrow: (step, 0)
        case .upArrow: (0, -step)
        default: (0, step)
        }
        let next = region.moved(dx: offset.dx, dy: offset.dy, within: area)
        if next != region { commit(next) }
        return .handled
    }

    private func clearCustomRegion() -> KeyPress.Result {
        guard isCustom else { return .ignored }
        clear()
        return .handled
    }
}
