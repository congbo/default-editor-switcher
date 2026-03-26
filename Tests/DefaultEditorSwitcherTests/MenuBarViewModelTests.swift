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
        XCTAssertEqual(viewModel.currentState?.currentBundleID, "com.microsoft.VSCode")
        XCTAssertEqual(viewModel.availableEditors.map(\.bundleID), sampleCandidates.map(\.bundleID))
        XCTAssertEqual(stateService.loadCount, 3)
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
                    role: .viewer,
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
            applicationLocator: StubApplicationLocator(iconPathsByBundleID: [:])
        )

        failureViewModel.load()
        failureViewModel.applyEditor(bundleID: "com.example.partial")

        XCTAssertEqual(failureViewModel.lastSwitchReport, failureReport)
        XCTAssertEqual(
            failureViewModel.lastSwitchFeedback,
            GlobalTextSwitchFeedback(
                headline: "1 text types could not switch to Partial Editor.",
                details: [".md: Still opens in TextEdit."]
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
                                role: .viewer,
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

    func testOpenSettingsWindowActionIsExposed() {
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

        XCTAssertEqual(viewModel.settingsWindowAction.title, "Settings...")
        XCTAssertEqual(viewModel.settingsWindowAction.windowID, "settings-window")
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

    func testLocalizedMenuLabelsFollowSelectedAppLanguage() {
        let localizer = StubLocalizer(
            stringsByLanguage: [
                "en": [
                    "Settings...": "Settings...",
                    "No Global Editor Detected": "No Global Editor Detected",
                    "No declared text type currently reports an editor handler.": "No declared text type currently reports an editor handler.",
                ],
                "zh-Hans": [
                    "Settings...": "设置...",
                    "No Global Editor Detected": "未检测到全局编辑器",
                    "No declared text type currently reports an editor handler.": "当前没有已声明的文本类型报告编辑器处理器。",
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
        XCTAssertEqual(viewModel.settingsWindowAction.title, "Settings...")
        XCTAssertEqual(viewModel.summary.title, "No Global Editor Detected")

        localizer.languageCode = "zh-Hans"
        localizer.sendChange()

        XCTAssertEqual(viewModel.settingsWindowAction.title, "设置...")
        XCTAssertEqual(viewModel.summary.title, "未检测到全局编辑器")
    }

    func testAboutMenuTitleUsesLocalizedFormat() {
        let localizer = StubLocalizer(
            stringsByLanguage: [
                "en": ["About %@": "About %@"],
                "zh-Hans": ["About %@": "关于 %@"],
            ]
        )

        XCTAssertEqual(
            StandardAboutPanelConfiguration.menuTitle(
                localizer: localizer,
                applicationName: "Default Editor Switcher"
            ),
            "About Default Editor Switcher"
        )

        localizer.languageCode = "zh-Hans"

        XCTAssertEqual(
            StandardAboutPanelConfiguration.menuTitle(
                localizer: localizer,
                applicationName: "Default Editor Switcher"
            ),
            "关于 Default Editor Switcher"
        )
    }

    func testAboutPanelOptionsIncludeClickableProjectLinkCredits() throws {
        let localizer = StubLocalizer(
            stringsByLanguage: [
                "en": ["Project Home": "Project Home"],
            ]
        )

        let options = StandardAboutPanelConfiguration.options(
            localizer: localizer,
            applicationName: "Default Editor Switcher"
        )

        XCTAssertEqual(options[.applicationName] as? String, "Default Editor Switcher")

        let credits = try XCTUnwrap(options[.credits] as? NSAttributedString)
        XCTAssertEqual(
            credits.string,
            "Project Home\nhttps://github.com/congbo/default-editor-switcher"
        )

        let linkLocation = ("Project Home\n" as NSString).length
        XCTAssertEqual(
            credits.attribute(.link, at: linkLocation, effectiveRange: nil) as? URL,
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

private struct StubEditorDiscovery: EditorDiscovering {
    let candidates: [EditorCandidate]

    func discoverEditors(for contentType: UTType, bucket: LanguageBucket?) -> [EditorCandidate] {
        candidates
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
