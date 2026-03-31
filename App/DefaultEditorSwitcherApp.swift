import SwiftUI

@main
struct DefaultEditorSwitcherApp: App {
    @StateObject private var appLanguageStore: AppLanguageStore
    @StateObject private var appLocalizer: AppLocalizer
    @StateObject private var settingsActivityStore: SettingsActivityStore
    @StateObject private var recommendedMenuAppsStore: RecommendedMenuAppsStore
    @StateObject private var globalTextTypesStore: GlobalTextTypesStore
    @StateObject private var generalSettingsViewModel: GeneralSettingsViewModel
    @StateObject private var menuBarViewModel: MenuBarViewModel

    init() {
        let settingsActivityStore = SettingsActivityStore()
        let appLanguageStore = AppLanguageStore(activityLogger: settingsActivityStore)
        let recommendedMenuAppsStore = RecommendedMenuAppsStore(activityLogger: settingsActivityStore)
        let globalTextTypesStore = GlobalTextTypesStore(activityLogger: settingsActivityStore)
        let generalSettingsViewModel = GeneralSettingsViewModel(activityLogger: settingsActivityStore)
        let localizer = AppLocalizer(languageStore: appLanguageStore)
        let viewModel = MenuBarViewModel(
            stateService: GlobalTextStateService(
                enabledExtensionsProvider: { globalTextTypesStore.enabledExtensions() }
            ),
            switchCoordinator: GlobalTextSwitchCoordinator(
                enabledExtensionsProvider: { globalTextTypesStore.enabledExtensions() }
            ),
            recommendedAppsStore: recommendedMenuAppsStore,
            globalTextTypesStore: globalTextTypesStore,
            localizer: localizer,
            settingsActivityStore: settingsActivityStore
        )
        viewModel.load()
        _appLanguageStore = StateObject(wrappedValue: appLanguageStore)
        _appLocalizer = StateObject(wrappedValue: localizer)
        _settingsActivityStore = StateObject(wrappedValue: settingsActivityStore)
        _recommendedMenuAppsStore = StateObject(wrappedValue: recommendedMenuAppsStore)
        _globalTextTypesStore = StateObject(wrappedValue: globalTextTypesStore)
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
                globalTextTypesStore: globalTextTypesStore,
                languageStore: appLanguageStore,
                localizer: appLocalizer
            )
            .environment(\.locale, appLanguageStore.effectiveLocale)
        }
        .defaultSize(width: 560, height: 540)
    }
}
