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
        let coordinator = StubSwitchCoordinator(reportsByBundleID: ["com.microsoft.VSCode": report])
        let viewModel = MenuBarViewModel(
            stateService: stateService,
            appDiscovery: StubEditorDiscovery(candidates: sampleCandidates),
            switchCoordinator: coordinator,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        viewModel.load()
        viewModel.applyEditor(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(viewModel.lastSwitchReport, report)
        XCTAssertEqual(stateService.loadCount, 3)
        XCTAssertEqual(coordinator.appliedBundleIDs, ["com.microsoft.VSCode"])
    }

    func testApplyKeepsLatestReportWithoutPublishingMenuFeedback() {
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
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        successViewModel.load()
        successViewModel.applyEditor(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(successViewModel.lastSwitchReport, successReport)

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
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        failureViewModel.load()
        failureViewModel.applyEditor(bundleID: "com.example.partial")

        XCTAssertEqual(failureViewModel.lastSwitchReport, failureReport)
        XCTAssertEqual(failureViewModel.summary.title, "Partial Editor")
        XCTAssertTrue(
            failureViewModel.sections
                .flatMap(\.rows)
                .first(where: { $0.bundleID == "com.example.partial" })?
                .isCurrent == true
        )
    }

    func testOpenRulesWindowActionIsExposed() {
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

        XCTAssertEqual(viewModel.rulesWindowAction.title, "Settings...")
        XCTAssertEqual(viewModel.rulesWindowAction.windowID, "rules-window")
    }

    func testPrimaryRowsUseTopTwelveInstalledAvailableEditors() {
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
                "com.microsoft.VSCode",
                "com.apple.dt.Xcode",
                "com.sublimetext.4",
                "abnerworks.Typora",
                "com.macromates.TextMate",
            ]
        )
        XCTAssertEqual(
            viewModel.overflowRows.map(\.bundleID),
            [
                "com.coteditor.CotEditor",
                "com.apple.TextEdit",
                "com.openai.atlas",
            ]
        )
    }

    func testPrimaryRowsBackfillWithOtherEligibleEditorsWhenRecommendedListIsShort() {
        let candidates = Array(rankedMenuCandidates.prefix(10)) + [
            EditorCandidate(
                bundleID: "com.apple.TextEdit",
                displayName: "TextEdit",
                iconLookupPath: "/System/Applications/TextEdit.app",
                source: .systemEligible,
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
                bundleID: "com.example.notepad",
                displayName: "Notepad",
                iconLookupPath: "/Applications/Notepad.app",
                source: .systemEligible,
                capability: .full
            ),
        ]
        let viewModel = MenuBarViewModel(
            stateService: StubStateService(
                snapshots: [
                    GlobalTextState(status: .unavailable, inspectedContentTypeIdentifiers: ["public.plain-text"])
                ]
            ),
            appDiscovery: StubEditorDiscovery(candidates: candidates),
            switchCoordinator: nil,
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        viewModel.load()

        XCTAssertEqual(viewModel.primaryRows.count, 12)
        XCTAssertEqual(
            viewModel.primaryRows.suffix(2).map(\.bundleID),
            ["com.apple.TextEdit", "com.openai.atlas"]
        )
        XCTAssertEqual(viewModel.overflowRows.map(\.bundleID), ["com.example.notepad"])
    }

    func testCurrentEditorIsInjectedIntoPrimaryRowsWhenOutsideTopTwelve() {
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
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        viewModel.load()

        XCTAssertEqual(viewModel.primaryRows.first?.bundleID, "com.apple.TextEdit")
        XCTAssertTrue(viewModel.primaryRows.first?.isCurrent == true)
        XCTAssertEqual(viewModel.primaryRows.count, 12)
        XCTAssertFalse(viewModel.overflowRows.map(\.bundleID).contains("com.apple.TextEdit"))
        XCTAssertEqual(
            viewModel.overflowRows.map(\.bundleID),
            [
                "com.macromates.TextMate",
                "com.coteditor.CotEditor",
                "com.openai.atlas",
            ]
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
                bundleID: "com.apple.TextEdit",
                displayName: "TextEdit",
                iconLookupPath: "/System/Applications/TextEdit.app",
                source: .systemEligible,
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

private struct StubEditorDiscovery: EditorDiscovering {
    let candidates: [EditorCandidate]

    func discoverEditors(for contentType: UTType, bucket: LanguageBucket?) -> [EditorCandidate] {
        candidates
    }
}

private struct StubApplicationLocator: ApplicationLocating {
    let iconPathsByBundleID: [String: String]

    func iconLookupPath(for bundleID: String) -> String? {
        iconPathsByBundleID[bundleID]
    }
}

private final class StubSwitchCoordinator: GlobalTextSwitchCoordinating {
    private let reportsByBundleID: [String: GlobalTextSwitchReport]
    private(set) var appliedBundleIDs: [String] = []

    init(reportsByBundleID: [String: GlobalTextSwitchReport]) {
        self.reportsByBundleID = reportsByBundleID
    }

    func apply(bundleID: String) -> GlobalTextSwitchReport {
        appliedBundleIDs.append(bundleID)
        return reportsByBundleID[bundleID]
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
