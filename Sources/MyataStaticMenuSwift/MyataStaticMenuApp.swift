import SwiftUI

@main
struct MyataStaticMenuApp: App {
    @StateObject private var viewModel = ControlPanelViewModel()

    var body: some Scene {
        WindowGroup {
            ControlPanelView(viewModel: viewModel)
                .frame(minWidth: 980, minHeight: 760)
        }
        .windowStyle(.automatic)

        Settings {
            SettingsView(viewModel: viewModel)
                .padding(20)
                .frame(width: 520)
        }
    }
}
