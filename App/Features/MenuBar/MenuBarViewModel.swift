import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

protocol EditorDiscovering {
    func discoverEditors(for contentType: UTType, bucket: LanguageBucket?) -> [EditorCandidate]
}

extension WorkspaceAppDiscovery: EditorDiscovering {}

protocol ApplicationLocating {
    func iconLookupPath(for bundleID: String) -> String?
}

struct WorkspaceApplicationLocator: ApplicationLocating {
    func iconLookupPath(for bundleID: String) -> String? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)?.path
    }
}

@MainActor
final class MenuBarViewModel: ObservableObject {
    static let rulesWindowID = "rules-window"
    static let primaryMenuLimit = 12

    @Published private(set) var summary = MenuBarSummary(
        title: "Loading...",
        detail: "Checking the current global text editor."
    )
    @Published private(set) var sections: [MenuBarSection] = []
    @Published private(set) var lastSwitchReport: GlobalTextSwitchReport?
    @Published private(set) var applyingBundleID: String?
    @Published private(set) var statusItemIconLookupPath: String?
    @Published private(set) var primaryRows: [MenuBarEditorRow] = []
    @Published private(set) var overflowRows: [MenuBarEditorRow] = []

    let rulesWindowAction = RulesWindowAction(
        title: "Settings...",
        windowID: MenuBarViewModel.rulesWindowID
    )

    private let stateService: GlobalTextStateServicing
    private let appDiscovery: EditorDiscovering
    private let switchCoordinator: GlobalTextSwitchCoordinating?
    private let applicationLocator: ApplicationLocating
    private var hasLoadedOnce = false

    init(
        stateService: GlobalTextStateServicing = GlobalTextStateService(),
        appDiscovery: EditorDiscovering = WorkspaceAppDiscovery(),
        switchCoordinator: GlobalTextSwitchCoordinating? = GlobalTextSwitchCoordinator(),
        applicationLocator: ApplicationLocating = WorkspaceApplicationLocator()
    ) {
        self.stateService = stateService
        self.appDiscovery = appDiscovery
        self.switchCoordinator = switchCoordinator
        self.applicationLocator = applicationLocator
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
        let allRows = orderedRows(
            from: candidates,
            currentBundleID: state.currentBundleID,
            applyingBundleID: applyingBundleID
        )
        primaryRows = primaryRows(from: allRows, currentBundleID: state.currentBundleID)
        let primaryIDs = Set(primaryRows.map(\.id))
        overflowRows = allRows.filter { !primaryIDs.contains($0.id) }

    }

    func applyEditor(bundleID: String) {
        guard let switchCoordinator else {
            return
        }

        applyingBundleID = bundleID
        load()

        let report = switchCoordinator.apply(bundleID: bundleID)
        lastSwitchReport = report
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
                detail: "Current global text editor across \(state.inspectedContentTypeIdentifiers.count) declared text types."
            )
        case .mixed(let bundleIDs):
            let highlightedName = state.currentBundleID.map { displayName(for: $0, displayNames: displayNames) } ?? "Mixed Defaults"
            let remainingNames = bundleIDs
                .filter { $0 != state.currentBundleID }
                .map { displayName(for: $0, displayNames: displayNames) }
                .joined(separator: ", ")
            let detail: String
            if remainingNames.isEmpty {
                detail = "Mixed defaults across declared text types. Current plain text opens in \(highlightedName)."
            } else {
                detail = "Mixed defaults across declared text types. Current plain text opens in \(highlightedName), while other types still use: \(remainingNames)."
            }
            return MenuBarSummary(
                title: highlightedName,
                detail: detail
            )
        case .unavailable:
            return MenuBarSummary(
                title: "No Global Editor Detected",
                detail: "No declared text type currently reports an editor handler."
            )
        }
    }

    private func sections(
        from candidates: [EditorCandidate],
        currentBundleID: String?,
        applyingBundleID: String?
    ) -> [MenuBarSection] {
        let recommendedRows = candidates
            .filter { $0.isRecommended && $0.capability == .full }
            .map { row(from: $0, currentBundleID: currentBundleID, applyingBundleID: applyingBundleID) }

        let otherEligibleRows = candidates
            .filter { !$0.isRecommended && $0.capability == .full }
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
            actionTitle: "Use \(candidate.displayName) for All Text Files",
            capabilityNote: capabilityNote(for: candidate),
            isCurrent: candidate.bundleID == currentBundleID,
            isBusy: candidate.bundleID == applyingBundleID,
            capability: candidate.capability
        )
    }

    private func orderedRows(
        from candidates: [EditorCandidate],
        currentBundleID: String?,
        applyingBundleID: String?
    ) -> [MenuBarEditorRow] {
        candidates.map { row(from: $0, currentBundleID: currentBundleID, applyingBundleID: applyingBundleID) }
    }

    private func primaryRows(
        from rows: [MenuBarEditorRow],
        currentBundleID: String?
    ) -> [MenuBarEditorRow] {
        guard let currentRow = rows.first(where: { $0.bundleID == currentBundleID }) else {
            return Array(rows.prefix(Self.primaryMenuLimit))
        }

        if rows.prefix(Self.primaryMenuLimit).contains(where: { $0.id == currentRow.id }) {
            return Array(rows.prefix(Self.primaryMenuLimit))
        }

        let fallbackRows = rows
            .filter { $0.id != currentRow.id }
            .prefix(max(Self.primaryMenuLimit - 1, 0))

        return [currentRow] + fallbackRows
    }

    private func capabilityNote(for candidate: EditorCandidate) -> String? {
        switch candidate.capability {
        case .full:
            return candidate.isRecommended ? nil : "Available through macOS registration"
        case .partial:
            return "Partial support"
        case .unverified:
            return "Needs verification"
        }
    }

    private func displayName(for bundleID: String, displayNames: [String: String]) -> String {
        displayNames[bundleID]
            ?? KnownEditors.knownEditor(for: bundleID)?.displayName
            ?? bundleID
    }

    private func deduplicatedCandidates(_ candidates: [EditorCandidate]) -> [EditorCandidate] {
        var seen = Set<String>()
        return candidates.filter { candidate in
            seen.insert(candidate.bundleID).inserted
        }
    }

    private func uniqueRows(_ rows: [MenuBarEditorRow]) -> [MenuBarEditorRow] {
        var seen = Set<String>()
        return rows.filter { seen.insert($0.id).inserted }
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
}
