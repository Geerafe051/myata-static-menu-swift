import Foundation

enum AppPaths {
    static let appFolderName = "MyataStaticMenuSwift"

    static var applicationSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(appFolderName, isDirectory: true)
    }

    static var settingsFileURL: URL {
        applicationSupportDirectory.appendingPathComponent("SourceConfiguration.json")
    }

    static var distDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("dist", isDirectory: true)
    }
}
