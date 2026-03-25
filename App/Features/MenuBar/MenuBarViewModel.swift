import AppKit
import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers

protocol EditorDiscovering {
    func discoverEditors(for contentType: UTType, bucket: LanguageBucket?) -> [EditorCandidate]
}

extension WorkspaceAppDiscovery: EditorDiscovering {}

protocol ApplicationLocating {
    func iconLookupPath(for bundleID: String) -> String?
    func displayName(for bundleID: String) -> String?
}

struct WorkspaceApplicationLocator: ApplicationLocating {
    func iconLookupPath(for bundleID: String) -> String? {
        applicationURL(for: bundleID)?.path
    }

    func displayName(for bundleID: String) -> String? {
        guard let applicationURL = applicationURL(for: bundleID) else {
            return nil
        }

        guard let bundle = Bundle(url: applicationURL) else {
            return applicationURL.deletingPathExtension().lastPathComponent
        }

        return bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? applicationURL.deletingPathExtension().lastPathComponent
    }

    private func applicationURL(for bundleID: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    }
}

@MainActor
final class MenuBarViewModel: ObservableObject {
    static let settingsWindowID = "settings-window"

    @Published private(set) var summary: MenuBarSummary
    @Published private(set) var sections: [MenuBarSection] = []
    @Published private(set) var lastSwitchReport: GlobalTextSwitchReport?
    @Published private(set) var lastSwitchFeedback: GlobalTextSwitchFeedback?
    @Published private(set) var applyingBundleID: String?
    @Published private(set) var statusItemIconLookupPath: String?
    @Published private(set) var primaryRows: [MenuBarEditorRow] = []
    @Published private(set) var overflowRows: [MenuBarEditorRow] = []

    private let stateService: GlobalTextStateServicing
    private let appDiscovery: EditorDiscovering
    private let switchCoordinator: GlobalTextSwitchCoordinating?
    private let applicationLocator: ApplicationLocating
    private let recommendedAppsStore: any RecommendedMenuAppsStoring
    private let localizer: any AppTextLocalizing
    private let switchFeedbackFormatter: any GlobalTextSwitchFeedbackFormatting
    private var hasLoadedOnce = false
    private var cancellables: Set<AnyCancellable> = []

    init(
        stateService: GlobalTextStateServicing = GlobalTextStateService(),
        appDiscovery: EditorDiscovering = WorkspaceAppDiscovery(),
        switchCoordinator: GlobalTextSwitchCoordinating? = GlobalTextSwitchCoordinator(),
        applicationLocator: ApplicationLocating = WorkspaceApplicationLocator(),
        recommendedAppsStore: any RecommendedMenuAppsStoring = TransientRecommendedMenuAppsStore(),
        localizer: any AppTextLocalizing = PassthroughLocalizer(),
        switchFeedbackFormatter: (any GlobalTextSwitchFeedbackFormatting)? = nil
    ) {
        self.stateService = stateService
        self.appDiscovery = appDiscovery
        self.switchCoordinator = switchCoordinator
        self.applicationLocator = applicationLocator
        self.recommendedAppsStore = recommendedAppsStore
        self.localizer = localizer
        self.switchFeedbackFormatter = switchFeedbackFormatter ?? GlobalTextSwitchFeedbackFormatter(
            localizer: localizer,
            applicationLocator: applicationLocator
        )
        self.summary = MenuBarSummary(
            title: localizer.string("Loading..."),
            detail: localizer.string("Checking the current global text editor.")
        )
        bindPreferenceUpdates()
    }

    var settingsWindowAction: SettingsWindowAction {
        SettingsWindowAction(
            title: localizer.string("Settings..."),
            windowID: Self.settingsWindowID
        )
    }

    func loadIfNeeded() {
        guard !hasLoadedOnce else {
            return
        }

        load()
    }

    func load() {
        hasLoadedOnce = true

        let state = stateService.currentState()
        let candidates = deduplicatedCandidates(
            appDiscovery.discoverEditors(for: .plainText, bucket: nil)
        )
        let displayNames = Dictionary(candidates.map { ($0.bundleID, $0.displayName) }, uniquingKeysWith: { first, _ in first })
        let iconPaths = Dictionary(candidates.map { ($0.bundleID, $0.iconLookupPath) }, uniquingKeysWith: { first, _ in first })

        summary = summary(from: state, displayNames: displayNames)
        statusItemIconLookupPath = currentIconLookupPath(
            for: state.currentBundleID,
            iconPaths: iconPaths
        )
        sections = sections(
            from: candidates,
            currentBundleID: state.currentBundleID,
            applyingBundleID: applyingBundleID
        )
        primaryRows = recommendedMenuRows(from: sections)
        overflowRows = overflowMenuRows(from: sections)
        lastSwitchFeedback = feedback(from: lastSwitchReport, displayNames: displayNames)
    }

    func applyEditor(bundleID: String) {
        guard let switchCoordinator else {
            return
        }

        applyingBundleID = bundleID
        load()

        let report = switchCoordinator.apply(bundleID: bundleID)
        lastSwitchReport = report
        if report.didFullyMatch {
            lastSwitchFeedback = nil
        }
        applyingBundleID = nil
        load()
    }

