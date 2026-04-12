import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var viewModel: ControlPanelViewModel

    var body: some View {
        VStack(spacing: 16) {
            header
            HStack(alignment: .top, spacing: 16) {
                actionsPanel
                sourcePanel
            }
            filesPanel
            logsPanel
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.06, blue: 0.08), Color(red: 0.08, green: 0.10, blue: 0.13)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Myata Static Menu Swift")
                .font(.system(size: 34, weight: .bold))
            Text("Нативное macOS приложение для сборки меню из Google Sheets. Текущий этап: локальная Swift-сборка HTML, JSON и Yandex YML.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var actionsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Действия")
                .font(.title3.weight(.semibold))

            Button {
                Task { await viewModel.buildMenu() }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Refresh Menu")
                        .font(.title3.weight(.bold))
                    Text("Скачать данные из Google Sheets и локально собрать index.html, menu.json и yandex-menu.yml")
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isBusy)

            HStack(spacing: 10) {
                smallActionButton(title: "Publish", description: "Нативная публикация в S3 будет следующим этапом.") {
                    viewModel.markPlannedFeature("Publish")
                }
                smallActionButton(title: "Migrate Images", description: "Нативный перенос картинок будет следующим этапом.") {
                    viewModel.markPlannedFeature("Migrate Images")
                }
            }

            Text(viewModel.lastBuildSummary)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var sourcePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Источник Данных")
                .font(.title3.weight(.semibold))

            labeledField("Google Sheet ID", text: $viewModel.configuration.googleSheetID)
            HStack(spacing: 10) {
                labeledField("Settings GID", text: $viewModel.configuration.settingsGID)
                labeledField("Categories GID", text: $viewModel.configuration.categoriesGID)
            }
            labeledField("Items GID", text: $viewModel.configuration.itemsGID)
            labeledField("Bucket", text: $viewModel.configuration.bucket)
            HStack(spacing: 10) {
                labeledField("Prefix", text: $viewModel.configuration.prefix)
                labeledField("Yandex Vendor", text: $viewModel.configuration.yandexVendor)
            }
            labeledField("Public Menu URL", text: $viewModel.configuration.publicMenuURL)

            Button("Сохранить настройки") {
                Task { await viewModel.saveConfiguration() }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var filesPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Собранные Файлы")
                .font(.title3.weight(.semibold))

            if viewModel.artifacts.isEmpty {
                Text("Файлы появятся после первой сборки.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.artifacts) { artifact in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(artifact.name)
                            .font(.headline)
                        Text(artifact.path)
                            .font(.caption)
                            .textSelection(.enabled)
                        Text("Обновлён: \(artifact.updatedAt.formatted(date: .abbreviated, time: .standard))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var logsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Логи")
                .font(.title3.weight(.semibold))

            ScrollView {
                Text(viewModel.logs.isEmpty ? "Логов пока нет." : viewModel.logs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .font(.system(.body, design: .monospaced))
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
            .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func smallActionButton(title: String, description: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.isBusy)
        .help(description)
    }

    private func labeledField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: ControlPanelViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Настройки")
                .font(.title2.weight(.bold))
            Text("Основные параметры источника данных редактируются прямо в главном окне приложения.")
                .foregroundStyle(.secondary)
            Button("Сохранить текущую конфигурацию") {
                Task { await viewModel.saveConfiguration() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
