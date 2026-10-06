import SwiftUI

struct AdvancedOptionsSection: View {
    let options: [ScannerOption]
    @Binding var draft: ScanRequest
    @ViewState private var isExpanded = false

    var body: some View {
        Section {
            DisclosureGroup("Advanced", isExpanded: $isExpanded) {
                ForEach(options) { option in
                    AdvancedOptionRow(option: option, draft: $draft)
                }
            }
        }
    }
}
