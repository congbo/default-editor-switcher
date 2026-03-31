import Foundation

@MainActor
struct SettingsCopyFormatter {
    let localizer: any AppTextLocalizing
    let applicationLocator: ApplicationLocating?

    init(
        localizer: any AppTextLocalizing,
        applicationLocator: ApplicationLocating? = nil
    ) {
        self.localizer = localizer
        self.applicationLocator = applicationLocator
    }

    func statusSnapshot(
        from state: GlobalTextState?,
        availableEditors: [EditorCandidate]
    ) -> SettingsStatusSnapshot {
        guard let state else {
            return SettingsStatusSnapshot(
                title: localizer.string("Loading..."),
                summary: localizer.string("Checking the current global text default app."),
                iconLookupPath: nil
            )
        }

        let displayNames = Dictionary(
            availableEditors.map { ($0.bundleID, $0.displayName) },
            uniquingKeysWith: { first, _ in first }
        )
        let iconPaths = Dictionary(
            availableEditors.map { ($0.bundleID, $0.iconLookupPath) },
            uniquingKeysWith: { first, _ in first }
        )

        let title: String
        let summary: String
        let titleIconLookupPath: String?

        switch state.status {
        case .single(let bundleID):
            let exampleExtensions = exampleExtensions(in: state.extensionAssociations)
            title = displayName(for: bundleID, displayNames: displayNames)
            summary = localizer.formattedString(
                "Current default app covers %d declared text extensions, for example %@.",
                state.extensionAssociations.count,
                exampleExtensions
            )
            titleIconLookupPath = iconLookupPath(for: bundleID, iconPaths: iconPaths)
        case .mixed:
            let representativeBundleID = state.currentBundleID
            title = representativeBundleID.map { displayName(for: $0, displayNames: displayNames) }
                ?? localizer.string("Mixed Defaults")
            summary = localizer.string("Declared text types are currently split across multiple default apps.")
            titleIconLookupPath = representativeBundleID.flatMap { iconLookupPath(for: $0, iconPaths: iconPaths) }
        case .unavailable:
            return SettingsStatusSnapshot(
                title: localizer.string("No Global Editor Detected"),
                summary: localizer.string("No declared text type currently reports a default app."),
                iconLookupPath: nil
            )
        }

        return SettingsStatusSnapshot(
            title: title,
            summary: summary,
            iconLookupPath: titleIconLookupPath
        )
    }

    func launchAtLoginDetail(
        detailKind: LaunchAtLoginDetailKind,
        errorMessage: String?
    ) -> String {
        if let errorMessage {
            return errorMessage
        }

        switch detailKind {
        case .enabled, .neutral:
            return localizer.string("Launch the app automatically when you sign in to macOS.")
        case .disabled:
            return localizer.string("The app opens manually from your menu bar until launch at login is enabled.")
        case .approvalRequired:
            return localizer.string("macOS requires approval before this app can launch at login.")
        }
    }

    func recommendedEntries(
        availableEditors: [EditorCandidate],
        configuration: RecommendedMenuAppsConfiguration
    ) -> [RecommendedAppsEntry] {
        let availableCandidateByBundleID = Dictionary(
            availableEditors.map { ($0.bundleID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let orderedBundleIDs = configuration.orderedBundleIDs.filter {
            availableCandidateByBundleID[$0] != nil
        } + availableEditors.map(\.bundleID).filter {
            !configuration.orderedBundleIDs.contains($0)
        }

        return orderedBundleIDs.compactMap { bundleID in
            guard let candidate = availableCandidateByBundleID[bundleID] else {
                return nil
            }
            let displayName = candidate.displayName

            return RecommendedAppsEntry(
                bundleID: bundleID,
                displayName: displayName,
                detail: recommendedEntryDetail(for: candidate, configuration: configuration),
                iconLookupPath: candidate.iconLookupPath,
                isEnabled: configuration.isEnabled(bundleID: bundleID),
                isAvailable: true
            )
        }
    }

    func recommendedEditorsSummary(enabledCount: Int) -> String {
        localizer.formattedString("%lld editors", Int64(enabledCount))
    }

    private func recommendedEntryDetail(
        for candidate: EditorCandidate,
        configuration: RecommendedMenuAppsConfiguration
    ) -> String {
        switch candidate.capability {
        case .full:
            if configuration.isEnabled(bundleID: candidate.bundleID) {
                return localizer.string("Shown in the first-level menu")
            }

            return localizer.string("Shown in More")
        case .partial:
            return localizer.string("Partial support")
        case .unverified:
            return localizer.string("Needs verification")
        }
    }

    private func displayName(for bundleID: String, displayNames: [String: String]) -> String {
        displayNames[bundleID]
            ?? KnownEditors.knownEditor(for: bundleID)?.displayName
            ?? applicationLocator?.displayName(for: bundleID)
            ?? bundleID
    }

    private func iconLookupPath(for bundleID: String, iconPaths: [String: String]) -> String? {
        iconPaths[bundleID] ?? applicationLocator?.iconLookupPath(for: bundleID)
    }

    private func exampleExtensions(in associations: [GlobalTextState.ExtensionAssociation]) -> String {
        associations
            .map(\.normalizedExtension)
            .sorted()
            .prefix(5)
            .map { ".\($0)" }
            .joined(separator: ", ")
    }
}

struct RecommendedAppsEntry: Identifiable, Equatable {
    let bundleID: String
    let displayName: String
    let detail: String
    let iconLookupPath: String?
    let isEnabled: Bool
    let isAvailable: Bool

    var id: String {
        bundleID
    }
}
