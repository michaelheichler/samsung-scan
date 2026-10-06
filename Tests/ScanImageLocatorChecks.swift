import Foundation

enum ScanImageLocatorChecks {
    static func run() {
        firstPathFolderWins()
        fileWithoutExecutePermissionIsSkipped()
    }

    private static func path(_ url: URL) -> String {
        url.path(percentEncoded: false)
    }

    static func firstPathFolderWins() {
        let first = TemporaryFolder.make()
        let second = TemporaryFolder.make()
        let wanted = FakeScanImage.write("#!/bin/sh\n", in: first)
        _ = FakeScanImage.write("#!/bin/sh\n", in: second)
        let found = ScanImageLocator.locate(searchPath: "\(path(first)):\(path(second))")
        expect(found?.standardizedFileURL == wanted.standardizedFileURL, "the locator takes scanimage from the first PATH folder")
    }

    static func fileWithoutExecutePermissionIsSkipped() {
        let folder = TemporaryFolder.make()
        let plain = folder.appending(path: "scanimage")
        try! "#!/bin/sh\n".write(to: plain, atomically: true, encoding: .utf8)
        try! FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: path(plain))
        let found = ScanImageLocator.locate(searchPath: path(folder))
        expect(found?.standardizedFileURL != plain.standardizedFileURL, "the locator skips a scanimage without execute permission")
    }
}
