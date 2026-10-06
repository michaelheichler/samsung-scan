import Foundation

struct BatchFolderWatcher {
    // Because scanimage renames page001.jpg.part when the page is done.
    static let partialSuffix = ".part"

    let folder: URL
    private var lastSizes: [String: Int] = [:]
    private(set) var delivered: [URL] = []

    init(folder: URL) {
        self.folder = folder
    }

    mutating func finishedPages(processEnded: Bool) -> [URL] {
        let sizes = currentSizes()
        let names = sizes.keys.sorted()
        var finished: [URL] = []
        for (index, name) in names.enumerated() {
            if name.hasSuffix(Self.partialSuffix) || delivered.contains(where: { $0.lastPathComponent == name }) {
                continue
            }
            let size = sizes[name] ?? 0
            let nextPageStarted = index < names.count - 1
            let isStable = size == lastSizes[name]
            let isFinished = size > 0 && (processEnded || (nextPageStarted && isStable))
            guard isFinished else { break }
            finished.append(folder.appending(path: name))
        }
        lastSizes = sizes
        delivered += finished
        return finished
    }

    private func currentSizes() -> [String: Int] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        )) ?? []
        return Dictionary(uniqueKeysWithValues: files.map { file in
            (file.lastPathComponent, (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        })
    }
}
