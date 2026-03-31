import AppKit
import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers

protocol EditorDiscovering {
    func discoverEditors(for contentType: UTType, bucket: LanguageBucket?) throws -> [EditorCandidate]
}

extension WorkspaceAppDiscovery: EditorDiscovering {}

protocol ApplicationLocating {
    func iconLookupPath(for bundleID: String) -> String?
    func displayName(for bundleID: String) -> String?
}

protocol GlobalTextSwitchExecuting {
    func executeSwitch(
        bundleID: String,
        coordinator: any GlobalTextSwitchCoordinating,
        completion: @escaping @MainActor (GlobalTextSwitchReport) -> Void
    )
}

final class BackgroundGlobalTextSwitchExecutor: GlobalTextSwitchExecuting {
    private let queue: OperationQueue

    init(queue: OperationQueue = BackgroundGlobalTextSwitchExecutor.makeQueue()) {
        self.queue = queue
    }

    func executeSwitch(
        bundleID: String,
        coordinator: any GlobalTextSwitchCoordinating,
        completion: @escaping @MainActor (GlobalTextSwitchReport) -> Void
    ) {
        queue.addOperation {
            let report = coordinator.apply(bundleID: bundleID)
            Task { @MainActor in
                completion(report)
            }
        }
    }

    private static func makeQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.name = "io.github.congbo.DefaultEditorSwitcher.switch"
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 1
        return queue
    }
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

struct SettingsRefreshStatus: Equatable {
    enum Phase: Equatable {
        case idle
        case refreshing
    }

    let phase: Phase
    let lastAttemptAt: Date?
    let lastErrorMessage: String?

    init(
        phase: Phase = .idle,
        lastAttemptAt: Date? = nil,
        lastErrorMessage: String? = nil
    ) {
        self.phase = phase
        self.lastAttemptAt = lastAttemptAt
        self.lastErrorMessage = lastErrorMessage
    }
}

struct MenuBarSwitchVerificationPolicy: Equatable {
    let initialPollIntervalNanoseconds: UInt64
    let initialMaxAttempts: Int
    let repairPollIntervalNanoseconds: UInt64
    let repairMaxAttempts: Int

    init(
        initialPollInterval: TimeInterval = 0.1,
        initialTimeout: TimeInterval = 1.5,
        repairPollInterval: TimeInterval = 0.2,
        repairTimeout: TimeInterval = 3
    ) {
        initialPollIntervalNanoseconds = Self.nanoseconds(for: initialPollInterval)
        initialMaxAttempts = Self.maxAttempts(
            pollInterval: initialPollInterval,
            timeout: initialTimeout
        )
        repairPollIntervalNanoseconds = Self.nanoseconds(for: repairPollInterval)
        repairMaxAttempts = Self.maxAttempts(
            pollInterval: repairPollInterval,
            timeout: repairTimeout
        )
    }

    private static func nanoseconds(for pollInterval: TimeInterval) -> UInt64 {
        UInt64(max(pollInterval, 0.01) * 1_000_000_000)
    }

