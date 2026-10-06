import SwiftUI

extension RegionHit {
    var pointerStyle: PointerStyle {
        switch self {
        case .resize(let handle): .frameResize(position: handle.framePosition)
        case .move: .grabIdle
        case .draw: .rectSelection
        }
    }
}

private extension RegionHandle {
    var framePosition: FrameResizePosition {
        switch self {
        case .topLeft: .topLeading
        case .topRight: .topTrailing
        case .bottomRight: .bottomTrailing
        case .bottomLeft: .bottomLeading
        case .top: .top
        case .right: .trailing
        case .bottom: .bottom
        case .left: .leading
        }
    }
}
