import AppKit
import Combine
import XCTest
import UniformTypeIdentifiers
@testable import DefaultEditorSwitcher

@MainActor
final class MenuBarViewModelTests: XCTestCase {
    func testLoadsCurrentStateAndCandidateSections() {
        let stateService = StubStateService(
            snapshots: [
                GlobalTextState(
                    status: .single(bundleID: "com.microsoft.VSCode"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"]
                )
            ]
        )
        let viewModel = MenuBarViewModel(
            stateService: stateService,
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        viewModel.load()

        XCTAssertEqual(viewModel.summary.title, "Visual Studio Code")
        XCTAssertEqual(viewModel.currentState?.currentBundleID, "com.microsoft.VSCode")
        XCTAssertEqual(viewModel.availableEditors.map(\.bundleID), sampleCandidates.map(\.bundleID))
        XCTAssertEqual(viewModel.statusItemIconLookupPath, "/Applications/Visual Studio Code.app")
        XCTAssertEqual(viewModel.sections.map(\.id), ["recommendedFullSupport", "otherEligible", "needsVerification"])
        XCTAssertEqual(viewModel.sections[0].rows.first?.bundleID, "com.microsoft.VSCode")
        XCTAssertTrue(viewModel.sections[0].rows.first?.isCurrent == true)
    }

    func testRecommendedFullSupportCandidatesAppearBeforeLowerConfidenceSections() {
        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .unavailable, inspectedContentTypeIdentifiers: ["public.plain-text"])
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        viewModel.load()

        XCTAssertEqual(viewModel.sections.map(\.title), ["Recommended Editors", "Other Eligible Editors", "Needs Verification"])
        XCTAssertEqual(viewModel.sections[2].rows.map(\.capability), [.partial, .unverified])
    }

    func testDuplicateBundleIDsAreCollapsedBeforeBuildingMenuSections() {
        let duplicatedCandidates = [
            EditorCandidate(
                bundleID: "at.eggerapps.Postico",
                displayName: "Postico",
                source: .systemEligible,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "at.eggerapps.Postico",
                displayName: "Postico Duplicate",
                source: .systemEligible,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.microsoft.VSCode",
                displayName: "Visual Studio Code",
                source: .recommendedCatalog,
                capability: .full
            ),
        ]
        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .unavailable, inspectedContentTypeIdentifiers: ["public.plain-text"])
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: duplicatedCandidates),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        viewModel.load()

