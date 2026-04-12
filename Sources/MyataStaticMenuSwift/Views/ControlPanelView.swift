import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var viewModel: ControlPanelViewModel

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    header

                    if geometry.size.width >= 1120 {
                        HStack(alignment: .top, spacing: 16) {
                            actionsPanel
                                .frame(width: 360)
                            sourcePanel
                        }
                    } else {
                        VStack(spacing: 16) {
                            actionsPanel
                            sourcePanel
                        }
                    }

                    filesPanel
                    logsPanel
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(backgroundGradient)
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(red: 0.05, green: 0.06, blue: 0.08), Color(red: 0.08, green: 0.10, blue: 0.13)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Myata Static Menu Swift")
                .font(.system(size: 34, weight: .bold))
            Text("Нативное macOS приложение для сборки и публикации меню из Google Sheets. Логика build, publish, refresh и migrate images уже выполняется на Swift.")
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
                Task { await viewModel.refreshMenu() }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Refresh Menu")
                        .font(.title2.weight(.bold))
                    Text("Скачать актуальные данные из Google Sheets, собрать HTML/JSON/YML и сразу опубликовать всё в Yandex Object Storage.")
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isBusy)
            .help("Полный цикл: build + publish.")

            VStack(spacing: 10) {
                smallActionButton(title: "Build", description: "Только локально собрать index.html, menu.json и yandex-menu.yml без публикации.") {
                    Task { await viewModel.buildMenu() }
                }
                smallActionButton(title: "Publish", description: "Если локальных артефактов ещё нет, приложение сначала выполнит Build, а затем загрузит файлы в S3.") {
                    Task { await viewModel.publishMenu() }
                }
                smallActionButton(title: "Migrate Images", description: "Скачать все image_url из таблицы и перенести изображения в bucket в каталог img.") {
                    Task { await viewModel.migrateImages() }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.lastBuildSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if let lastOperation = viewModel.lastOperation {
                    Text("\(lastOperation.kind.rawValue): \(lastOperation.success ? "успех" : "ошибка")")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(lastOperation.success ? .green : .red)
                    Text(lastOperation.details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var sourcePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Источник Данных И S3")
                .font(.title3.weight(.semibold))

            labeledField("Google Sheet ID", text: $viewModel.configuration.googleSheetID)

            adaptiveFields {
                labeledField("Settings GID", text: $viewModel.configuration.settingsGID)
                labeledField("Categories GID", text: $viewModel.configuration.categoriesGID)
            }

            labeledField("Items GID", text: $viewModel.configuration.itemsGID)

            adaptiveFields {
                labeledField("S3 Endpoint", text: $viewModel.configuration.s3Endpoint)
                labeledField("S3 Region", text: $viewModel.configuration.s3Region)
            }

            labeledField("Bucket", text: $viewModel.configuration.bucket)

            adaptiveFields {
                labeledField("Prefix", text: $viewModel.configuration.prefix)
                labeledField("Yandex Vendor", text: $viewModel.configuration.yandexVendor)
            }

            adaptiveFields {
                labeledField("Access Key ID", text: $viewModel.configuration.accessKeyID)
                secretField("Secret Access Key", text: $viewModel.configuration.secretAccessKey)
            }

            labeledField("Public Menu URL", text: $viewModel.configuration.publicMenuURL)

            Button("Сохранить настройки") {
                Task { await viewModel.saveConfiguration() }
            }
            .buttonStyle(.bordered)

            Text("S3 секреты сохраняются в macOS Keychain. В локальном конфиге остаются только несекретные настройки.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
            .frame(maxWidth: .infinity, minHeight: 240, alignment: .topLeading)
            .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func smallActionButton(title: String, description: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.isBusy)
        .help(description)
    }

    private func adaptiveFields<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 10) {
                content()
            }
            VStack(spacing: 10) {
                content()
            }
        }
    }

    private func labeledField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func secretField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            SecureField(title, text: text)
                .textFieldStyle(.roundedBorder)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