    private func summary(
        from state: GlobalTextState,
        displayNames: [String: String]
    ) -> MenuBarSummary {
        switch state.status {
        case .single(let bundleID):
            return MenuBarSummary(
                title: displayName(for: bundleID, displayNames: displayNames),
                detail: localizer.formattedString(
                    "Current global text editor across %d declared text types.",
                    state.inspectedContentTypeIdentifiers.count
                )
            )
        case .mixed(let bundleIDs):
            let highlightedName = state.currentBundleID.map { displayName(for: $0, displayNames: displayNames) }
                ?? localizer.string("Mixed Defaults")
            let remainingNames = bundleIDs
                .filter { $0 != state.currentBundleID }
                .map { displayName(for: $0, displayNames: displayNames) }
                .joined(separator: ", ")
            let detail: String
            if remainingNames.isEmpty {
                detail = localizer.formattedString(
                    "Mixed defaults across declared text types. Current plain text opens in %@.",
                    highlightedName
                )
            } else {
                detail = localizer.formattedString(
                    "Mixed defaults across declared text types. Current plain text opens in %@, while other types still use: %@.",
                    highlightedName,
                    remainingNames
                )
            }
            return MenuBarSummary(
                title: highlightedName,
                detail: detail
            )
        case .unavailable:
            return MenuBarSummary(
                title: localizer.string("No Global Editor Detected"),
                detail: localizer.string("No declared text type currently reports an editor handler.")
            )
        }
    }

    private func sections(
        from candidates: [EditorCandidate],
        currentBundleID: String?,
        applyingBundleID: String?
    ) -> [MenuBarSection] {
        let recommendedBundleIDs = recommendedAppsStore.resolvedRecommendedBundleIDs(
            availableBundleIDs: candidates
                .filter { $0.capability == .full }
                .map(\.bundleID)
        )
        let recommendedBundleIDSet = Set(recommendedBundleIDs)
        let recommendedRows = recommendedBundleIDs
            .compactMap { bundleID in
                candidates.first(where: { $0.bundleID == bundleID && $0.capability == .full })
            }
            .map { row(from: $0, currentBundleID: currentBundleID, applyingBundleID: applyingBundleID) }

        let otherEligibleRows = candidates
            .filter { $0.capability == .full && !recommendedBundleIDSet.contains($0.bundleID) }
            .map { row(from: $0, currentBundleID: currentBundleID, applyingBundleID: applyingBundleID) }

        let verificationRows = candidates
            .filter { $0.capability != .full }
            .map { row(from: $0, currentBundleID: currentBundleID, applyingBundleID: applyingBundleID) }

        return [
            recommendedRows.isEmpty ? nil : .recommendedFullSupport(rows: recommendedRows),
            otherEligibleRows.isEmpty ? nil : .otherEligible(rows: otherEligibleRows),
            verificationRows.isEmpty ? nil : .needsVerification(rows: verificationRows),
        ].compactMap { $0 }
    }

    private func row(
        from candidate: EditorCandidate,
        currentBundleID: String?,
        applyingBundleID: String?
    ) -> MenuBarEditorRow {
        MenuBarEditorRow(
            bundleID: candidate.bundleID,
            displayName: candidate.displayName,
            iconLookupPath: candidate.iconLookupPath,
            actionTitle: localizer.formattedString(
                "Use %@ for All Text Files",
                candidate.displayName
            ),
            capabilityNote: capabilityNote(for: candidate),
            isCurrent: candidate.bundleID == currentBundleID,
            isBusy: candidate.bundleID == applyingBundleID,
            capability: candidate.capability
        )
    }

    private func capabilityNote(for candidate: EditorCandidate) -> String? {
        switch candidate.capability {
        case .full:
            return candidate.isRecommended ? nil : localizer.string("Available through macOS registration")
        case .partial:
            return localizer.string("Partial support")
        case .unverified:
            return localizer.string("Needs verification")
        }
    }

    private func displayName(for bundleID: String, displayNames: [String: String]) -> String {
        displayNames[bundleID]
            ?? KnownEditors.knownEditor(for: bundleID)?.displayName
            ?? applicationLocator.displayName(for: bundleID)
            ?? bundleID
    }

    private func deduplicatedCandidates(_ candidates: [EditorCandidate]) -> [EditorCandidate] {
        var seen = Set<String>()
        return candidates.filter { candidate in
            seen.insert(candidate.bundleID).inserted
        }
    }

    private func recommendedMenuRows(from sections: [MenuBarSection]) -> [MenuBarEditorRow] {
        for section in sections {
            if case .recommendedFullSupport(let rows) = section {
                return rows
            }
        }

        return []
    }

    private func overflowMenuRows(from sections: [MenuBarSection]) -> [MenuBarEditorRow] {
        sections.compactMap { section -> [MenuBarEditorRow]? in
            if case .recommendedFullSupport = section {
                return nil
            }

            return section.rows
        }
        .flatMap { $0 }
    }

    private func currentIconLookupPath(
        for bundleID: String?,
        iconPaths: [String: String]
    ) -> String? {
        guard let bundleID else {
            return nil
        }

        return iconPaths[bundleID] ?? applicationLocator.iconLookupPath(for: bundleID)
    }

    private func bindPreferenceUpdates() {
        recommendedAppsStore.objectWillChangePublisher
            .sink { [weak self] in
                guard let self, self.hasLoadedOnce else { return }
                self.load()
            }
            .store(in: &cancellables)

        localizer.objectWillChangePublisher
            .sink { [weak self] in
                guard let self, self.hasLoadedOnce else { return }
                self.load()
            }
            .store(in: &cancellables)
    }

    private func feedback(
        from report: GlobalTextSwitchReport?,
        displayNames: [String: String]
    ) -> GlobalTextSwitchFeedback? {
        guard let report else {
            return nil
        }

        if report.didFullyMatch {
            return nil
        }

        return switchFeedbackFormatter.feedback(
            for: report,
            requestedEditorName: displayName(for: report.requestedBundleID, displayNames: displayNames)
        )
    }
}
