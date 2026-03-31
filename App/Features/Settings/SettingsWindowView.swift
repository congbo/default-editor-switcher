import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var menuBarViewModel: MenuBarViewModel
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel
    @ObservedObject var recommendedAppsStore: RecommendedMenuAppsStore
    @ObservedObject var globalTextTypesStore: GlobalTextTypesStore
    @ObservedObject var languageStore: AppLanguageStore
    @ObservedObject var localizer: AppLocalizer

    private let applicationLocator: ApplicationLocating

    init(
        menuBarViewModel: MenuBarViewModel,
        generalSettingsViewModel: GeneralSettingsViewModel,
        recommendedAppsStore: RecommendedMenuAppsStore,
        globalTextTypesStore: GlobalTextTypesStore,
        languageStore: AppLanguageStore,
        localizer: AppLocalizer,
        applicationLocator: ApplicationLocating = WorkspaceApplicationLocator()
    ) {
        self.menuBarViewModel = menuBarViewModel
        self.generalSettingsViewModel = generalSettingsViewModel
        self.recommendedAppsStore = recommendedAppsStore
        self.globalTextTypesStore = globalTextTypesStore
        self.languageStore = languageStore
        self.localizer = localizer
        self.applicationLocator = applicationLocator
    }

    var body: some View {
        List {
            GeneralSettingsSection(
                viewModel: generalSettingsViewModel,
                statusSnapshot: statusSnapshot,
                localizer: localizer
            )

            refreshSection

            RecommendedAppsSettingsSection(
                recommendedAppsStore: recommendedAppsStore,
                availableEditors: menuBarViewModel.availableEditors,
                localizer: localizer
            )

            GlobalTextTypesSettingsSection(
                globalTextTypesStore: globalTextTypesStore,
                localizer: localizer
            )

            LanguageSettingsSection(languageStore: languageStore)

            activityLogSection
        }
        .listStyle(.inset)
        .frame(minWidth: 520, idealWidth: 560, minHeight: 480, idealHeight: 540, alignment: .topLeading)
        .background(
            SettingsWindowAccessor { window in
                SettingsWindowCoordinator.shared.register(window: window)
            }
        )
        .onAppear {
            menuBarViewModel.loadIfNeeded()
            generalSettingsViewModel.loadStatus()
        }
    }

    private var activityFormatter: SettingsActivityFormatter {
        SettingsActivityFormatter(localizer: localizer)
    }

    private var statusSnapshot: SettingsStatusSnapshot {
        SettingsCopyFormatter(
            localizer: localizer,
            applicationLocator: applicationLocator
        )
        .statusSnapshot(
            from: menuBarViewModel.currentState,
            availableEditors: menuBarViewModel.availableEditors
        )
    }

    private var refreshSection: some View {
        Section(localizer.string("Refresh")) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizer.string("Refresh"))

                    Text(activityFormatter.refreshDescription())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(
                        activityFormatter.refreshStatusDetail(
                            refreshStatus: menuBarViewModel.settingsRefreshStatus,
                            isBlockedBySwitch: menuBarViewModel.applyingBundleID != nil
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 16)

                Button(localizer.string("Refresh"), action: refreshSettings)
                    .buttonStyle(.bordered)
                    .disabled(menuBarViewModel.isSettingsRefreshDisabled)
            }
        }
    }

    private var activityLogSection: some View {
        Section(localizer.string("Last Switch Log")) {
            if menuBarViewModel.settingsLogEntries.isEmpty {
                Text(activityFormatter.activityEmptyStateText())
                    .foregroundStyle(.secondary)
            } else {
                ForEach(menuBarViewModel.settingsLogEntries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(verbatim: entry.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)

                            Text(verbatim: activityFormatter.logLevelTitle(for: entry.level))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(activityFormatter.logLevelColor(for: entry.level))

                            Text(verbatim: activityFormatter.logCategoryTitle(for: entry.category))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let targetDisplayName = entry.targetDisplayName, !targetDisplayName.isEmpty {
                                Text(verbatim: targetDisplayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(verbatim: entry.message)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func refreshSettings() {
        menuBarViewModel.refresh()
        generalSettingsViewModel.loadStatus()
    }
}

struct SettingsStatusSnapshot: Equatable {
    let title: String
    let summary: String
    let iconLookupPath: String?
}

@MainActor
final class SettingsWindowCoordinator {
    static let shared = SettingsWindowCoordinator()

    private weak var window: NSWindow?

    func register(window: NSWindow) {
        self.window = window
        raiseRegisteredWindow()
    }

    func prepareForPresentation() {
        NSApp.activate(ignoringOtherApps: true)

        if raiseRegisteredWindow() {
            return
        }

        retryRaiseRegisteredWindow(remainingAttempts: 4)
    }

    @discardableResult
    private func raiseRegisteredWindow() -> Bool {
        guard let window else {
            return false
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        return true
    }

    private func retryRaiseRegisteredWindow(remainingAttempts: Int) {
        guard remainingAttempts > 0 else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else {
                return
            }

            if self.raiseRegisteredWindow() {
                return
            }

            self.retryRaiseRegisteredWindow(remainingAttempts: remainingAttempts - 1)
        }
    }
}

struct SettingsWindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        resolveWindow(for: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        resolveWindow(for: nsView)
    }

    private func resolveWindow(for view: NSView) {
        DispatchQueue.main.async {
            guard let window = view.window else {
                return
            }

            onResolve(window)
        }
    }
}