        XCTAssertEqual(viewModel.sections.map(\.title), ["Recommended Editors", "Other Eligible Editors"])
        XCTAssertEqual(viewModel.sections[1].rows.map(\.bundleID), ["at.eggerapps.Postico"])
        XCTAssertEqual(viewModel.sections[1].rows.map(\.displayName), ["Postico"])
    }

    func testSummaryFallsBackToApplicationLocatorDisplayName() {
        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(
                        status: .single(bundleID: "company.thebrowser.Browser"),
                        inspectedContentTypeIdentifiers: ["public.html"]
                    )
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: []),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(
                iconPathsByBundleID: ["company.thebrowser.Browser": "/Applications/TRAE.app"],
                displayNamesByBundleID: ["company.thebrowser.Browser": "TRAE"]
            )
        )

        viewModel.load()

        XCTAssertEqual(viewModel.summary.title, "TRAE")
        XCTAssertEqual(viewModel.statusItemIconLookupPath, "/Applications/TRAE.app")
    }

    func testGlobalTextTypePreferenceChangesTriggerReload() {
        let stateService = StubStateService(
            snapshots: [
                GlobalTextState(status: .single(bundleID: "com.apple.TextEdit"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
                GlobalTextState(status: .single(bundleID: "com.microsoft.VSCode"), inspectedContentTypeIdentifiers: ["public.plain-text", "public.css"]),
            ]
        )
        let globalTextTypesStore = StubGlobalTextTypesStore()
        let viewModel = MenuBarViewModel(
            stateService: stateService,
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            globalTextTypesStore: globalTextTypesStore
        )

        viewModel.load()
        globalTextTypesStore.sendChange()

        XCTAssertEqual(stateService.loadCount, 2)
        XCTAssertEqual(viewModel.currentState?.inspectedContentTypeIdentifiers, ["public.plain-text", "public.css"])
    }

    func testApplyEditorStoresLatestAggregateReportAndTriggersReload() {
        let report = GlobalTextSwitchReport(
            requestedBundleID: "com.microsoft.VSCode",
            matchedCount: 2,
            mismatchedCount: 0,
            unsupportedCount: 0,
            writeFailedCount: 0,
            processedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
            processedExtensions: ["txt", "md"],
            sampleFailures: []
        )
        let stateService = StubStateService(
            snapshots: [
                GlobalTextState(status: .single(bundleID: "com.apple.TextEdit"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
                GlobalTextState(status: .single(bundleID: "com.microsoft.VSCode"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
            ]
        )
        let editorDiscovery = SequenceEditorDiscovery(candidateSets: [sampleCandidates])
        let coordinator = StubSwitchCoordinator(reportsByBundleID: ["com.microsoft.VSCode": report])
        let viewModel = MenuBarViewModel(
            stateService: stateService,
            appDiscovery: editorDiscovery,
            switchCoordinator: coordinator,
            switchExecutor: ImmediateSwitchExecutor(),
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        viewModel.load()
        viewModel.applyEditor(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(viewModel.lastSwitchReport, report)
        XCTAssertEqual(viewModel.currentState?.currentBundleID, "com.microsoft.VSCode")
        XCTAssertEqual(viewModel.availableEditors.map(\.bundleID), sampleCandidates.map(\.bundleID))
        XCTAssertEqual(stateService.loadCount, 2)
        XCTAssertEqual(editorDiscovery.loadCount, 1)
        XCTAssertEqual(coordinator.appliedBundleIDs, ["com.microsoft.VSCode"])
    }

    func testApplyPublishesRecoveryFeedbackForFailedSwitches() {
        let successReport = GlobalTextSwitchReport(
            requestedBundleID: "com.microsoft.VSCode",
            matchedCount: 2,
            mismatchedCount: 0,
            unsupportedCount: 0,
            writeFailedCount: 0,
            processedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
            processedExtensions: ["txt", "md"],
            sampleFailures: []
        )
        let failureReport = GlobalTextSwitchReport(
            requestedBundleID: "com.example.partial",
            matchedCount: 1,
            mismatchedCount: 1,
            unsupportedCount: 0,
            writeFailedCount: 0,
            processedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
            processedExtensions: ["txt", "md"],
            sampleFailures: [
                .init(
                    contentTypeIdentifier: "net.daringfireball.markdown",
                    scopeLabel: ".md",
                    role: .editor,
                    status: "mismatched",
                    effectiveBundleID: "com.apple.TextEdit",
                    statusCode: nil
                )
            ]
        )

        let successViewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .single(bundleID: "com.apple.TextEdit"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
                    GlobalTextState(status: .single(bundleID: "com.microsoft.VSCode"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: StubSwitchCoordinator(reportsByBundleID: ["com.microsoft.VSCode": successReport]),
            switchExecutor: ImmediateSwitchExecutor(),
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        successViewModel.load()
        successViewModel.applyEditor(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(successViewModel.lastSwitchReport, successReport)
        XCTAssertNil(successViewModel.lastSwitchFeedback)

        let failureViewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .single(bundleID: "com.apple.TextEdit"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
                    GlobalTextState(
                        status: .mixed(bundleIDs: ["com.example.partial", "com.apple.TextEdit"]),
                        inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                        representativeBundleID: "com.example.partial"
                    ),
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: StubSwitchCoordinator(reportsByBundleID: ["com.example.partial": failureReport]),
            switchExecutor: ImmediateSwitchExecutor(),
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        failureViewModel.load()
        failureViewModel.applyEditor(bundleID: "com.example.partial")

        XCTAssertEqual(failureViewModel.lastSwitchReport, failureReport)
        XCTAssertEqual(
            failureViewModel.lastSwitchFeedback,
            GlobalTextSwitchFeedback(
                headline: "1 text types could not switch to Partial Editor.",
                details: [".md (editor): Still opens in TextEdit."]
            )
        )
        XCTAssertEqual(failureViewModel.summary.title, "Partial Editor")
        XCTAssertTrue(
            failureViewModel.sections
                .flatMap(\.rows)
                .first(where: { $0.bundleID == "com.example.partial" })?
                .isCurrent == true
        )
    }

    func testLaterSuccessfulApplyClearsStaleRecoveryFeedback() {
        let coordinator = StubSwitchCoordinator(
            reportsByBundleID: [
                "com.example.partial": [
                    GlobalTextSwitchReport(
                        requestedBundleID: "com.example.partial",
                        matchedCount: 1,
                        mismatchedCount: 1,
                        unsupportedCount: 0,
                        writeFailedCount: 0,
                        processedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                        processedExtensions: ["txt", "md"],
                        sampleFailures: [
                            .init(
                                contentTypeIdentifier: "net.daringfireball.markdown",
                                scopeLabel: ".md",
                                role: .editor,
                                status: "mismatched",
                                effectiveBundleID: "com.apple.TextEdit",
                                statusCode: nil
                            )
                        ]
                    ),
                    GlobalTextSwitchReport(
                        requestedBundleID: "com.example.partial",
                        matchedCount: 2,
                        mismatchedCount: 0,
                        unsupportedCount: 0,
                        writeFailedCount: 0,
                        processedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                        processedExtensions: ["txt", "md"],
                        sampleFailures: []
                    ),
                ]
            ]
        )
        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .single(bundleID: "com.apple.TextEdit"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
                    GlobalTextState(
                        status: .mixed(bundleIDs: ["com.example.partial", "com.apple.TextEdit"]),
                        inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                        representativeBundleID: "com.example.partial"
                    ),
                    GlobalTextState(status: .single(bundleID: "com.example.partial"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: coordinator,
            switchExecutor: ImmediateSwitchExecutor(),
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        viewModel.load()
        viewModel.applyEditor(bundleID: "com.example.partial")
        XCTAssertNotNil(viewModel.lastSwitchFeedback)
        XCTAssertEqual(viewModel.lastSwitchReport?.matchedCount, 1)

        viewModel.applyEditor(bundleID: "com.example.partial")
        XCTAssertNil(viewModel.lastSwitchFeedback)
        XCTAssertEqual(viewModel.lastSwitchReport?.matchedCount, 2)
    }

    func testApplyEditorMarksBusyImmediatelyWithoutRediscoveringEditors() {
        let report = GlobalTextSwitchReport(
            requestedBundleID: "com.microsoft.VSCode",
            matchedCount: 2,
            mismatchedCount: 0,
            unsupportedCount: 0,
            writeFailedCount: 0,
            processedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
            processedExtensions: ["txt", "md"],
            sampleFailures: []
        )
        let stateService = StubStateService(
            snapshots: [
                GlobalTextState(status: .single(bundleID: "com.apple.TextEdit"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
                GlobalTextState(status: .single(bundleID: "com.microsoft.VSCode"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
            ]
        )
        let editorDiscovery = SequenceEditorDiscovery(candidateSets: [sampleCandidates])
        let coordinator = StubSwitchCoordinator(reportsByBundleID: ["com.microsoft.VSCode": report])
        let switchExecutor = ControlledSwitchExecutor()
        let viewModel = MenuBarViewModel(
            stateService: stateService,
            appDiscovery: editorDiscovery,
            switchCoordinator: coordinator,
            switchExecutor: switchExecutor,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        viewModel.load()
        viewModel.applyEditor(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(viewModel.applyingBundleID, "com.microsoft.VSCode")
        XCTAssertEqual(stateService.loadCount, 1)
        XCTAssertEqual(editorDiscovery.loadCount, 1)
        XCTAssertTrue(
            viewModel.sections
                .flatMap(\.rows)
                .first(where: { $0.bundleID == "com.microsoft.VSCode" })?
                .isBusy == true
        )

        switchExecutor.runNext()

        XCTAssertNil(viewModel.applyingBundleID)
        XCTAssertEqual(viewModel.currentState?.currentBundleID, "com.microsoft.VSCode")
        XCTAssertEqual(stateService.loadCount, 2)
        XCTAssertEqual(editorDiscovery.loadCount, 1)
    }

    func testApplyEditorOptimisticallyUpdatesPresentationForPendingVerification() {
        let report = GlobalTextSwitchReport(
            requestedBundleID: "com.microsoft.VSCode",
            matchedCount: 1,
            mismatchedCount: 0,
            pendingVerificationCount: 1,
            unsupportedCount: 0,
            writeFailedCount: 0,
            processedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
            processedExtensions: ["txt", "md"],
            sampleFailures: [
                .init(
                    contentTypeIdentifier: "net.daringfireball.markdown",
                    scopeLabel: ".md",
                    role: .editor,
                    status: AssociationVerificationStatus.pendingVerification.rawValue,
                    effectiveBundleID: "com.apple.TextEdit",
                    statusCode: nil
                )
            ]
        )
        let activityStore = SettingsActivityStore()
        let refreshScheduler = StubLaunchServicesRefreshScheduler()
        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(
                        status: .mixed(bundleIDs: ["com.apple.TextEdit"]),
                        inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                        extensionAssociations: [
                            .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.microsoft.VSCode"),
                            .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                        ],
                        representativeBundleID: "com.microsoft.VSCode"
                    )
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: StubSwitchCoordinator(reportsByBundleID: ["com.microsoft.VSCode": report]),
            switchExecutor: ImmediateSwitchExecutor(),
            switchRefreshScheduler: refreshScheduler,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            settingsActivityStore: activityStore
        )

        viewModel.load()
        viewModel.applyEditor(bundleID: "com.microsoft.VSCode")

        XCTAssertNil(viewModel.applyingBundleID)
        XCTAssertEqual(viewModel.currentState?.currentBundleID, "com.microsoft.VSCode")
        XCTAssertEqual(viewModel.statusItemIconLookupPath, "/Applications/Visual Studio Code.app")
        XCTAssertTrue(
            viewModel.sections
                .flatMap(\.rows)
                .first(where: { $0.bundleID == "com.microsoft.VSCode" })?
                .isCurrent == true
        )
        XCTAssertNil(viewModel.lastSwitchFeedback)
        XCTAssertEqual(refreshScheduler.fastRefreshCount, 1)
        XCTAssertEqual(refreshScheduler.repairRefreshCount, 0)
        XCTAssertEqual(
            viewModel.settingsLogEntries.first?.message,
            "Updated text types to Visual Studio Code. Verifying system state in background."
        )
    }

    func testPendingVerificationEventuallyReconcilesWithoutManualRefresh() async {
        let report = GlobalTextSwitchReport(
            requestedBundleID: "com.microsoft.VSCode",
            matchedCount: 1,
            mismatchedCount: 0,
            pendingVerificationCount: 1,
            unsupportedCount: 0,
            writeFailedCount: 0,
            processedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
            processedExtensions: ["txt", "md"],
            sampleFailures: [
                .init(
                    contentTypeIdentifier: "net.daringfireball.markdown",
                    scopeLabel: ".md",
                    role: .editor,
                    status: AssociationVerificationStatus.pendingVerification.rawValue,
                    effectiveBundleID: "com.apple.TextEdit",
                    statusCode: nil
                )
            ]
        )
        let stateService = StubStateService(
            snapshots: [
                GlobalTextState(
                    status: .mixed(bundleIDs: ["com.microsoft.VSCode", "com.apple.TextEdit"]),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.microsoft.VSCode"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                    ],
                    representativeBundleID: "com.microsoft.VSCode"
                ),
                GlobalTextState(
                    status: .mixed(bundleIDs: ["com.microsoft.VSCode", "com.apple.TextEdit"]),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.microsoft.VSCode"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                    ],
                    representativeBundleID: "com.microsoft.VSCode"
                ),
                GlobalTextState(
                    status: .single(bundleID: "com.microsoft.VSCode"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.microsoft.VSCode"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.microsoft.VSCode"),
                    ],
                    representativeBundleID: "com.microsoft.VSCode"
                ),
            ]
        )
        let refreshScheduler = StubLaunchServicesRefreshScheduler()
        let viewModel = MenuBarViewModel(
            stateService: stateService,
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: StubSwitchCoordinator(reportsByBundleID: ["com.microsoft.VSCode": report]),
            switchExecutor: ImmediateSwitchExecutor(),
            switchRefreshScheduler: refreshScheduler,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            switchVerificationPolicy: MenuBarSwitchVerificationPolicy(
                initialPollInterval: 0.01,
                initialTimeout: 0.02,
                repairPollInterval: 0.01,
                repairTimeout: 0.02
            ),
            switchVerificationSleeper: { _ in }
        )

        viewModel.load()
        viewModel.applyEditor(bundleID: "com.microsoft.VSCode")
        await exhaustMainActorTurns()

        XCTAssertEqual(viewModel.currentState?.currentBundleID, "com.microsoft.VSCode")
        XCTAssertEqual(viewModel.lastSwitchReport?.pendingVerificationCount, 0)
        XCTAssertEqual(viewModel.lastSwitchReport?.mismatchedCount, 0)
        XCTAssertNil(viewModel.lastSwitchFeedback)
        XCTAssertEqual(refreshScheduler.fastRefreshCount, 1)
        XCTAssertEqual(refreshScheduler.repairRefreshCount, 0)
        XCTAssertEqual(stateService.loadCount, 3)
    }

    func testApplyEditorStillSchedulesRefreshWhenUnsupportedTypesRemain() {
        let report = GlobalTextSwitchReport(
            requestedBundleID: "com.microsoft.VSCode",
            matchedCount: 0,
            mismatchedCount: 0,
            pendingVerificationCount: 1,
            unsupportedCount: 1,
            writeFailedCount: 0,
            processedContentTypeIdentifiers: ["public.plain-text", "dyn.unresolved"],
            processedExtensions: ["txt", "conf"],
            sampleFailures: [
                .init(
                    contentTypeIdentifier: "public.plain-text",
                    scopeLabel: ".txt",
                    role: .all,
                    status: AssociationVerificationStatus.pendingVerification.rawValue,
                    effectiveBundleID: "com.apple.TextEdit",
                    statusCode: nil
                ),
                .init(
                    contentTypeIdentifier: "dyn.unresolved",
                    scopeLabel: ".conf",
                    role: .all,
                    status: AssociationVerificationStatus.unsupportedTarget.rawValue,
                    effectiveBundleID: nil,
                    statusCode: nil
                ),
            ]
        )
        let activityStore = SettingsActivityStore()
        let refreshScheduler = StubLaunchServicesRefreshScheduler()
        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(
                        status: .single(bundleID: "com.apple.TextEdit"),
                        inspectedContentTypeIdentifiers: ["public.plain-text", "dyn.unresolved"],
                        extensionAssociations: [
                            .init(
                                normalizedExtension: "txt",
                                contentTypeIdentifier: "public.plain-text",
                                bundleID: "com.apple.TextEdit",
                                allBundleID: "com.apple.TextEdit",
                                viewerBundleID: "com.apple.TextEdit",
                                editorBundleID: "com.apple.TextEdit"
                            ),
                            .init(
                                normalizedExtension: "conf",
                                contentTypeIdentifier: "dyn.unresolved",
                                bundleID: "com.apple.TextEdit",
                                allBundleID: "com.apple.TextEdit",
                                viewerBundleID: "com.apple.TextEdit",
                                editorBundleID: "com.apple.TextEdit"
                            ),
                        ],
                        representativeBundleID: "com.apple.TextEdit"
                    )
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: StubSwitchCoordinator(reportsByBundleID: ["com.microsoft.VSCode": report]),
            switchExecutor: ImmediateSwitchExecutor(),
            switchRefreshScheduler: refreshScheduler,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            settingsActivityStore: activityStore
        )

        viewModel.load()
        viewModel.applyEditor(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(refreshScheduler.fastRefreshCount, 1)
        XCTAssertEqual(viewModel.currentState?.currentBundleID, "com.microsoft.VSCode")
        XCTAssertNotNil(viewModel.lastSwitchFeedback)
        XCTAssertTrue(
            viewModel.settingsLogEntries.contains {
                $0.level == .warning
                    && $0.message == "1 text types could not switch to Visual Studio Code."
            }
        )
        XCTAssertTrue(
            activityStore.entries.contains {
                $0.level == .warning
                    && $0.message == ".conf: This editor does not support this type on this Mac. macOS only reports a dynamic UTI for this extension, so app matching is limited."
            }
        )
    }

    func testPendingVerificationTriggersRepairAndEventuallyReconciles() async {
        let report = GlobalTextSwitchReport(
            requestedBundleID: "com.microsoft.VSCode",
            matchedCount: 0,
            mismatchedCount: 0,
            pendingVerificationCount: 2,
            unsupportedCount: 0,
            writeFailedCount: 0,
            processedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
            processedExtensions: ["txt", "md"],
            sampleFailures: [
                .init(
                    contentTypeIdentifier: "public.plain-text",
                    scopeLabel: ".txt",
                    role: .editor,
                    status: AssociationVerificationStatus.pendingVerification.rawValue,
                    effectiveBundleID: "com.apple.TextEdit",
                    statusCode: nil
                ),
                .init(
                    contentTypeIdentifier: "net.daringfireball.markdown",
                    scopeLabel: ".md",
                    role: .editor,
                    status: AssociationVerificationStatus.pendingVerification.rawValue,
                    effectiveBundleID: "com.apple.TextEdit",
                    statusCode: nil
                )
            ]
        )
        let refreshScheduler = StubLaunchServicesRefreshScheduler()
        let stateService = StubStateService(
            snapshots: [
                GlobalTextState(
                    status: .single(bundleID: "com.apple.TextEdit"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.apple.TextEdit"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                    ],
                    representativeBundleID: "com.apple.TextEdit"
                ),
                GlobalTextState(
                    status: .single(bundleID: "com.apple.TextEdit"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.apple.TextEdit"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                    ],
                    representativeBundleID: "com.apple.TextEdit"
                ),
                GlobalTextState(
                    status: .single(bundleID: "com.apple.TextEdit"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.apple.TextEdit"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                    ],
                    representativeBundleID: "com.apple.TextEdit"
                ),
                GlobalTextState(
                    status: .mixed(bundleIDs: ["com.microsoft.VSCode", "com.apple.TextEdit"]),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.microsoft.VSCode"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                    ],
                    representativeBundleID: "com.microsoft.VSCode"
                ),
                GlobalTextState(
                    status: .single(bundleID: "com.microsoft.VSCode"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.microsoft.VSCode"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.microsoft.VSCode"),
                    ],
                    representativeBundleID: "com.microsoft.VSCode"
                ),
            ]
        )
        let viewModel = MenuBarViewModel(
            stateService: stateService,
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: StubSwitchCoordinator(reportsByBundleID: ["com.microsoft.VSCode": report]),
            switchExecutor: ImmediateSwitchExecutor(),
            switchRefreshScheduler: refreshScheduler,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            switchVerificationPolicy: MenuBarSwitchVerificationPolicy(
                initialPollInterval: 0.01,
                initialTimeout: 0.02,
                repairPollInterval: 0.01,
                repairTimeout: 0.02
            ),
            switchVerificationSleeper: { _ in }
        )

        viewModel.load()
        viewModel.applyEditor(bundleID: "com.microsoft.VSCode")
        await exhaustMainActorTurns()

        XCTAssertEqual(viewModel.currentState?.currentBundleID, "com.microsoft.VSCode")
        XCTAssertEqual(viewModel.lastSwitchReport?.pendingVerificationCount, 0)
        XCTAssertEqual(viewModel.lastSwitchReport?.mismatchedCount, 0)
        XCTAssertNil(viewModel.lastSwitchFeedback)
        XCTAssertEqual(refreshScheduler.fastRefreshCount, 1)
        XCTAssertEqual(refreshScheduler.repairRefreshCount, 1)
        XCTAssertEqual(stateService.loadCount, 5)
    }

    func testPendingVerificationTimeoutKeepsRequestedEditorAndLogsWarning() async {
        let report = GlobalTextSwitchReport(
            requestedBundleID: "com.microsoft.VSCode",
            matchedCount: 0,
            mismatchedCount: 0,
            pendingVerificationCount: 2,
            unsupportedCount: 0,
            writeFailedCount: 0,
            processedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
            processedExtensions: ["txt", "md"],
            sampleFailures: [
                .init(
                    contentTypeIdentifier: "public.plain-text",
                    scopeLabel: ".txt",
                    role: .editor,
                    status: AssociationVerificationStatus.pendingVerification.rawValue,
                    effectiveBundleID: "com.apple.TextEdit",
                    statusCode: nil
                ),
                .init(
                    contentTypeIdentifier: "net.daringfireball.markdown",
                    scopeLabel: ".md",
                    role: .editor,
                    status: AssociationVerificationStatus.pendingVerification.rawValue,
                    effectiveBundleID: "com.apple.TextEdit",
                    statusCode: nil
                )
            ]
        )
        let activityStore = SettingsActivityStore()
        let refreshScheduler = StubLaunchServicesRefreshScheduler()
        let stateService = StubStateService(
            snapshots: [
                GlobalTextState(
                    status: .single(bundleID: "com.apple.TextEdit"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.apple.TextEdit"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                    ],
                    representativeBundleID: "com.apple.TextEdit"
                ),
                GlobalTextState(
                    status: .single(bundleID: "com.apple.TextEdit"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.apple.TextEdit"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                    ],
                    representativeBundleID: "com.apple.TextEdit"
                ),
                GlobalTextState(
                    status: .single(bundleID: "com.apple.TextEdit"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.apple.TextEdit"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                    ],
                    representativeBundleID: "com.apple.TextEdit"
                ),
                GlobalTextState(
                    status: .single(bundleID: "com.apple.TextEdit"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.apple.TextEdit"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                    ],
                    representativeBundleID: "com.apple.TextEdit"
                ),
                GlobalTextState(
                    status: .single(bundleID: "com.apple.TextEdit"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.apple.TextEdit"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                    ],
                    representativeBundleID: "com.apple.TextEdit"
                ),
            ]
        )
        let viewModel = MenuBarViewModel(
            stateService: stateService,
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: StubSwitchCoordinator(reportsByBundleID: ["com.microsoft.VSCode": report]),
            switchExecutor: ImmediateSwitchExecutor(),
            switchRefreshScheduler: refreshScheduler,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            settingsActivityStore: activityStore,
            switchVerificationPolicy: MenuBarSwitchVerificationPolicy(
                initialPollInterval: 0.01,
                initialTimeout: 0.02,
                repairPollInterval: 0.01,
                repairTimeout: 0.02
            ),
            switchVerificationSleeper: { _ in }
        )

        viewModel.load()
        viewModel.applyEditor(bundleID: "com.microsoft.VSCode")
        await exhaustMainActorTurns()

        XCTAssertEqual(viewModel.currentState?.currentBundleID, "com.microsoft.VSCode")
        XCTAssertEqual(viewModel.lastSwitchReport?.pendingVerificationCount, 2)
        XCTAssertEqual(viewModel.lastSwitchReport?.mismatchedCount, 0)
        XCTAssertNil(viewModel.lastSwitchFeedback)
        XCTAssertEqual(viewModel.settingsLogEntries.first?.level, .warning)
        XCTAssertEqual(refreshScheduler.fastRefreshCount, 1)
        XCTAssertEqual(refreshScheduler.repairRefreshCount, 1)
        XCTAssertEqual(
            viewModel.settingsLogEntries.first?.message,
            "macOS has not confirmed Visual Studio Code yet. The menu stays on the requested editor; use Refresh to check the live state."
        )
    }

    func testManualRefreshCancelsPendingVerificationTask() async {
        let report = GlobalTextSwitchReport(
            requestedBundleID: "com.microsoft.VSCode",
            matchedCount: 0,
            mismatchedCount: 0,
            pendingVerificationCount: 2,
            unsupportedCount: 0,
            writeFailedCount: 0,
            processedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
            processedExtensions: ["txt", "md"],
            sampleFailures: [
                .init(
                    contentTypeIdentifier: "public.plain-text",
                    scopeLabel: ".txt",
                    role: .editor,
                    status: AssociationVerificationStatus.pendingVerification.rawValue,
                    effectiveBundleID: "com.apple.TextEdit",
                    statusCode: nil
                ),
                .init(
                    contentTypeIdentifier: "net.daringfireball.markdown",
                    scopeLabel: ".md",
                    role: .editor,
                    status: AssociationVerificationStatus.pendingVerification.rawValue,
                    effectiveBundleID: "com.apple.TextEdit",
                    statusCode: nil
                )
            ]
        )
        let blockingSleeper = BlockingVerificationSleeper()
        let refreshScheduler = StubLaunchServicesRefreshScheduler()
        let stateService = StubStateService(
            snapshots: [
                GlobalTextState(
                    status: .single(bundleID: "com.apple.TextEdit"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.apple.TextEdit"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                    ],
                    representativeBundleID: "com.apple.TextEdit"
                ),
                GlobalTextState(
                    status: .single(bundleID: "com.apple.TextEdit"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.apple.TextEdit"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                    ],
                    representativeBundleID: "com.apple.TextEdit"
                ),
                GlobalTextState(
                    status: .single(bundleID: "com.openai.atlas"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.openai.atlas"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.openai.atlas"),
                    ],
                    representativeBundleID: "com.openai.atlas"
                ),
                GlobalTextState(
                    status: .single(bundleID: "com.apple.TextEdit"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                    extensionAssociations: [
                        .init(normalizedExtension: "txt", contentTypeIdentifier: "public.plain-text", bundleID: "com.apple.TextEdit"),
                        .init(normalizedExtension: "md", contentTypeIdentifier: "net.daringfireball.markdown", bundleID: "com.apple.TextEdit"),
                    ],
                    representativeBundleID: "com.apple.TextEdit"
                ),
            ]
        )
        let viewModel = MenuBarViewModel(
            stateService: stateService,
            appDiscovery: SequenceEditorDiscovery(candidateSets: [sampleCandidates, sampleCandidates]),
            switchCoordinator: StubSwitchCoordinator(reportsByBundleID: ["com.microsoft.VSCode": report]),
            switchExecutor: ImmediateSwitchExecutor(),
            switchRefreshScheduler: refreshScheduler,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            switchVerificationPolicy: MenuBarSwitchVerificationPolicy(
                initialPollInterval: 0.01,
                initialTimeout: 0.02,
                repairPollInterval: 0.01,
                repairTimeout: 0.02
            ),
            switchVerificationSleeper: { nanoseconds in
                try await blockingSleeper.sleep(nanoseconds: nanoseconds)
            }
        )

        viewModel.load()
        viewModel.applyEditor(bundleID: "com.microsoft.VSCode")
        await exhaustMainActorTurns()
        viewModel.refresh()
        await blockingSleeper.resumeAll()
        await exhaustMainActorTurns()

        XCTAssertEqual(viewModel.currentState?.currentBundleID, "com.openai.atlas")
        XCTAssertEqual(refreshScheduler.fastRefreshCount, 1)
        XCTAssertEqual(refreshScheduler.repairRefreshCount, 0)
        XCTAssertEqual(stateService.loadCount, 3)
    }

    func testRefreshReloadsStateAndEditors() {
        let stateService = StubStateService(
            snapshots: [
                GlobalTextState(
                    status: .single(bundleID: "com.apple.TextEdit"),
                    inspectedContentTypeIdentifiers: ["public.plain-text"]
                ),
                GlobalTextState(
                    status: .single(bundleID: "com.microsoft.VSCode"),
                    inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"]
                ),
            ]
        )
        let editorDiscovery = SequenceEditorDiscovery(candidateSets: [
            [
                EditorCandidate(
                    bundleID: "com.apple.TextEdit",
                    displayName: "TextEdit",
                    iconLookupPath: "/System/Applications/TextEdit.app",
                    source: .recommendedCatalog,
                    capability: .full
                )
            ],
            [
                EditorCandidate(
                    bundleID: "com.microsoft.VSCode",
                    displayName: "Visual Studio Code",
                    iconLookupPath: "/Applications/Visual Studio Code.app",
                    source: .recommendedCatalog,
                    capability: .full
                ),
                EditorCandidate(
                    bundleID: "com.openai.atlas",
                    displayName: "ChatGPT Atlas",
                    iconLookupPath: "/Applications/ChatGPT Atlas.app",
                    source: .systemEligible,
                    capability: .full
                ),
            ],
        ])
        let viewModel = MenuBarViewModel(
            stateService: stateService,
            appDiscovery: editorDiscovery,
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        viewModel.load()
        XCTAssertEqual(viewModel.summary.title, "TextEdit")
        XCTAssertEqual(viewModel.availableEditors.map(\.bundleID), ["com.apple.TextEdit"])
        XCTAssertEqual(viewModel.primaryRows.map(\.bundleID), ["com.apple.TextEdit"])

        viewModel.refresh()

        XCTAssertEqual(viewModel.summary.title, "Visual Studio Code")
        XCTAssertEqual(
            viewModel.availableEditors.map(\.bundleID),
            ["com.microsoft.VSCode", "com.openai.atlas"]
        )
        XCTAssertEqual(viewModel.primaryRows.map(\.bundleID), ["com.microsoft.VSCode"])
        XCTAssertEqual(viewModel.overflowRows.map(\.bundleID), ["com.openai.atlas"])
        XCTAssertEqual(viewModel.statusItemIconLookupPath, "/Applications/Visual Studio Code.app")
        XCTAssertEqual(stateService.loadCount, 2)
        XCTAssertEqual(editorDiscovery.loadCount, 2)
    }

    func testRefreshRecordsLifecycleLogsNewestFirst() {
        let activityStore = SettingsActivityStore()
        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .single(bundleID: "com.apple.TextEdit"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
                    GlobalTextState(status: .single(bundleID: "com.microsoft.VSCode"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
                ]
            ),
            appDiscovery: SequenceEditorDiscovery(candidateSets: [
                sampleCandidates,
                sampleCandidates,
            ]),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            settingsActivityStore: activityStore
        )

        viewModel.load()
        viewModel.refresh()

        XCTAssertEqual(viewModel.settingsRefreshStatus.phase, .idle)
        XCTAssertNil(viewModel.settingsRefreshStatus.lastErrorMessage)
        XCTAssertNotNil(viewModel.settingsRefreshStatus.lastAttemptAt)
        XCTAssertEqual(viewModel.settingsLogEntries.map(\.category), [.refresh, .refresh])
        XCTAssertEqual(viewModel.settingsLogEntries.map(\.level), [.info, .info])
        XCTAssertEqual(viewModel.settingsLogEntries.first?.message, "Current editor state refreshed.")
        XCTAssertEqual(viewModel.settingsLogEntries.last?.message, "Refreshing current editor state and installed editors.")
    }

    func testRefreshFailureRecordsErrorAndRetainsPreviousState() {
        let activityStore = SettingsActivityStore()
        let stateService = StubStateService(
            snapshots: [
                GlobalTextState(status: .single(bundleID: "com.apple.TextEdit"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
                GlobalTextState(status: .single(bundleID: "com.microsoft.VSCode"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
            ]
        )
        let discovery = SequenceThrowingEditorDiscovery(results: [
            .success(sampleCandidates),
            .failure(StubEditorDiscoveryError.forcedFailure),
        ])
        let viewModel = MenuBarViewModel(
            stateService: stateService,
            appDiscovery: discovery,
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            settingsActivityStore: activityStore
        )

        viewModel.load()
        viewModel.refresh()

        XCTAssertEqual(viewModel.summary.title, "TextEdit")
        XCTAssertEqual(viewModel.currentState?.currentBundleID, "com.apple.TextEdit")
        XCTAssertEqual(viewModel.settingsRefreshStatus.phase, .idle)
        XCTAssertEqual(viewModel.settingsRefreshStatus.lastErrorMessage, StubEditorDiscoveryError.forcedFailure.localizedDescription)
        XCTAssertEqual(viewModel.settingsLogEntries.map(\.level), [.error, .info])
        XCTAssertEqual(viewModel.settingsLogEntries.first?.message, StubEditorDiscoveryError.forcedFailure.localizedDescription)
        XCTAssertEqual(stateService.loadCount, 2)
        XCTAssertEqual(discovery.loadCount, 2)
    }

    func testApplyEditorRecordsSwitchLifecycleLogs() {
        let activityStore = SettingsActivityStore()
        let report = GlobalTextSwitchReport(
            requestedBundleID: "com.microsoft.VSCode",
            matchedCount: 2,
            mismatchedCount: 0,
            unsupportedCount: 0,
            writeFailedCount: 0,
            processedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
            processedExtensions: ["txt", "md"],
            sampleFailures: []
        )
        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .single(bundleID: "com.apple.TextEdit"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
                    GlobalTextState(status: .single(bundleID: "com.microsoft.VSCode"), inspectedContentTypeIdentifiers: ["public.plain-text"]),
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: StubSwitchCoordinator(reportsByBundleID: ["com.microsoft.VSCode": report]),
            switchExecutor: ImmediateSwitchExecutor(),
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            settingsActivityStore: activityStore
        )

        viewModel.load()
        viewModel.applyEditor(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(viewModel.settingsLogEntries.map(\.category), [.switching, .switching])
        XCTAssertEqual(viewModel.settingsLogEntries.map(\.level), [.info, .info])
        XCTAssertEqual(viewModel.settingsLogEntries.first?.message, "Updated all text types to Visual Studio Code.")
        XCTAssertEqual(viewModel.settingsLogEntries.last?.message, "Switch requested for Visual Studio Code.")
    }

    func testSettingsLogRetentionTrimsOldestEntries() {
        let activityStore = SettingsActivityStore()
        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [GlobalTextState(status: .unavailable, inspectedContentTypeIdentifiers: ["public.plain-text"])]
            ),
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            settingsActivityStore: activityStore
        )

        for index in 0..<205 {
            activityStore.log(
                level: .info,
                category: .refresh,
                message: "log-\(index)",
                targetDisplayName: nil
            )
        }

        XCTAssertEqual(viewModel.settingsLogEntries.count, 200)
        XCTAssertEqual(viewModel.settingsLogEntries.first?.message, "log-204")
        XCTAssertEqual(viewModel.settingsLogEntries.last?.message, "log-5")
    }

    func testPrimaryRowsUseDefaultEnabledInstalledRecommendedEditors() {
        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .unavailable, inspectedContentTypeIdentifiers: ["public.plain-text"])
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: rankedMenuCandidates),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        viewModel.load()

        XCTAssertEqual(
            viewModel.primaryRows.map(\.bundleID),
            [
                "com.google.antigravity",
                "com.todesktop.230313mzl4w4u92",
                "dev.kiro.desktop",
                "com.exafunction.windsurf",
                "com.trae.app",
                "com.tencent.codebuddy",
                "dev.zed.Zed",
                "com.qoder.ide",
                "com.microsoft.VSCode",
                "com.apple.dt.Xcode",
                "com.sublimetext.4",
                "com.apple.TextEdit",
            ]
        )
        XCTAssertEqual(
            viewModel.overflowRows.map(\.bundleID),
            [
                "abnerworks.Typora",
                "com.macromates.TextMate",
                "com.coteditor.CotEditor",
                "com.openai.atlas",
            ]
        )
    }

    func testPrimaryRowsOnlyShowEnabledAvailableEditorsWithoutBackfill() {
        let userDefaults = UserDefaults(suiteName: #function)!
        userDefaults.removePersistentDomain(forName: #function)
        let store = RecommendedMenuAppsStore(userDefaults: userDefaults)
        for bundleID in KnownEditors.defaultEnabledRecommendedBundleIDs where bundleID != "com.microsoft.VSCode" {
            store.setEnabled(bundleID: bundleID, isEnabled: false)
        }

        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .unavailable, inspectedContentTypeIdentifiers: ["public.plain-text"])
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: [
                EditorCandidate(
                    bundleID: "com.microsoft.VSCode",
                    displayName: "Visual Studio Code",
                    iconLookupPath: "/Applications/Visual Studio Code.app",
                    source: .recommendedCatalog,
                    capability: .full
                ),
                EditorCandidate(
                    bundleID: "com.openai.atlas",
                    displayName: "ChatGPT Atlas",
                    iconLookupPath: "/Applications/ChatGPT Atlas.app",
                    source: .systemEligible,
                    capability: .full
                ),
            ]),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            recommendedAppsStore: store
        )

        viewModel.load()

        XCTAssertEqual(viewModel.primaryRows.map(\.bundleID), ["com.microsoft.VSCode"])
        XCTAssertEqual(viewModel.overflowRows.map(\.bundleID), ["com.openai.atlas"])
    }

    func testCurrentEditorRemainsInMoreWhenNotEnabledForFirstLevelMenu() {
        let userDefaults = UserDefaults(suiteName: #function)!
        userDefaults.removePersistentDomain(forName: #function)
        let store = RecommendedMenuAppsStore(userDefaults: userDefaults)
        store.setEnabled(bundleID: "com.apple.TextEdit", isEnabled: false)

        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(
                        status: .single(bundleID: "com.apple.TextEdit"),
                        inspectedContentTypeIdentifiers: ["public.plain-text"]
                    )
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: rankedMenuCandidates),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            recommendedAppsStore: store
        )

        viewModel.load()

        XCTAssertFalse(viewModel.primaryRows.map(\.bundleID).contains("com.apple.TextEdit"))
        XCTAssertEqual(
            viewModel.overflowRows.first(where: { $0.bundleID == "com.apple.TextEdit" })?.bundleID,
            "com.apple.TextEdit"
        )
        XCTAssertTrue(
            viewModel.overflowRows.first(where: { $0.bundleID == "com.apple.TextEdit" })?.isCurrent == true
        )
    }

    func testPrimaryRowsRespectConfiguredRecommendedAppOrder() {
        let userDefaults = UserDefaults(suiteName: #function)!
        userDefaults.removePersistentDomain(forName: #function)
        let store = RecommendedMenuAppsStore(userDefaults: userDefaults)
        store.move(bundleID: "com.microsoft.VSCode", beforeBundleID: "com.google.antigravity")
        store.move(bundleID: "dev.zed.Zed", beforeBundleID: "com.google.antigravity")

        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .unavailable, inspectedContentTypeIdentifiers: ["public.plain-text"])
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: rankedMenuCandidates),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            recommendedAppsStore: store
        )

        viewModel.load()

        XCTAssertEqual(
            Array(viewModel.primaryRows.prefix(3).map(\.bundleID)),
            ["com.microsoft.VSCode", "dev.zed.Zed", "com.google.antigravity"]
        )
    }

    func testPrimaryRowsSkipDisabledRecommendedEditorsAfterRecommendationUpdate() {
        let userDefaults = UserDefaults(suiteName: #function)!
        userDefaults.removePersistentDomain(forName: #function)
        let store = RecommendedMenuAppsStore(userDefaults: userDefaults)
        store.setEnabled(bundleID: "com.google.antigravity", isEnabled: false)
        store.move(bundleID: "com.microsoft.VSCode", beforeBundleID: "com.google.antigravity")

        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .unavailable, inspectedContentTypeIdentifiers: ["public.plain-text"])
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: rankedMenuCandidates),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            recommendedAppsStore: store
        )

        viewModel.load()

        XCTAssertEqual(viewModel.primaryRows.first?.bundleID, "com.microsoft.VSCode")
        XCTAssertFalse(viewModel.primaryRows.map(\.bundleID).contains("com.google.antigravity"))
    }

    func testPrimaryRowsReactImmediatelyToRecommendationUpdates() {
        let userDefaults = UserDefaults(suiteName: #function)!
        userDefaults.removePersistentDomain(forName: #function)
        let store = RecommendedMenuAppsStore(userDefaults: userDefaults)
        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .unavailable, inspectedContentTypeIdentifiers: ["public.plain-text"]),
                    GlobalTextState(status: .unavailable, inspectedContentTypeIdentifiers: ["public.plain-text"]),
                    GlobalTextState(status: .unavailable, inspectedContentTypeIdentifiers: ["public.plain-text"]),
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: rankedMenuCandidates),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            recommendedAppsStore: store
        )

        viewModel.load()
        store.move(bundleID: "com.microsoft.VSCode", beforeBundleID: "com.google.antigravity")
        store.setEnabled(bundleID: "com.google.antigravity", isEnabled: false)

        XCTAssertEqual(viewModel.primaryRows.first?.bundleID, "com.microsoft.VSCode")
        XCTAssertFalse(viewModel.primaryRows.map(\.bundleID).contains("com.google.antigravity"))
    }

    func testUserEnabledSystemDiscoveredEditorAppearsInPrimaryRows() {
        let userDefaults = UserDefaults(suiteName: #function)!
        userDefaults.removePersistentDomain(forName: #function)
        let store = RecommendedMenuAppsStore(userDefaults: userDefaults)
        store.setEnabled(bundleID: "com.openai.atlas", isEnabled: true)

        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .unavailable, inspectedContentTypeIdentifiers: ["public.plain-text"])
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: [
                EditorCandidate(
                    bundleID: "com.microsoft.VSCode",
                    displayName: "Visual Studio Code",
                    iconLookupPath: "/Applications/Visual Studio Code.app",
                    source: .recommendedCatalog,
                    capability: .full
                ),
                EditorCandidate(
                    bundleID: "com.openai.atlas",
                    displayName: "ChatGPT Atlas",
                    iconLookupPath: "/Applications/ChatGPT Atlas.app",
                    source: .systemEligible,
                    capability: .full
                ),
            ]),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            recommendedAppsStore: store
        )

        viewModel.load()

        XCTAssertEqual(viewModel.primaryRows.map(\.bundleID), ["com.microsoft.VSCode", "com.openai.atlas"])
        XCTAssertTrue(viewModel.overflowRows.isEmpty)
    }

    func testLocalizedMenuLabelsFollowSelectedAppLanguage() {
        let localizer = StubLocalizer(
            stringsByLanguage: [
                "en": [
                    "Refresh": "Refresh",
                    "Quit": "Quit",
                    "No Global Editor Detected": "No Global Editor Detected",
                    "No declared text type currently reports a default app.": "No declared text type currently reports a default app.",
                ],
                "zh-Hans": [
                    "Refresh": "刷新",
                    "Quit": "退出",
                    "No Global Editor Detected": "未检测到全局编辑器",
                    "No declared text type currently reports a default app.": "当前没有已声明的文本类型报告默认应用。",
                ],
            ]
        )
        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .unavailable, inspectedContentTypeIdentifiers: ["public.plain-text"]),
                    GlobalTextState(status: .unavailable, inspectedContentTypeIdentifiers: ["public.plain-text"]),
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:]),
            localizer: localizer
        )

        viewModel.load()
        XCTAssertEqual(viewModel.refreshActionTitle, "Refresh")
        XCTAssertEqual(viewModel.quitActionTitle, "Quit")
        XCTAssertEqual(viewModel.summary.title, "No Global Editor Detected")

        localizer.languageCode = "zh-Hans"
        localizer.sendChange()

        XCTAssertEqual(viewModel.refreshActionTitle, "刷新")
        XCTAssertEqual(viewModel.quitActionTitle, "退出")
        XCTAssertEqual(viewModel.summary.title, "未检测到全局编辑器")
    }

    func testAboutMenuTitleUsesLocalizedFormat() {
        let localizer = StubLocalizer(
            stringsByLanguage: [
                "en": ["About": "About"],
                "zh-Hans": ["About": "关于"],
            ]
        )

        XCTAssertEqual(
            StandardAboutPanelConfiguration.menuTitle(localizer: localizer),
            "About"
        )

        localizer.languageCode = "zh-Hans"

        XCTAssertEqual(
            StandardAboutPanelConfiguration.menuTitle(localizer: localizer),
            "关于"
        )
    }

    func testAboutPanelOptionsIncludeClickableProjectLinkCredits() throws {
        let localizer = StubLocalizer(stringsByLanguage: [:])

        let options = StandardAboutPanelConfiguration.options(
            localizer: localizer,
            applicationName: "Default Editor Switcher"
        )

        XCTAssertEqual(options[.applicationName] as? String, "Default Editor Switcher")

        let credits = try XCTUnwrap(options[.credits] as? NSAttributedString)
        XCTAssertEqual(
            credits.string,
            "https://github.com/congbo/default-editor-switcher"
        )

        XCTAssertEqual(
            credits.attribute(.link, at: 0, effectiveRange: nil) as? URL,
            StandardAboutPanelConfiguration.projectURL
        )
        XCTAssertEqual(
            (credits.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?.alignment,
            .center
        )
    }

    private var sampleCandidates: [EditorCandidate] {
        [
            EditorCandidate(
                bundleID: "com.microsoft.VSCode",
                displayName: "Visual Studio Code",
                iconLookupPath: "/Applications/Visual Studio Code.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.apple.TextEdit",
                displayName: "TextEdit",
                iconLookupPath: "/System/Applications/TextEdit.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.openai.atlas",
                displayName: "ChatGPT Atlas",
                iconLookupPath: "/Applications/ChatGPT Atlas.app",
                source: .systemEligible,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.example.partial",
                displayName: "Partial Editor",
                iconLookupPath: "/Applications/Partial Editor.app",
                source: .systemEligible,
                capability: .partial
            ),
            EditorCandidate(
                bundleID: "com.example.unknown",
                displayName: "Unknown Editor",
                iconLookupPath: "/Applications/Unknown Editor.app",
                source: .systemEligible,
                capability: .unverified
            ),
        ]
    }

    private var rankedMenuCandidates: [EditorCandidate] {
        [
            EditorCandidate(
                bundleID: "com.google.antigravity",
                displayName: "Antigravity",
                iconLookupPath: "/Applications/Antigravity.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.todesktop.230313mzl4w4u92",
                displayName: "Cursor",
                iconLookupPath: "/Applications/Cursor.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "dev.kiro.desktop",
                displayName: "Kiro",
                iconLookupPath: "/Applications/Kiro.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.exafunction.windsurf",
                displayName: "Windsurf",
                iconLookupPath: "/Applications/Windsurf.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.trae.app",
                displayName: "Trae",
                iconLookupPath: "/Applications/Trae.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.tencent.codebuddy",
                displayName: "CodeBuddy",
                iconLookupPath: "/Applications/CodeBuddy.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "dev.zed.Zed",
                displayName: "Zed",
                iconLookupPath: "/Applications/Zed.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.qoder.ide",
                displayName: "Qoder",
                iconLookupPath: "/Applications/Qoder.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.microsoft.VSCode",
                displayName: "Visual Studio Code",
                iconLookupPath: "/Applications/Visual Studio Code.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.apple.dt.Xcode",
                displayName: "Xcode",
                iconLookupPath: "/Applications/Xcode.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.sublimetext.4",
                displayName: "Sublime Text",
                iconLookupPath: "/Applications/Sublime Text.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.apple.TextEdit",
                displayName: "TextEdit",
                iconLookupPath: "/System/Applications/TextEdit.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "abnerworks.Typora",
                displayName: "Typora",
                iconLookupPath: "/Applications/Typora.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.macromates.TextMate",
                displayName: "TextMate",
                iconLookupPath: "/Applications/TextMate.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.coteditor.CotEditor",
                displayName: "CotEditor",
                iconLookupPath: "/Applications/CotEditor.app",
                source: .recommendedCatalog,
                capability: .full
            ),
            EditorCandidate(
                bundleID: "com.openai.atlas",
                displayName: "ChatGPT Atlas",
                iconLookupPath: "/Applications/ChatGPT Atlas.app",
                source: .systemEligible,
                capability: .full
            ),
        ]
    }
}

private final class StubStateService: GlobalTextStateServicing {
    private let snapshots: [GlobalTextState]
    private(set) var loadCount = 0

    init(snapshots: [GlobalTextState]) {
        self.snapshots = snapshots
    }

    func currentState() -> GlobalTextState {
        defer { loadCount += 1 }
        return snapshots[min(loadCount, snapshots.count - 1)]
    }
}

private actor BlockingVerificationSleeper {
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func sleep(nanoseconds _: UInt64) async throws {
        if Task.isCancelled {
            throw CancellationError()
        }

        await withCheckedContinuation { continuation in
            continuations.append(continuation)
        }

        if Task.isCancelled {
            throw CancellationError()
        }
    }

    func resumeAll() {
        let pendingContinuations = continuations
        continuations.removeAll()
        for continuation in pendingContinuations {
            continuation.resume()
        }
    }
}

private func exhaustMainActorTurns(count: Int = 8) async {
    for _ in 0..<count {
        await Task.yield()
    }
}

private struct StubEditorDiscovery: EditorDiscovering {
    let candidates: [EditorCandidate]

    func discoverEditors(for contentType: UTType, bucket: LanguageBucket?) throws -> [EditorCandidate] {
        candidates
    }
}

private final class SequenceEditorDiscovery: EditorDiscovering {
    private let candidateSets: [[EditorCandidate]]
    private(set) var loadCount = 0

    init(candidateSets: [[EditorCandidate]]) {
        self.candidateSets = candidateSets
    }

    func discoverEditors(for contentType: UTType, bucket: LanguageBucket?) throws -> [EditorCandidate] {
        defer { loadCount += 1 }
        return candidateSets[min(loadCount, candidateSets.count - 1)]
    }
}

private final class SequenceThrowingEditorDiscovery: EditorDiscovering {
    private let results: [Result<[EditorCandidate], Error>]
    private(set) var loadCount = 0

    init(results: [Result<[EditorCandidate], Error>]) {
        self.results = results
    }

    func discoverEditors(for contentType: UTType, bucket: LanguageBucket?) throws -> [EditorCandidate] {
        defer { loadCount += 1 }
        return try results[min(loadCount, results.count - 1)].get()
    }
}

private enum StubEditorDiscoveryError: LocalizedError {
    case forcedFailure

    var errorDescription: String? {
        "Editor discovery failed."
    }
}

private struct StubApplicationLocator: ApplicationLocating {
    let iconPathsByBundleID: [String: String]
    let displayNamesByBundleID: [String: String]

    init(
        iconPathsByBundleID: [String: String],
        displayNamesByBundleID: [String: String] = [:]
    ) {
        self.iconPathsByBundleID = iconPathsByBundleID
        self.displayNamesByBundleID = displayNamesByBundleID
    }

    func iconLookupPath(for bundleID: String) -> String? {
        iconPathsByBundleID[bundleID]
    }

    func displayName(for bundleID: String) -> String? {
        displayNamesByBundleID[bundleID]
    }
}

private final class StubSwitchCoordinator: GlobalTextSwitchCoordinating {
    private let reportsByBundleID: [String: [GlobalTextSwitchReport]]
    private var applyCountsByBundleID: [String: Int] = [:]
    private(set) var appliedBundleIDs: [String] = []

    convenience init(reportsByBundleID: [String: GlobalTextSwitchReport]) {
        self.init(reportsByBundleID: reportsByBundleID.mapValues { [$0] })
    }

    init(reportsByBundleID: [String: [GlobalTextSwitchReport]]) {
        self.reportsByBundleID = reportsByBundleID
    }

    func apply(bundleID: String) -> GlobalTextSwitchReport {
        appliedBundleIDs.append(bundleID)
        let index = applyCountsByBundleID[bundleID, default: 0]
        applyCountsByBundleID[bundleID] = index + 1

        return reportsByBundleID[bundleID]?[min(index, (reportsByBundleID[bundleID]?.count ?? 1) - 1)]
            ?? GlobalTextSwitchReport(
                requestedBundleID: bundleID,
                matchedCount: 0,
                mismatchedCount: 0,
                unsupportedCount: 0,
                writeFailedCount: 0,
                processedContentTypeIdentifiers: [],
                processedExtensions: [],
                sampleFailures: []
            )
    }
}

private final class StubLaunchServicesRefreshScheduler: LaunchServicesRefreshScheduling {
    private(set) var fastRefreshCount = 0
    private(set) var repairRefreshCount = 0

    func scheduleFastRefresh() {
        fastRefreshCount += 1
    }

    func scheduleRepairRefresh() {
        repairRefreshCount += 1
    }
}

private struct ImmediateSwitchExecutor: GlobalTextSwitchExecuting {
    func executeSwitch(
        bundleID: String,
        coordinator: any GlobalTextSwitchCoordinating,
        completion: @escaping @MainActor (GlobalTextSwitchReport) -> Void
    ) {
        let report = coordinator.apply(bundleID: bundleID)
        MainActor.assumeIsolated {
            completion(report)
        }
    }
}

private final class ControlledSwitchExecutor: GlobalTextSwitchExecuting {
    private var pendingOperations: [() -> Void] = []

    func executeSwitch(
        bundleID: String,
        coordinator: any GlobalTextSwitchCoordinating,
        completion: @escaping @MainActor (GlobalTextSwitchReport) -> Void
    ) {
        pendingOperations.append {
            let report = coordinator.apply(bundleID: bundleID)
            MainActor.assumeIsolated {
                completion(report)
            }
        }
    }

    func runNext() {
        pendingOperations.removeFirst()()
    }
}

private final class StubLocalizer: AppTextLocalizing {
    var languageCode: String = "en"
    let stringsByLanguage: [String: [String: String]]
    private let subject = PassthroughSubject<Void, Never>()

    init(stringsByLanguage: [String: [String: String]]) {
        self.stringsByLanguage = stringsByLanguage
    }

    var objectWillChangePublisher: AnyPublisher<Void, Never> {
        subject.eraseToAnyPublisher()
    }

    func string(_ key: String) -> String {
        stringsByLanguage[languageCode]?[key] ?? key
    }

    func formattedString(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: Locale(identifier: languageCode), arguments: arguments)
    }

    func sendChange() {
        subject.send(())
    }
}

private final class StubGlobalTextTypesStore: GlobalTextTypesStoring {
    private let subject = PassthroughSubject<Void, Never>()

    var objectWillChangePublisher: AnyPublisher<Void, Never> {
        subject.eraseToAnyPublisher()
    }

    func enabledExtensions() -> Set<String> {
        ContentTypeResolver.defaultEnabledGlobalTextExtensions
    }

    func sendChange() {
        subject.send(())
    }
}
