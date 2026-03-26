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
        lastSwitchReport: GlobalTextSwitchReport?,
        availableEditors: [EditorCandidate]
    ) -> SettingsStatusSnapshot {
        guard let state else {
            return SettingsStatusSnapshot(
                title: localizer.string("Loading..."),
                summary: localizer.string("Checking the current global text editor."),
                iconLookupPath: nil,
                distributionGroups: [],
                pendingGroups: [],
                recentSwitch: nil
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
        let distributionGroups: [CurrentDefaultEditorGroup]

        switch state.status {
        case .single(let bundleID):
            let exampleExtensions = exampleExtensions(in: state.extensionAssociations)
            title = displayName(for: bundleID, displayNames: displayNames)
            summary = localizer.formattedString(
                "Current editor covers %d declared text extensions, for example %@.",
                state.extensionAssociations.count,
                exampleExtensions
            )
            titleIconLookupPath = iconLookupPath(for: bundleID, iconPaths: iconPaths)
            distributionGroups = []
        case .mixed(let bundleIDs):
            let representativeBundleID = state.currentBundleID
            title = representativeBundleID.map { displayName(for: $0, displayNames: displayNames) }
                ?? localizer.string("Mixed Defaults")
            distributionGroups = currentDefaultEditorGroups(
                from: state,
                bundleIDs: bundleIDs,
                displayNames: displayNames,
                iconPaths: iconPaths
            )
            summary = localizer.string("Declared text types are currently split across multiple editors.")
            titleIconLookupPath = representativeBundleID.flatMap { iconLookupPath(for: $0, iconPaths: iconPaths) }
        case .unavailable:
            return SettingsStatusSnapshot(
                title: localizer.string("No Global Editor Detected"),
                summary: localizer.string("No declared text type currently reports an editor handler."),
                iconLookupPath: nil,
                distributionGroups: [],
                pendingGroups: [],
                recentSwitch: recentSwitchSnapshot(from: lastSwitchReport, displayNames: displayNames)
            )
        }

        return SettingsStatusSnapshot(
            title: title,
            summary: summary,
            iconLookupPath: titleIconLookupPath,
            distributionGroups: distributionGroups,
            pendingGroups: pendingAssignmentGroups(in: state),
            recentSwitch: recentSwitchSnapshot(from: lastSwitchReport, displayNames: displayNames)
        )
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

    private func recentSwitchSnapshot(
        from report: GlobalTextSwitchReport?,
        displayNames: [String: String]
    ) -> SettingsStatusActivitySnapshot? {
        guard let report else {
            return nil
        }

        let requestedEditorName = displayName(for: report.requestedBundleID, displayNames: displayNames)

        if report.didFullyMatch {
            return SettingsStatusActivitySnapshot(
                statusTitle: localizer.string("Completed"),
                headline: localizer.formattedString(
                    "Last switch to %@ completed for %d text types.",
                    requestedEditorName,
                    report.totalProcessedCount
                ),
                groups: []
            )
        }

        let statusTitle: String
        if report.matchedCount == 0 {
            statusTitle = localizer.string("Not Completed")
        } else {
            statusTitle = localizer.string("Partially Completed")
        }

        return SettingsStatusActivitySnapshot(
            statusTitle: statusTitle,
            headline: localizer.formattedString(
                "Last switch to %@ processed %d text types: %d succeeded, %d failed.",
                requestedEditorName,
                report.totalProcessedCount,
                report.matchedCount,
                report.affectedCount
            ),
            groups: lastSwitchLogGroups(from: report)
        )
    }

    func recommendedEntries(
        availableEditors: [EditorCandidate],
        configuration: RecommendedMenuAppsConfiguration
    ) -> [RecommendedAppsEntry] {
        let availableCandidateByBundleID = Dictionary(
            availableEditors.map { ($0.bundleID, $0) },
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
            if let candidate {
                detail = recommendedEntryDetail(for: candidate, configuration: configuration)
            } else {
                detail = localizer.string("Currently unavailable on this Mac")
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

    private func pendingAssignmentGroups(in state: GlobalTextState) -> [SettingsStatusGroup] {
        let missingExtensions = missingExtensions(in: state)

        guard !missingExtensions.isEmpty else {
            return []
        }

        return [
            SettingsStatusGroup(
                title: localizer.formattedString(
                    "%d extensions are still missing a default app.",
                    missingExtensions.count
                ),
                extensions: missingExtensions
            )
        ]
    }

    private func lastSwitchLogGroups(from report: GlobalTextSwitchReport) -> [SettingsStatusGroup] {
        let unsupportedExtensions = report.failures
            .filter { $0.status == AssociationVerificationStatus.unsupportedTarget.rawValue }
            .map(\.scopeLabel)
            .sorted()
        let mismatchedExtensions = report.failures
            .filter { $0.status == AssociationVerificationStatus.mismatched.rawValue }
            .map(\.scopeLabel)
            .sorted()
        let writeFailedExtensions = report.failures
            .filter { $0.status == AssociationVerificationStatus.writeFailed.rawValue }
            .map(\.scopeLabel)
            .sorted()

        return [
            unsupportedExtensions.isEmpty ? nil : SettingsStatusGroup(
                title: localizer.formattedString(
                    "This Mac does not currently declare support (%d)",
                    unsupportedExtensions.count
                ),
                extensions: unsupportedExtensions
            ),
            mismatchedExtensions.isEmpty ? nil : SettingsStatusGroup(
                title: localizer.formattedString(
                    "Still using another default app (%d)",
                    mismatchedExtensions.count
                ),
                extensions: mismatchedExtensions
            ),
            writeFailedExtensions.isEmpty ? nil : SettingsStatusGroup(
                title: localizer.formattedString(
                    "macOS did not accept this change (%d)",
                    writeFailedExtensions.count
                ),
                extensions: writeFailedExtensions
            ),
        ].compactMap { $0 }
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
