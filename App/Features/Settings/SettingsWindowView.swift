import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var menuBarViewModel: MenuBarViewModel
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel
    @ObservedObject var recommendedAppsStore: RecommendedMenuAppsStore
    @ObservedObject var languageStore: AppLanguageStore
    @ObservedObject var localizer: AppLocalizer

    private let applicationLocator: ApplicationLocating

    init(
        menuBarViewModel: MenuBarViewModel,
        generalSettingsViewModel: GeneralSettingsViewModel,
        recommendedAppsStore: RecommendedMenuAppsStore,
        languageStore: AppLanguageStore,
        localizer: AppLocalizer,
        applicationLocator: ApplicationLocating = WorkspaceApplicationLocator()
    ) {
        self.menuBarViewModel = menuBarViewModel
        self.generalSettingsViewModel = generalSettingsViewModel
        self.recommendedAppsStore = recommendedAppsStore
        self.languageStore = languageStore
        self.localizer = localizer
        self.applicationLocator = applicationLocator
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            List {
                GeneralSettingsSection(
                    viewModel: generalSettingsViewModel,
                    statusSnapshot: statusSnapshot,
                    localizer: localizer
                )

                RecommendedAppsSettingsSection(
                    recommendedAppsStore: recommendedAppsStore,
                    availableEditors: menuBarViewModel.availableEditors,
                    localizer: localizer
                )

                LanguageSettingsSection(languageStore: languageStore)
            }
            .listStyle(.inset)
        }
        .padding(20)
        .frame(minWidth: 680, minHeight: 560, alignment: .topLeading)
        .onAppear {
            menuBarViewModel.loadIfNeeded()
            generalSettingsViewModel.loadStatus()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Tune launch behavior, keep the menu bar shortlist in order, and check which editor currently owns global text files.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statusSnapshot: SettingsStatusSnapshot {
        SettingsCopyFormatter(
            localizer: localizer,
            applicationLocator: applicationLocator
        )
        .statusSnapshot(
            from: menuBarViewModel.currentState,
            lastSwitchReport: menuBarViewModel.lastSwitchReport,
            availableEditors: menuBarViewModel.availableEditors
        )
    }
}

struct SettingsStatusSnapshot: Equatable {
    let title: String
    let summary: String
    let iconLookupPath: String?
    let distributionGroups: [CurrentDefaultEditorGroup]
    let pendingGroups: [SettingsStatusGroup]
    let recentSwitch: SettingsStatusActivitySnapshot?
}

struct CurrentDefaultEditorGroup: Identifiable, Equatable {
    let bundleID: String
    let displayName: String
    let iconLookupPath: String?
    let extensions: [String]

    var id: String {
        bundleID
    }

    var extensionLines: [String] {
        ExtensionLineChunker().chunk(extensions)
    }
}

struct SettingsStatusGroup: Identifiable, Equatable {
    let title: String
    let extensions: [String]

    var id: String {
        title
    }

    var extensionLines: [String] {
        ExtensionLineChunker().chunk(extensions)
    }
}

struct SettingsStatusActivitySnapshot: Equatable {
    let statusTitle: String
    let headline: String
    let groups: [SettingsStatusGroup]
}

struct ExtensionLineChunker {
    let maximumLineLength: Int

    init(maximumLineLength: Int = 48) {
        self.maximumLineLength = maximumLineLength
    }

    func chunk(_ extensions: [String]) -> [String] {
        guard !extensions.isEmpty else {
            return []
        }

        let singleLine = extensions.joined(separator: ", ")
        guard singleLine.count > maximumLineLength, extensions.count > 1 else {
            return [singleLine]
        }

        var bestSplitIndex = 1
        var bestScore = Int.max

        for splitIndex in 1..<extensions.count {
            let firstLine = extensions[..<splitIndex].joined(separator: ", ")
            let secondLine = extensions[splitIndex...].joined(separator: ", ")
            let longestLine = max(firstLine.count, secondLine.count)
            let balancePenalty = abs(firstLine.count - secondLine.count)
            let score = (longestLine * 1_000) + balancePenalty

            if score < bestScore {
                bestScore = score
                bestSplitIndex = splitIndex
            }
        }

        return [
            extensions[..<bestSplitIndex].joined(separator: ", "),
            extensions[bestSplitIndex...].joined(separator: ", "),
        ]
    }
}
