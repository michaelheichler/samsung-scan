import CoreTransferable
import Foundation

struct PageDrag: Transferable, Sendable {
    let page: ScannedPage
    let number: Int
    let workFolder: WorkFolder
    let name = ExportFileName(date: .now)

    var fileName: String {
        name.page(number, as: .png)
    }

    // Because the grid reorders through the text form and Finder takes the PNG.
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .png, exporting: stagePNG)
            .suggestedFileName { $0.fileName }
        ProxyRepresentation(exporting: \.page.id.uuidString)
    }

    private static func stagePNG(_ drag: Self) throws -> SentTransferredFile {
        let file = try drag.workFolder.makeExportFolder().appending(path: drag.fileName)
        try PageExporter(format: .png).write(drag.page, to: file)
        return SentTransferredFile(file)
    }
}
