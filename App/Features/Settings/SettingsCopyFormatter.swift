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

    func currentDefaultEditorSnapshot(
        from state: GlobalTextState?,
        availableEditors: [EditorCandidate]
    ) -> CurrentDefaultEditorSnapshot {
        guard let state else {
            return CurrentDefaultEditorSnapshot(
                title: localizer.string("Loading..."),
                summary: localizer.string("Checking the current global text editor."),
                iconLookupPath: nil,
                groups: [],
                missingExtensions: []
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

        switch state.status {
        case .single(let bundleID):
            let missingExtensions = missingExtensions(in: state)
            let exampleExtensions = exampleExtensions(in: state.extensionAssociations)
            let summary = summaryWithMissingDetails(
                localizer.formattedString(
                    "Current editor covers %d declared text extensions, for example %@.",
                    state.extensionAssociations.count,
                    exampleExtensions
                ),
                missingExtensions: missingExtensions
            )
            return CurrentDefaultEditorSnapshot(
                title: displayName(for: bundleID, displayNames: displayNames),
                summary: summary,
                iconLookupPath: iconLookupPath(for: bundleID, iconPaths: iconPaths),
                groups: [],
                missingExtensions: missingExtensions
            )
        case .mixed(let bundleIDs):
            let missingExtensions = missingExtensions(in: state)
            let representativeBundleID = state.currentBundleID
            let title = representativeBundleID.map { displayName(for: $0, displayNames: displayNames) }
                ?? localizer.string("Mixed Defaults")
            let groups = currentDefaultEditorGroups(
                from: state,
                bundleIDs: bundleIDs,
                displayNames: displayNames,
                iconPaths: iconPaths
            )
            let summary = summaryWithMissingDetails(
                localizer.string("Text file default apps are currently mixed."),
                missingExtensions: missingExtensions
            )

            return CurrentDefaultEditorSnapshot(
                title: title,
                summary: summary,
                iconLookupPath: representativeBundleID.flatMap { iconLookupPath(for: $0, iconPaths: iconPaths) },
                groups: groups,
                missingExtensions: missingExtensions
            )
        case .unavailable:
            return CurrentDefaultEditorSnapshot(
                title: localizer.string("No Global Editor Detected"),
                summary: localizer.string("No declared text type currently reports an editor handler."),
                iconLookupPath: nil,
                groups: [],
                missingExtensions: []
            )
        }
    }

    func launchAtLoginDetail(
        status: LaunchAtLoginStatus,
        errorMessage: String?
    ) -> String {
        if let errorMessage {
            return errorMessage
        }

        switch status {
        case .enabled:
            return localizer.string("Launch the app automatically when you sign in to macOS.")
        case .disabled:
            return localizer.string("The app opens manually from your menu bar until launch at login is enabled.")
        case .requiresApproval:
            return localizer.string("macOS requires approval before this app can launch at login.")
        case .unavailable:
            return localizer.string("Launch at login is unavailable for the current build.")
        }
    }

    func recommendedEntries(
        availableEditors: [EditorCandidate],
        configuration: RecommendedMenuAppsConfiguration
    ) -> [RecommendedAppsEntry] {
        let availableCandidateByBundleID = Dictionary(
            availableEditors
                .filter { $0.capability == .full }
                .map { ($0.bundleID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let orderedBundleIDs = configuration.orderedBundleIDs + availableCandidateByBundleID.keys.filter {
            !configuration.orderedBundleIDs.contains($0)
        }.sorted()

        return orderedBundleIDs.map { bundleID in
            let candidate = availableCandidateByBundleID[bundleID]
            let displayName = candidate?.displayName
                ?? KnownEditors.knownEditor(for: bundleID)?.displayName
                ?? applicationLocator?.displayName(for: bundleID)
                ?? bundleID
            let detail: String
            if candidate == nil {
                detail = localizer.string("Currently unavailable on this Mac")
            } else if configuration.isEnabled(bundleID: bundleID) {
                detail = localizer.string("Shown in the first-level menu")
            } else {
                detail = localizer.string("Shown in More")
            }

            return RecommendedAppsEntry(
                bundleID: bundleID,
                displayName: displayName,
                detail: detail,
                iconLookupPath: candidate?.iconLookupPath,
                isEnabled: configuration.isEnabled(bundleID: bundleID),
                isAvailable: candidate != nil
            )
        }
    }

    func recommendedEditorsSummary(enabledCount: Int) -> String {
        localizer.formattedString("%lld editors", Int64(enabledCount))
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

    private func currentDefaultEditorGroups(
        from state: GlobalTextState,
        bundleIDs: [String],
        displayNames: [String: String],
        iconPaths: [String: String]
    ) -> [CurrentDefaultEditorGroup] {
        var groupedExtensions: [String: [String]] = [:]
        for association in state.extensionAssociations {
            guard let bundleID = association.bundleID else {
                continue
            }

            groupedExtensions[bundleID, default: []].append(".\(association.normalizedExtension)")
        }

        let representativeBundleID = state.currentBundleID
        let availableBundleIDs = bundleIDs.filter { groupedExtensions[$0] != nil }

        return availableBundleIDs.map { bundleID in
            CurrentDefaultEditorGroup(
                bundleID: bundleID,
                displayName: displayName(for: bundleID, displayNames: displayNames),
                iconLookupPath: iconLookupPath(for: bundleID, iconPaths: iconPaths),
                extensions: groupedExtensions[bundleID, default: []].sorted()
            )
        }
        .sorted { lhs, rhs in
            if lhs.bundleID == representativeBundleID {
                return rhs.bundleID != representativeBundleID
            }

            if rhs.bundleID == representativeBundleID {
                return false
            }

            let nameComparison = lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName)
            if nameComparison != .orderedSame {
                return nameComparison == .orderedAscending
            }

            return lhs.bundleID < rhs.bundleID
        }
    }

    private func exampleExtensions(in associations: [GlobalTextState.ExtensionAssociation]) -> String {
        associations
            .map(\.normalizedExtension)
            .sorted()
            .prefix(5)
            .map { ".\($0)" }
            .joined(separator: ", ")
    }

    private func missingExtensions(in state: GlobalTextState) -> [String] {
        state.extensionAssociations
            .filter { $0.bundleID == nil }
            .map(\.normalizedExtension)
            .sorted()
            .map { ".\($0)" }
    }

    private func summaryWithMissingDetails(_ base: String, missingExtensions: [String]) -> String {
        guard !missingExtensions.isEmpty else {
            return base
        }

        let separator = base.last == "。" ? "" : " "
        return base + separator + localizer.formattedString(
            "%d extensions do not currently report a default app: %@",
            missingExtensions.count,
            missingExtensions.joined(separator: ",")
        )
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
