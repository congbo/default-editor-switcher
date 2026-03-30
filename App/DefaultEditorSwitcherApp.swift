import SwiftUI

@main
struct DefaultEditorSwitcherApp: App {
    @StateObject private var appLanguageStore: AppLanguageStore
    @StateObject private var appLocalizer: AppLocalizer
    @StateObject private var recommendedMenuAppsStore: RecommendedMenuAppsStore
    @StateObject private var generalSettingsViewModel: GeneralSettingsViewModel
    @StateObject private var menuBarViewModel: MenuBarViewModel

    init() {
        let appLanguageStore = AppLanguageStore()
        let recommendedMenuAppsStore = RecommendedMenuAppsStore()
        let generalSettingsViewModel = GeneralSettingsViewModel()
        let localizer = AppLocalizer(languageStore: appLanguageStore)
        let viewModel = MenuBarViewModel(
            recommendedAppsStore: recommendedMenuAppsStore,
            localizer: localizer
        )
        viewModel.load()
        _appLanguageStore = StateObject(wrappedValue: appLanguageStore)
        _appLocalizer = StateObject(wrappedValue: localizer)
        _recommendedMenuAppsStore = StateObject(wrappedValue: recommendedMenuAppsStore)
        _generalSettingsViewModel = StateObject(wrappedValue: generalSettingsViewModel)
        _menuBarViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: menuBarViewModel, localizer: appLocalizer)
                .environment(\.locale, appLanguageStore.effectiveLocale)
        } label: {
            MenuBarStatusItemView(viewModel: menuBarViewModel)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsWindowView(
                menuBarViewModel: menuBarViewModel,
                generalSettingsViewModel: generalSettingsViewModel,
                recommendedAppsStore: recommendedMenuAppsStore,
                languageStore: appLanguageStore,
                localizer: appLocalizer
            )
            .environment(\.locale, appLanguageStore.effectiveLocale)
        }
        .defaultSize(width: 560, height: 540)
    }
}
