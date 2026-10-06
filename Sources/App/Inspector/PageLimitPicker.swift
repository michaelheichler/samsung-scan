import SwiftUI

struct PageLimitPicker: View {
    static let singlePage = 1

    @Binding var pageLimit: Int?

    var body: some View {
        Picker("Pages", selection: $pageLimit) {
            Text("All").tag(Int?.none)
            Text("\(Self.singlePage)").tag(Int?.some(Self.singlePage))
        }
        .pickerStyle(.segmented)
    }
}
