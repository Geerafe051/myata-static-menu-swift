import Foundation

@MainActor
final class ControlPanelViewModel: ObservableObject {
    @Published var configuration = SourceConfiguration()
    @Published var isBusy = false
    @Published var artifacts: [GeneratedArtifact] = []
    @Published var logs = ""
    @Published var lastBuildSummary = "Пока ничего не собрано."
    @Published var lastOperation: OperationResult?

    private let settingsStore = SettingsStore()
    private let buildService = MenuBuildService()
    private let publishService = PublishService()
    private let imageMigrationService = ImageMigrationService()

    init() {
        Task {
            await loadConfiguration()
        }
    }

    func loadConfiguration() async {
        do {
            configuration = try await settingsStore.load()
            appendLog("Loaded source configuration and resolved S3 secrets from Keychain.\n")
        } catch {
            appendLog("Failed to load configuration: \(error.localizedDescription)\n")
        }
    }

    func saveConfiguration() async {
        do {
            try await settingsStore.persist(configuration)
            appendLog("Saved source configuration and stored S3 secrets in Keychain.\n")
        } catch {
            appendLog("Failed to save configuration: \(error.localizedDescription)\n")
        }
    }

    func buildMenu() async {
        await runOperation(.build) { [self] in
            let result = try await self.buildService.build(using: self.configuration)
            self.artifacts = result.artifacts
            self.lastBuildSummary = "Собрано \(result.menuData.sections.count) категорий и \(result.menuData.items.count) позиций."
            self.appendLog("Build finished successfully.\n")
            return self.lastBuildSummary
        }
    }

    func publishMenu() async {
        await runOperation(.publish) { [self] in
            if self.artifacts.isEmpty {
                self.appendLog("No local artifacts found. Running build before publish...\n")
                let buildResult = try await self.buildService.build(using: self.configuration)
                self.artifacts = buildResult.artifacts
                self.lastBuildSummary = "Собрано \(buildResult.menuData.sections.count) категорий и \(buildResult.menuData.items.count) позиций."
            }

            let uploaded = try await self.publishService.publishArtifacts(configuration: self.configuration)
            self.artifacts = uploaded
            let detail = "Опубликовано \(uploaded.count) файлов в bucket."
            self.appendLog("Publish finished successfully.\n")
            return detail
        }
    }

    func refreshMenu() async {
        await runOperation(.refresh) { [self] in
            let buildResult = try await self.buildService.build(using: self.configuration)
            let uploaded = try await self.publishService.publishArtifacts(configuration: self.configuration)
            self.artifacts = uploaded
            let detail = "Собрано \(buildResult.menuData.sections.count) категорий и опубликовано \(uploaded.count) файлов."
            self.lastBuildSummary = detail
            self.appendLog("Refresh finished successfully.\n")
            return detail
        }
    }

    func migrateImages() async {
        await runOperation(.migrateImages) { [self] in
            let manifest = try await self.imageMigrationService.migrateImages(configuration: self.configuration)
            self.appendLog("Image migration finished successfully.\n")
            return "Перенесено \(manifest.migratedCount) изображений. Новый префикс: \(manifest.newPrefix)"
        }
    }

    private func appendLog(_ line: String) {
        logs += "[\(DateFormatter.logTimestamp.string(from: Date()))] \(line)"
    }

    private func runOperation(_ kind: OperationKind, work: @escaping () async throws -> String) async {
        guard !isBusy else { return }
        isBusy = true
        appendLog("Starting \(kind.rawValue)...\n")

        do {
            try await settingsStore.persist(configuration)
            let detail = try await work()
            lastOperation = OperationResult(kind: kind, success: true, details: detail, finishedAt: Date())
        } catch {
            let detail = error.localizedDescription
            appendLog("\(kind.rawValue) failed: \(detail)\n")
            lastOperation = OperationResult(kind: kind, success: false, details: detail, finishedAt: Date())
            if kind == .build || kind == .refresh {
                lastBuildSummary = "Ошибка сборки"
            }
        }

        isBusy = false
    }
}

private extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