    private static func maxAttempts(
        pollInterval: TimeInterval,
        timeout: TimeInterval
    ) -> Int {
        let sanitizedPollInterval = max(pollInterval, 0.01)
        let sanitizedTimeout = max(timeout, sanitizedPollInterval)
        return max(Int(ceil(sanitizedTimeout / sanitizedPollInterval)), 1)
    }
}

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published private(set) var summary: MenuBarSummary
    @Published private(set) var currentState: GlobalTextState?
    @Published private(set) var availableEditors: [EditorCandidate] = []
    @Published private(set) var sections: [MenuBarSection] = []
    @Published private(set) var lastSwitchReport: GlobalTextSwitchReport?
    @Published private(set) var lastSwitchFeedback: GlobalTextSwitchFeedback?
    @Published private(set) var applyingBundleID: String?
    @Published private(set) var statusItemIconLookupPath: String?
    @Published private(set) var primaryRows: [MenuBarEditorRow] = []
    @Published private(set) var overflowRows: [MenuBarEditorRow] = []
    @Published private(set) var settingsRefreshStatus = SettingsRefreshStatus()

    private let stateService: GlobalTextStateServicing
    private let appDiscovery: EditorDiscovering
    private let switchCoordinator: GlobalTextSwitchCoordinating?
    private let switchExecutor: any GlobalTextSwitchExecuting
    private let switchRefreshScheduler: any LaunchServicesRefreshScheduling
    private let applicationLocator: ApplicationLocating
    private let recommendedAppsStore: any RecommendedMenuAppsStoring
    private let globalTextTypesStore: any GlobalTextTypesStoring
    private let localizer: any AppTextLocalizing
    private let switchFeedbackFormatter: any GlobalTextSwitchFeedbackFormatting
    private let settingsActivityStore: SettingsActivityStore?
    private let switchVerificationPolicy: MenuBarSwitchVerificationPolicy
    private let switchVerificationSleeper: @Sendable (UInt64) async throws -> Void
    private var hasLoadedOnce = false
    private var cancellables: Set<AnyCancellable> = []
    private var switchVerificationTask: Task<Void, Never>?
    private var switchVerificationToken = UUID()

    init(
        stateService: GlobalTextStateServicing = GlobalTextStateService(),
        appDiscovery: EditorDiscovering = WorkspaceAppDiscovery(),
        switchCoordinator: GlobalTextSwitchCoordinating? = GlobalTextSwitchCoordinator(),
        switchExecutor: any GlobalTextSwitchExecuting = BackgroundGlobalTextSwitchExecutor(),
        switchRefreshScheduler: any LaunchServicesRefreshScheduling = LaunchServicesRefreshScheduler(),
        applicationLocator: ApplicationLocating = WorkspaceApplicationLocator(),
        recommendedAppsStore: any RecommendedMenuAppsStoring = TransientRecommendedMenuAppsStore(),
        globalTextTypesStore: any GlobalTextTypesStoring = TransientGlobalTextTypesStore(),
        localizer: any AppTextLocalizing = PassthroughLocalizer(),
        switchFeedbackFormatter: (any GlobalTextSwitchFeedbackFormatting)? = nil,
        settingsActivityStore: SettingsActivityStore? = nil,
        switchVerificationPolicy: MenuBarSwitchVerificationPolicy = MenuBarSwitchVerificationPolicy(),
        switchVerificationSleeper: @escaping @Sendable (UInt64) async throws -> Void = { nanoseconds in
            try await Task.sleep(nanoseconds: nanoseconds)
        }
    ) {
        self.stateService = stateService
        self.appDiscovery = appDiscovery
        self.switchCoordinator = switchCoordinator
        self.switchExecutor = switchExecutor
        self.switchRefreshScheduler = switchRefreshScheduler
        self.applicationLocator = applicationLocator
        self.recommendedAppsStore = recommendedAppsStore
        self.globalTextTypesStore = globalTextTypesStore
        self.localizer = localizer
        self.settingsActivityStore = settingsActivityStore
        self.switchVerificationPolicy = switchVerificationPolicy
        self.switchVerificationSleeper = switchVerificationSleeper
        self.switchFeedbackFormatter = switchFeedbackFormatter ?? GlobalTextSwitchFeedbackFormatter(
            localizer: localizer,
            applicationLocator: applicationLocator
        )
        self.summary = MenuBarSummary(
            title: localizer.string("Loading..."),
            detail: localizer.string("Checking the current global text default app.")
        )
        bindPreferenceUpdates()
    }

    var refreshActionTitle: String {
        localizer.string("Refresh")
    }

    var quitActionTitle: String {
        localizer.string("Quit")
    }

    var settingsLogEntries: [SettingsLogEntry] {
        Array((settingsActivityStore?.entries ?? []).reversed())
    }

    var isSettingsRefreshDisabled: Bool {
        settingsRefreshStatus.phase == .refreshing || applyingBundleID != nil
    }

    func loadIfNeeded() {
        guard !hasLoadedOnce else {
            return
        }

        load()
    }

    func refresh() {
        guard !isSettingsRefreshDisabled else {
            return
        }

        log(
            level: .info,
            category: .refresh,
            message: "Refreshing current editor state and installed editors."
        )
        settingsRefreshStatus = SettingsRefreshStatus(
            phase: .refreshing,
            lastAttemptAt: settingsRefreshStatus.lastAttemptAt,
            lastErrorMessage: nil
        )
        reloadAllData(source: .manualRefresh)
    }

    func load() {
        reloadAllData(source: .initialLoad)
    }

    private enum ReloadSource {
        case initialLoad
        case settingsChange
        case manualRefresh
    }

    private func reloadAllData(source: ReloadSource) {
        hasLoadedOnce = true
        cancelPendingSwitchVerification()

        do {
            let state = stateService.currentState()
            let candidates = deduplicatedCandidates(
                try appDiscovery.discoverEditors(for: .plainText, bucket: nil)
            )
            currentState = state
            availableEditors = candidates
            rebuildPresentation(state: state, candidates: candidates)

            if source == .manualRefresh {
                settingsRefreshStatus = SettingsRefreshStatus(
                    phase: .idle,
                    lastAttemptAt: .now,
                    lastErrorMessage: nil
                )
                log(
                    level: .info,
                    category: .refresh,
                    message: "Current editor state refreshed."
                )
            }
        } catch {
            if source == .manualRefresh {
                settingsRefreshStatus = SettingsRefreshStatus(
                    phase: .idle,
                    lastAttemptAt: .now,
                    lastErrorMessage: error.localizedDescription
                )
                log(
                    level: .error,
                    category: .refresh,
                    message: error.localizedDescription
                )
            }
        }
    }

    private func refreshStateOnly() {
        hasLoadedOnce = true

        let state = stateService.currentState()
        currentState = state
        rebuildPresentation(state: state, candidates: availableEditors)
    }

    private func rebuildPresentation(state: GlobalTextState, candidates: [EditorCandidate]) {
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

        if !hasLoadedOnce {
            reloadAllData(source: .initialLoad)
        }

        guard applyingBundleID == nil else {
            return
        }

        cancelPendingSwitchVerification()
        let requestedEditorName = displayName(for: bundleID, displayNames: displayNamesByBundleID(in: availableEditors))
        log(
            level: .info,
            category: .switching,
            message: "Switch requested for \(requestedEditorName).",
            targetDisplayName: requestedEditorName
        )
        applyingBundleID = bundleID
        if let currentState {
            rebuildPresentation(state: currentState, candidates: availableEditors)
        }

        switchExecutor.executeSwitch(bundleID: bundleID, coordinator: switchCoordinator) { [weak self] report in
            guard let self else {
                return
            }

            self.lastSwitchReport = report
            self.applyingBundleID = nil
            if report.pendingVerificationCount > 0,
               let currentState = self.currentState {
                self.switchRefreshScheduler.scheduleFastRefresh()
                let projectedState = self.projectedState(
                    from: currentState,
                    requestedBundleID: bundleID,
                    report: report
                )
                self.currentState = projectedState
                self.rebuildPresentation(state: projectedState, candidates: self.availableEditors)
                self.scheduleSwitchVerification(for: report)
            } else {
                self.refreshStateOnly()
            }
            self.logSwitchOutcome(for: report)
        }
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
                    "Current global text default app across %d declared text types.",
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
                detail: localizer.string("No declared text type currently reports a default app.")
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
                self.reloadAllData(source: .settingsChange)
            }
            .store(in: &cancellables)

        globalTextTypesStore.objectWillChangePublisher
            .sink { [weak self] in
                guard let self, self.hasLoadedOnce else { return }
                self.reloadAllData(source: .settingsChange)
            }
            .store(in: &cancellables)

        localizer.objectWillChangePublisher
            .sink { [weak self] in
                guard let self, self.hasLoadedOnce else { return }
                self.reloadAllData(source: .settingsChange)
            }
            .store(in: &cancellables)

        if let settingsActivityStore {
            settingsActivityStore.objectWillChange
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
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

    private func displayNamesByBundleID(in candidates: [EditorCandidate]) -> [String: String] {
        Dictionary(candidates.map { ($0.bundleID, $0.displayName) }, uniquingKeysWith: { first, _ in first })
    }

    private func scheduleSwitchVerification(for report: GlobalTextSwitchReport) {
        cancelPendingSwitchVerification()
        let token = UUID()
        switchVerificationToken = token
        switchVerificationTask = Task { [weak self] in
            await self?.runSwitchVerification(for: report, token: token)
        }
    }

    private func cancelPendingSwitchVerification() {
        switchVerificationTask?.cancel()
        switchVerificationTask = nil
        switchVerificationToken = UUID()
    }

    private func runSwitchVerification(
        for report: GlobalTextSwitchReport,
        token: UUID
    ) async {
        defer {
            if switchVerificationToken == token {
                switchVerificationTask = nil
            }
        }

        if let state = await verifiedState(
            for: report,
            pollIntervalNanoseconds: switchVerificationPolicy.initialPollIntervalNanoseconds,
            maxAttempts: switchVerificationPolicy.initialMaxAttempts
        ) {
            applyVerifiedSwitchState(state, for: report)
            return
        }

        guard !Task.isCancelled else {
            return
        }

        logSwitchVerificationRepairStarted(for: report)
        switchRefreshScheduler.scheduleRepairRefresh()

        if let state = await verifiedState(
            for: report,
            pollIntervalNanoseconds: switchVerificationPolicy.repairPollIntervalNanoseconds,
            maxAttempts: switchVerificationPolicy.repairMaxAttempts
        ) {
            applyVerifiedSwitchState(state, for: report)
            return
        }

        guard !Task.isCancelled else {
            return
        }

        lastSwitchReport = report
        logSwitchVerificationUnconfirmed(for: report)
    }

    private func verifiedState(
        for report: GlobalTextSwitchReport,
        pollIntervalNanoseconds: UInt64,
        maxAttempts: Int
    ) async -> GlobalTextState? {
        for attempt in 0..<maxAttempts {
            if Task.isCancelled {
                return nil
            }

            if attempt > 0 {
                do {
                    try await switchVerificationSleeper(pollIntervalNanoseconds)
                } catch {
                    return nil
                }
            }

            let state = stateService.currentState()
            if reportIsVerified(report, by: state) {
                return state
            }
        }

        return nil
    }

    private func applyVerifiedSwitchState(
        _ state: GlobalTextState,
        for report: GlobalTextSwitchReport
    ) {
        let verifiedReport = resolvedReport(from: report, using: state)
        lastSwitchReport = verifiedReport
        currentState = state
        rebuildPresentation(state: state, candidates: availableEditors)
        logSwitchVerificationConfirmed(for: report)
    }

    private func reportIsVerified(_ report: GlobalTextSwitchReport, by state: GlobalTextState) -> Bool {
        guard report.pendingVerificationCount > 0 else {
            return true
        }

        let bundleIDsByContentType = Dictionary(
            state.extensionAssociations.map { ($0.contentTypeIdentifier, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return report.failures
            .filter { $0.status == AssociationVerificationStatus.pendingVerification.rawValue }
            .allSatisfy { failure in
                resolvedBundleID(
                    for: failure,
                    associationsByContentType: bundleIDsByContentType,
                    fallbackBundleID: state.currentBundleID
                ) == report.requestedBundleID
            }
    }

    private func resolvedReport(
        from report: GlobalTextSwitchReport,
        using state: GlobalTextState
    ) -> GlobalTextSwitchReport {
        let associationsByContentType = Dictionary(
            state.extensionAssociations.map { ($0.contentTypeIdentifier, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        var matchedCount = report.matchedCount
        var failures: [GlobalTextSwitchReport.Failure] = []

        for failure in report.failures {
            guard failure.status == AssociationVerificationStatus.pendingVerification.rawValue else {
                failures.append(failure)
                continue
            }

            let effectiveBundleID = resolvedBundleID(
                for: failure,
                associationsByContentType: associationsByContentType,
                fallbackBundleID: state.currentBundleID
            )
            if effectiveBundleID == report.requestedBundleID {
                matchedCount += 1
                continue
            }

            failures.append(
                GlobalTextSwitchReport.Failure(
                    contentTypeIdentifier: failure.contentTypeIdentifier,
                    scopeLabel: failure.scopeLabel,
                    role: failure.role,
                    status: AssociationVerificationStatus.pendingVerification.rawValue,
                    effectiveBundleID: effectiveBundleID,
                    statusCode: nil,
                    diagnostic: failure.diagnostic
                )
            )
        }

        return GlobalTextSwitchReport(
            requestedBundleID: report.requestedBundleID,
            matchedCount: matchedCount,
            mismatchedCount: report.mismatchedCount,
            pendingVerificationCount: failures.filter {
                $0.status == AssociationVerificationStatus.pendingVerification.rawValue
            }.count,
            unsupportedCount: report.unsupportedCount,
            writeFailedCount: report.writeFailedCount,
            processedContentTypeIdentifiers: report.processedContentTypeIdentifiers,
            processedExtensions: report.processedExtensions,
            failures: failures
        )
    }

    private func projectedState(
        from state: GlobalTextState,
        requestedBundleID: String,
        report: GlobalTextSwitchReport
    ) -> GlobalTextState {
        let unsupportedContentTypeIdentifiers = Set(
            report.failures
                .filter { $0.status == AssociationVerificationStatus.unsupportedTarget.rawValue }
                .map(\.contentTypeIdentifier)
        )
        let updatedAssociations = state.extensionAssociations.map { association in
            let projectedBundleID = unsupportedContentTypeIdentifiers.contains(association.contentTypeIdentifier)
                ? association.bundleID
                : requestedBundleID
            return GlobalTextState.ExtensionAssociation(
                normalizedExtension: association.normalizedExtension,
                contentTypeIdentifier: association.contentTypeIdentifier,
                bundleID: projectedBundleID,
                allBundleID: unsupportedContentTypeIdentifiers.contains(association.contentTypeIdentifier)
                    ? association.allBundleID
                    : requestedBundleID,
                viewerBundleID: unsupportedContentTypeIdentifiers.contains(association.contentTypeIdentifier)
                    ? association.viewerBundleID
                    : requestedBundleID,
                editorBundleID: unsupportedContentTypeIdentifiers.contains(association.contentTypeIdentifier)
                    ? association.editorBundleID
                    : requestedBundleID
            )
        }
        let uniqueBundleIDs = orderedUnique(updatedAssociations.compactMap(\.bundleID))
        let status: GlobalTextState.Status

        if uniqueBundleIDs.isEmpty {
            status = .single(bundleID: requestedBundleID)
        } else if uniqueBundleIDs.count == 1 {
            status = .single(bundleID: uniqueBundleIDs[0])
        } else {
            status = .mixed(bundleIDs: uniqueBundleIDs)
        }

        return GlobalTextState(
            status: status,
            inspectedContentTypeIdentifiers: state.inspectedContentTypeIdentifiers,
            extensionAssociations: updatedAssociations,
            representativeBundleID: requestedBundleID
        )
    }

    private func orderedUnique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    private func log(
        level: SettingsLogEntry.Level,
        category: SettingsLogEntry.Category,
        message: String,
        targetDisplayName: String? = nil
    ) {
        settingsActivityStore?.log(
            level: level,
            category: category,
            message: message,
            targetDisplayName: targetDisplayName
        )
    }

    private func logSwitchVerificationRepairStarted(for report: GlobalTextSwitchReport) {
        let requestedEditorName = displayName(
            for: report.requestedBundleID,
            displayNames: displayNamesByBundleID(in: availableEditors)
        )
        log(
            level: .info,
            category: .switching,
            message: "Verification is taking longer than expected for \(requestedEditorName). Running a deeper Launch Services refresh.",
            targetDisplayName: requestedEditorName
        )
    }

    private func logSwitchVerificationConfirmed(for report: GlobalTextSwitchReport) {
        let requestedEditorName = displayName(
            for: report.requestedBundleID,
            displayNames: displayNamesByBundleID(in: availableEditors)
        )
        log(
            level: .info,
            category: .switching,
            message: "Background verification confirmed \(requestedEditorName).",
            targetDisplayName: requestedEditorName
        )
    }

    private func logSwitchVerificationUnconfirmed(for report: GlobalTextSwitchReport) {
        let requestedEditorName = displayName(
            for: report.requestedBundleID,
            displayNames: displayNamesByBundleID(in: availableEditors)
        )
        log(
            level: .warning,
            category: .switching,
            message: "macOS has not confirmed \(requestedEditorName) yet. The menu stays on the requested editor; use Refresh to check the live state.",
            targetDisplayName: requestedEditorName
        )
    }

    private func logSwitchOutcome(for report: GlobalTextSwitchReport) {
        let displayNames = displayNamesByBundleID(in: availableEditors)
        let requestedEditorName = displayName(for: report.requestedBundleID, displayNames: displayNames)

        if report.didFullyMatch {
            log(
                level: .info,
                category: .switching,
                message: "Updated all text types to \(requestedEditorName).",
                targetDisplayName: requestedEditorName
            )
            return
        }

        if report.pendingVerificationCount > 0, !report.hasBlockingFailures {
            log(
                level: .info,
                category: .switching,
                message: "Updated text types to \(requestedEditorName). Verifying system state in background.",
                targetDisplayName: requestedEditorName
            )
            return
        }

        let level = switchFailureLogLevel(for: report)
        let feedback = feedback(from: report, displayNames: displayNames)
        let summaryMessage = feedback?.headline ?? "Some text types could not switch to \(requestedEditorName)."
        log(
            level: level,
            category: .switching,
            message: summaryMessage,
            targetDisplayName: requestedEditorName
        )

        for detail in feedback?.details ?? [] {
            log(
                level: level,
                category: .switching,
                message: detail,
                targetDisplayName: requestedEditorName
            )
        }
    }

    private func switchFailureLogLevel(for report: GlobalTextSwitchReport) -> SettingsLogEntry.Level {
        if report.writeFailedCount == 0, report.mismatchedCount == 0, report.unsupportedCount > 0 {
            return .warning
        }

        return report.matchedCount > 0 ? .warning : .error
    }

    private func resolvedBundleID(
        for failure: GlobalTextSwitchReport.Failure,
        associationsByContentType: [String: GlobalTextState.ExtensionAssociation],
        fallbackBundleID: String?
    ) -> String? {
        guard let association = associationsByContentType[failure.contentTypeIdentifier] else {
            return fallbackBundleID
        }

        return association.bundleID(for: failure.role)
            ?? association.bundleID
            ?? fallbackBundleID
    }
}
