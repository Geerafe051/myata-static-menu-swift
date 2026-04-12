import Foundation

@MainActor
final class ControlPanelViewModel: ObservableObject {
    @Published var configuration = SourceConfiguration()
    @Published var isBusy = false
    @Published var artifacts: [GeneratedArtifact] = []
    @Published var logs = ""
    @Published var lastBuildSummary = "Пока ничего не собрано."

    private let settingsStore = SettingsStore()
    private let buildService = MenuBuildService()

    init() {
        Task {
            await loadConfiguration()
        }
    }

    func loadConfiguration() async {
        do {
            configuration = try await settingsStore.load()
            appendLog("Loaded source configuration.\n")
        } catch {
            appendLog("Failed to load configuration: \(error.localizedDescription)\n")
        }
    }

    func saveConfiguration() async {
        do {
            try await settingsStore.persist(configuration)
            appendLog("Saved source configuration.\n")
        } catch {
            appendLog("Failed to save configuration: \(error.localizedDescription)\n")
        }
    }

    func buildMenu() async {
        guard !isBusy else { return }
        isBusy = true
        appendLog("Starting native Swift build...\n")

        do {
            try await settingsStore.persist(configuration)
            let result = try await buildService.build(using: configuration)
            artifacts = result.artifacts
            lastBuildSummary = "Собрано \(result.menuData.sections.count) категорий и \(result.menuData.items.count) позиций."
            appendLog("Build finished successfully.\n")
        } catch {
            appendLog("Build failed: \(error.localizedDescription)\n")
            lastBuildSummary = "Ошибка сборки"
        }

        isBusy = false
    }

    func markPlannedFeature(_ feature: String) {
        appendLog("\(feature) будет реализован следующим этапом в Swift.\n")
    }

    private func appendLog(_ line: String) {
        logs += "[\(DateFormatter.logTimestamp.string(from: Date()))] \(line)"
    }
}

private extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
