import SwiftUI

struct ShellView: View {
    static let defaultWidth = 1200.0
    static let defaultHeight = 780.0
    static let minimumWidth = 900.0
    static let minimumHeight = 560.0
    static let sidebarWidths = (min: 200.0, ideal: 230.0, max: 320.0)
    // Because a plain minWidth frame on the detail loops split view constraints.
    static let detailWidths = (min: 380.0, ideal: 640.0)
    static let inspectorWidths = (min: 260.0, ideal: 300.0, max: 420.0)

    @Bindable var session: ScanSession
    @ViewState private var showsInspector = true
    @ViewState private var isExporting = false

    var body: some View {
        NavigationSplitView {
            ScannerSidebar(session: session)
                .navigationSplitViewColumnWidth(
                    min: Self.sidebarWidths.min, ideal: Self.sidebarWidths.ideal, max: Self.sidebarWidths.max)
        } detail: {
            DetailArea(session: session)
                .navigationSplitViewColumnWidth(min: Self.detailWidths.min, ideal: Self.detailWidths.ideal)
                .inspector(isPresented: $showsInspector) {
                    ScanSettingsInspector(session: session)
                        .inspectorColumnWidth(
                            min: Self.inspectorWidths.min,
                            ideal: Self.inspectorWidths.ideal,
                            max: Self.inspectorWidths.max)
                }
                .toolbar {
                    ShellToolbar(session: session, showsInspector: $showsInspector, isExporting: $isExporting)
                }
                .sheet(isPresented: $isExporting) {
                    ExportSheet(session: session)
                }
        }
        .frame(minWidth: Self.minimumWidth, minHeight: Self.minimumHeight)
    }
}
