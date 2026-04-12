import Foundation

actor SettingsStore {
    func load() async throws -> SourceConfiguration {
        try ensureDirectories()

        let fileURL = AppPaths.settingsFileURL
        guard FileManager.default.fileExists(atPath: fileURL.path()) else {
            let initial = SourceConfiguration()
            try save(initial)
            return initial
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(SourceConfiguration.self, from: data)
    }

    func persist(_ configuration: SourceConfiguration) async throws {
        try ensureDirectories()
        try save(configuration)
    }

    private func save(_ configuration: SourceConfiguration) throws {
        let data = try JSONEncoder().encode(configuration)
        try data.write(to: AppPaths.settingsFileURL, options: .atomic)
    }

    private func ensureDirectories() throws {
        try FileManager.default.createDirectory(at: AppPaths.applicationSupportDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: AppPaths.distDirectory, withIntermediateDirectories: true)
    }
}
