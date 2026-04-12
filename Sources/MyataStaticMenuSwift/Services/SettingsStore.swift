import Foundation

actor SettingsStore {
    private let keychainStore = KeychainStore()

    func load() async throws -> SourceConfiguration {
        try ensureDirectories()

        let fileURL = AppPaths.settingsFileURL
        guard FileManager.default.fileExists(atPath: fileURL.path()) else {
            let initial = SourceConfiguration()
            try save(initial)
            return initial
        }

        let data = try Data(contentsOf: fileURL)
        var configuration = try JSONDecoder().decode(SourceConfiguration.self, from: data)
        let legacySecrets = extractLegacySecrets(from: data)
        let keychainSecrets = try await keychainStore.loadSecrets()

        configuration.accessKeyID = keychainSecrets.accessKeyID
        configuration.secretAccessKey = keychainSecrets.secretAccessKey

        if configuration.accessKeyID.isEmpty, let legacyAccessKey = legacySecrets.accessKeyID {
            configuration.accessKeyID = legacyAccessKey
        }

        if configuration.secretAccessKey.isEmpty, let legacySecret = legacySecrets.secretAccessKey {
            configuration.secretAccessKey = legacySecret
        }

        if !configuration.accessKeyID.isEmpty || !configuration.secretAccessKey.isEmpty {
            try await keychainStore.saveSecrets(accessKeyID: configuration.accessKeyID, secretAccessKey: configuration.secretAccessKey)
            try save(configuration)
        }

        return configuration
    }

    func persist(_ configuration: SourceConfiguration) async throws {
        try ensureDirectories()
        try await keychainStore.saveSecrets(accessKeyID: configuration.accessKeyID, secretAccessKey: configuration.secretAccessKey)
        try save(configuration)
    }

    private func save(_ configuration: SourceConfiguration) throws {
        let data = try JSONEncoder().encode(configuration)
        try data.write(to: AppPaths.settingsFileURL, options: .atomic)
    }

    private func extractLegacySecrets(from data: Data) -> (accessKeyID: String?, secretAccessKey: String?) {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return (nil, nil)
        }

        return (
            object["accessKeyID"] as? String,
            object["secretAccessKey"] as? String
        )
    }

    private func ensureDirectories() throws {
        try FileManager.default.createDirectory(at: AppPaths.applicationSupportDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: AppPaths.distDirectory, withIntermediateDirectories: true)
    }
}
