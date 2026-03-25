import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var generalSettingsViewModel: GeneralSettingsViewModel
    @ObservedObject var recommendedAppsStore: RecommendedMenuAppsStore
    @ObservedObject var languageStore: AppLanguageStore
    @ObservedObject var localizer: AppLocalizer

    private let appDiscovery: EditorDiscovering
    private let stateService: GlobalTextStateServicing
    private let applicationLocator: ApplicationLocating

    @State private var availableEditors: [EditorCandidate] = []
    @State private var currentState: GlobalTextState?

    init(
        generalSettingsViewModel: GeneralSettingsViewModel,
        recommendedAppsStore: RecommendedMenuAppsStore,
        languageStore: AppLanguageStore,
        localizer: AppLocalizer,
        appDiscovery: EditorDiscovering = WorkspaceAppDiscovery(),
        stateService: GlobalTextStateServicing = GlobalTextStateService(),
        applicationLocator: ApplicationLocating = WorkspaceApplicationLocator()
    ) {
        self.generalSettingsViewModel = generalSettingsViewModel
        self.recommendedAppsStore = recommendedAppsStore
        self.languageStore = languageStore
        self.localizer = localizer
        self.appDiscovery = appDiscovery
        self.stateService = stateService
        self.applicationLocator = applicationLocator
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            List {
                GeneralSettingsSection(
                    viewModel: generalSettingsViewModel,
                    currentDefaultEditor: currentDefaultEditorSnapshot,
                    localizer: localizer
                )

                RecommendedAppsSettingsSection(
                    recommendedAppsStore: recommendedAppsStore,
                    availableEditors: availableEditors,
                    localizer: localizer
                )

                LanguageSettingsSection(languageStore: languageStore)
            }
            .listStyle(.inset)
        }
        .padding(20)
        .frame(minWidth: 680, minHeight: 560, alignment: .topLeading)
        .onAppear(perform: reloadData)
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

    private func reloadData() {
        generalSettingsViewModel.loadStatus()

        let discoveredEditors = appDiscovery.discoverEditors(for: .plainText, bucket: nil)
        availableEditors = discoveredEditors
        currentState = stateService.currentState()
    }

    private var currentDefaultEditorSnapshot: CurrentDefaultEditorSnapshot {
        SettingsCopyFormatter(
            localizer: localizer,
            applicationLocator: applicationLocator
        )
        .currentDefaultEditorSnapshot(from: currentState, availableEditors: availableEditors)
    }
}

struct CurrentDefaultEditorSnapshot: Equatable {
    let title: String
    let summary: String
    let iconLookupPath: String?
    let groups: [CurrentDefaultEditorGroup]
    let missingExtensions: [String]

    var missingExtensionLines: [String] {
        ExtensionLineChunker().chunk(missingExtensions)
    }
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
