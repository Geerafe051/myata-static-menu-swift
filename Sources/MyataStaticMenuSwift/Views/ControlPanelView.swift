import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var viewModel: ControlPanelViewModel
    @State private var isActionsHelpPresented = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    toolbarRow

                    actionsPanel(width: geometry.size.width)
                    statusPanel

                    filesPanel
                    logsPanel
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private var toolbarRow: some View {
        HStack {
            Text("Static Menu Publisher")
                .font(.headline)

            Spacer()

            SettingsLink {
                Label("Configure", systemImage: "gearshape")
            }
            .buttonStyle(.bordered)
        }
    }

    private func actionsPanel(width: CGFloat) -> some View {
        GroupBox {
            VStack(alignment: .center, spacing: 8) {
                if width >= 760 {
                    HStack(spacing: 10) {
                        actionButton(title: "Обновить меню", prominent: true, action: {
                            Task { await viewModel.refreshMenu() }
                        })
                        actionButton(title: "Сбор данных", action: {
                            Task { await viewModel.buildMenu() }
                        })
                        actionButton(title: "Публикация", action: {
                            Task { await viewModel.publishMenu() }
                        })
                        actionButton(title: "Перенос изображений", action: {
                            Task { await viewModel.migrateImages() }
                        })
                    }
                } else {
                    VStack(spacing: 10) {
                        actionButton(title: "Обновить меню", prominent: true, action: {
                            Task { await viewModel.refreshMenu() }
                        })
                        actionButton(title: "Сбор данных", action: {
                            Task { await viewModel.buildMenu() }
                        })
                        actionButton(title: "Публикация", action: {
                            Task { await viewModel.publishMenu() }
                        })
                        actionButton(title: "Перенос изображений", action: {
                            Task { await viewModel.migrateImages() }
                        })
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text("Actions")
                Button {
                    isActionsHelpPresented.toggle()
                } label: {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isActionsHelpPresented, arrowEdge: .bottom) {
                    actionsHelpPopover
                }
            }
        }
        .groupBoxStyle(.automatic)
    }

    private var statusPanel: some View {
        GroupBox("Status") {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: statusSymbol)
                    .font(.title3)
                    .foregroundStyle(statusColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.headline)
                    Text(statusDescription)
                        .foregroundStyle(.secondary)

                    if let lastOperation = viewModel.lastOperation {
                        Text("Updated \(lastOperation.finishedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()
            }
        }
    }

    private var filesPanel: some View {
        GroupBox("Generated Files") {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text("Name")
                        .frame(width: 180, alignment: .leading)
                    Text("Path")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Updated")
                        .frame(width: 180, alignment: .leading)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()

                if viewModel.artifacts.isEmpty {
                    Text("Файлы появятся после первой сборки.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(viewModel.artifacts.enumerated()), id: \.element.id) { index, artifact in
                        HStack(spacing: 12) {
                            Text(artifact.name)
                                .frame(width: 180, alignment: .leading)
                            HStack(spacing: 8) {
                                Text(artifact.path)
                                    .font(.caption)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button {
                                    copyToPasteboard(artifact.path)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(.plain)
                                .help("Скопировать URL")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(artifact.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .frame(width: 180, alignment: .leading)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(index.isMultiple(of: 2) ? Color.clear : Color(nsColor: .controlBackgroundColor).opacity(0.45))

                        if index != viewModel.artifacts.count - 1 {
                            Divider()
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
    }

    private var logsPanel: some View {
        GroupBox("Logs") {
            TextEditor(text: .constant(viewModel.logs.isEmpty ? "Логов пока нет." : viewModel.logs))
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, minHeight: 220)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color(nsColor: .textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
        }
    }

    private func actionButton(title: String, prominent: Bool = false, action: @escaping () -> Void) -> some View {
        SimpleActionButton(
            title: title,
            prominent: prominent,
            isDisabled: viewModel.isBusy || !viewModel.isConfigurationLoaded,
            action: action
        )
    }

    private var statusTitle: String {
        guard let lastOperation = viewModel.lastOperation else {
            return "Ready"
        }

        return lastOperation.success ? "\(lastOperation.kind.rawValue) completed" : "\(lastOperation.kind.rawValue) failed"
    }

    private var statusDescription: String {
        if let lastOperation = viewModel.lastOperation {
            return lastOperation.details
        }

        return viewModel.lastBuildSummary
    }

    private var statusSymbol: String {
        guard let lastOperation = viewModel.lastOperation else {
            return "circle.fill"
        }

        return lastOperation.success ? "checkmark.circle.fill" : "xmark.octagon.fill"
    }

    private var statusColor: Color {
        guard let lastOperation = viewModel.lastOperation else {
            return .secondary
        }

        return lastOperation.success ? .green : .red
    }

    private func copyToPasteboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    private var actionsHelpPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Что делают кнопки")
                .font(.headline)

            helpRow(title: "Обновить меню", text: "Скачать актуальные данные из Google Sheets, собрать HTML, JSON и YML, а затем сразу опубликовать всё в Yandex Object Storage.")
            helpRow(title: "Сбор данных", text: "Только локально собрать файлы `index.html`, `menu.json` и `yandex-menu.yml` без публикации.")
            helpRow(title: "Публикация", text: "Загрузить уже собранные файлы в S3. Если локальных файлов ещё нет, приложение сначала выполнит сборку.")
            helpRow(title: "Перенос изображений", text: "Скачать изображения по `image_url` из таблицы и перенести их в bucket в каталог `img`.")
        }
        .padding(16)
        .frame(width: 380, alignment: .leading)
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: ControlPanelViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Configure")
                        .font(.title2.weight(.bold))
                    Text("Настройки источника данных Google Sheets и публикации в Yandex Object Storage.")
                        .foregroundStyle(.secondary)
                }

                settingsSection(title: "Google Sheets") {
                    labeledField("Google Sheet ID", text: $viewModel.configuration.googleSheetID)

                    adaptiveFields {
                        labeledField("Settings GID", text: $viewModel.configuration.settingsGID)
                        labeledField("Categories GID", text: $viewModel.configuration.categoriesGID)
                    }

                    labeledField("Items GID", text: $viewModel.configuration.itemsGID)
                }

                settingsSection(title: "S3") {
                    adaptiveFields {
                        labeledField("S3 Endpoint", text: $viewModel.configuration.s3Endpoint)
                        labeledField("S3 Region", text: $viewModel.configuration.s3Region)
                    }

                    adaptiveFields {
                        labeledField("Bucket", text: $viewModel.configuration.bucket)
                        labeledField("Prefix", text: $viewModel.configuration.prefix)
                    }

                    adaptiveFields {
                        labeledField("Access Key ID", text: $viewModel.accessKeyIDDraft)
                        secretField("Secret Access Key", text: $viewModel.secretAccessKeyDraft)
                    }
                }

                settingsSection(title: "Publication") {
                    adaptiveFields {
                        labeledField("Yandex Vendor", text: $viewModel.configuration.yandexVendor)
                        labeledField("Public Menu URL", text: $viewModel.configuration.publicMenuURL)
                    }
                }

                Button("Save Configuration") {
                    Task { await viewModel.saveConfiguration() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isBusy || !viewModel.isConfigurationLoaded)

                Text("S3 секреты сохраняются отдельно от обычного конфига. Пустые поля не затирают уже сохранённые ключи.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
    }
}

private struct SimpleActionButton: View {
    let title: String
    let prominent: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Group {
            if prominent {
                Button(action: action) {
                    Text(title)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderedProminentButtonStyle())
            } else {
                Button(action: action) {
                    Text(title)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderedButtonStyle())
            }
        }
        .overlay(buttonHoverOverlay)
        .controlSize(.regular)
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }

    private var buttonHoverOverlay: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .stroke(isHovered ? Color.accentColor.opacity(0.55) : Color.clear, lineWidth: 1)
            .shadow(color: isHovered ? Color.accentColor.opacity(0.18) : Color.clear, radius: 3)
            .animation(.easeOut(duration: 0.12), value: isHovered)
    }
}

private func helpRow(title: String, text: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title)
            .font(.subheadline.weight(.semibold))
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

private struct HintBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Color(nsColor: .labelColor))
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: 320, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }
}

private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
    GroupBox(title) {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
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

#Preview {
    ControlPanelView(viewModel: ControlPanelViewModel())
        .frame(width: 1280, height: 900)
}
