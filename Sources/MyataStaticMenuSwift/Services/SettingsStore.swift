import Foundation

actor SettingsStore {
    private let keychainStore = KeychainStore()

    private struct StoredSecrets: Codable {
        var accessKeyID: String
        var secretAccessKey: String
    }

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
        configuration = try await hydratedConfiguration(from: configuration, rawData: data)

        if !configuration.accessKeyID.isEmpty || !configuration.secretAccessKey.isEmpty {
            try await keychainStore.saveSecrets(accessKeyID: configuration.accessKeyID, secretAccessKey: configuration.secretAccessKey)
            try saveFallbackSecrets(accessKeyID: configuration.accessKeyID, secretAccessKey: configuration.secretAccessKey)
            try save(configuration)
        }

        return configuration
    }

    func resolveSecrets(for configuration: SourceConfiguration) async throws -> SourceConfiguration {
        try ensureDirectories()
        let rawData = try? Data(contentsOf: AppPaths.settingsFileURL)
        return try await hydratedConfiguration(from: configuration, rawData: rawData)
    }

    func persist(_ configuration: SourceConfiguration) async throws {
        try ensureDirectories()
        let configurationToSave = try await resolveSecrets(for: configuration)
        try await keychainStore.saveSecrets(accessKeyID: configurationToSave.accessKeyID, secretAccessKey: configurationToSave.secretAccessKey)
        try saveFallbackSecrets(accessKeyID: configurationToSave.accessKeyID, secretAccessKey: configurationToSave.secretAccessKey)
        try save(configurationToSave)
    }

    private func save(_ configuration: SourceConfiguration) throws {
        let data = try JSONEncoder().encode(configuration)
        try data.write(to: AppPaths.settingsFileURL, options: .atomic)
    }

    private func loadFallbackSecrets() throws -> StoredSecrets? {
        let url = AppPaths.secretsFileURL
        guard FileManager.default.fileExists(atPath: url.path()) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(StoredSecrets.self, from: data)
    }

    private func saveFallbackSecrets(accessKeyID: String, secretAccessKey: String) throws {
        try ensureDirectories()

        let url = AppPaths.secretsFileURL
        let data = try JSONEncoder().encode(StoredSecrets(accessKeyID: accessKeyID, secretAccessKey: secretAccessKey))
        try data.write(to: url)

        let permissions = [FileAttributeKey.posixPermissions: 0o600]
        try? FileManager.default.setAttributes(permissions, ofItemAtPath: url.path())
    }

    private func hydratedConfiguration(from configuration: SourceConfiguration, rawData: Data?) async throws -> SourceConfiguration {
        var resolved = configuration
        let legacySecrets: (accessKeyID: String?, secretAccessKey: String?) = rawData.map(extractLegacySecrets) ?? (nil, nil)
        let keychainSecrets = try await keychainStore.loadSecrets()
        let fallbackSecrets = try loadFallbackSecrets()

        if resolved.accessKeyID.isEmpty {
            resolved.accessKeyID = !keychainSecrets.accessKeyID.isEmpty ? keychainSecrets.accessKeyID : (fallbackSecrets?.accessKeyID ?? "")
        }

        if resolved.secretAccessKey.isEmpty {
            resolved.secretAccessKey = !keychainSecrets.secretAccessKey.isEmpty ? keychainSecrets.secretAccessKey : (fallbackSecrets?.secretAccessKey ?? "")
        }

        if resolved.accessKeyID.isEmpty, let legacyAccessKey = legacySecrets.accessKeyID {
            resolved.accessKeyID = legacyAccessKey
        }

        if resolved.secretAccessKey.isEmpty, let legacySecret = legacySecrets.secretAccessKey {
            resolved.secretAccessKey = legacySecret
        }

        return resolved
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
