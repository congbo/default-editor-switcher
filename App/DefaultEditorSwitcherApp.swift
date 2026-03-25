import SwiftUI

@main
struct DefaultEditorSwitcherApp: App {
    @StateObject private var menuBarViewModel: MenuBarViewModel

    init() {
        let viewModel = MenuBarViewModel()
        viewModel.load()
        _menuBarViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: menuBarViewModel)
        } label: {
            MenuBarStatusItemView(viewModel: menuBarViewModel)
        }
        .menuBarExtraStyle(.menu)

        WindowGroup("Rules Window", id: MenuBarViewModel.rulesWindowID) {
            RulesWindowPlaceholderView()
        }
        .defaultSize(width: 480, height: 320)
    }
}
