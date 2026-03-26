import Combine
import XCTest
@testable import DefaultEditorSwitcher

@MainActor
final class SettingsCopyFormatterTests: XCTestCase {
    func testStatusSnapshotUsesSingleStateSummaryWithExamples() {
        let formatter = SettingsCopyFormatter(
            localizer: StubSettingsLocalizer(
                strings: [
                    "Current editor covers %d declared text extensions, for example %@.": "当前应用覆盖 %d 个已声明文本扩展名，例如 %@。",
                ]
            ),
            applicationLocator: StubSettingsApplicationLocator(
                iconPathsByBundleID: ["com.microsoft.VSCode": "/Applications/Visual Studio Code.app"]
            )
        )

        let snapshot = formatter.statusSnapshot(
            from: GlobalTextState(
                status: .single(bundleID: "com.microsoft.VSCode"),
                inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                extensionAssociations: [
                    .init(
                        normalizedExtension: "txt",
                        contentTypeIdentifier: "public.plain-text",
                        bundleID: "com.microsoft.VSCode"
                    ),
                    .init(
                        normalizedExtension: "md",
                        contentTypeIdentifier: "net.daringfireball.markdown",
                        bundleID: "com.microsoft.VSCode"
                    ),
                ]
            ),
            lastSwitchReport: nil,
            availableEditors: [
                EditorCandidate(
                    bundleID: "com.microsoft.VSCode",
                    displayName: "Visual Studio Code",
                    iconLookupPath: "/Applications/Visual Studio Code.app",
                    source: .recommendedCatalog,
                    capability: .full
                )
            ]
        )

        XCTAssertEqual(snapshot.title, "Visual Studio Code")
        XCTAssertEqual(snapshot.summary, "当前应用覆盖 2 个已声明文本扩展名，例如 .md, .txt。")
        XCTAssertEqual(snapshot.iconLookupPath, "/Applications/Visual Studio Code.app")
        XCTAssertTrue(snapshot.distributionGroups.isEmpty)
        XCTAssertTrue(snapshot.pendingGroups.isEmpty)
        XCTAssertNil(snapshot.recentSwitch)
    }

    func testStatusSnapshotGroupsMixedStateExtensionsByEditor() {
        let formatter = SettingsCopyFormatter(localizer: StubSettingsLocalizer(
            strings: [
                "Declared text types are currently split across multiple editors.": "已声明文本类型当前分散在多个编辑器中。",
            ]
        ))

        let snapshot = formatter.statusSnapshot(
            from: GlobalTextState(
                status: .mixed(bundleIDs: ["com.microsoft.VSCode", "com.apple.TextEdit"]),
                inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                extensionAssociations: [
                    .init(
                        normalizedExtension: "txt",
                        contentTypeIdentifier: "public.plain-text",
                        bundleID: "com.microsoft.VSCode"
                    ),
                    .init(
                        normalizedExtension: "md",
                        contentTypeIdentifier: "net.daringfireball.markdown",
                        bundleID: "com.apple.TextEdit"
                    ),
                    .init(
                        normalizedExtension: "json",
                        contentTypeIdentifier: "public.json",
                        bundleID: "com.microsoft.VSCode"
                    ),
                ],
                representativeBundleID: "com.microsoft.VSCode"
            ),
            lastSwitchReport: nil,
            availableEditors: [
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
            ]
        )

        XCTAssertEqual(snapshot.title, "Visual Studio Code")
        XCTAssertEqual(snapshot.summary, "已声明文本类型当前分散在多个编辑器中。")
        XCTAssertEqual(snapshot.distributionGroups.map(\.displayName), ["Visual Studio Code", "TextEdit"])
        XCTAssertEqual(snapshot.distributionGroups[0].extensions, [".json", ".txt"])
        XCTAssertEqual(snapshot.distributionGroups[1].extensions, [".md"])
        XCTAssertTrue(snapshot.pendingGroups.isEmpty)
    }

    func testStatusSnapshotMovesMissingHandlersIntoPendingAssignmentGroup() {
        let formatter = SettingsCopyFormatter(localizer: StubSettingsLocalizer(
            strings: [
                "Current editor covers %d declared text extensions, for example %@.": "当前应用覆盖 %d 个已声明文本扩展名，例如 %@。",
                "%d extensions are still missing a default app.": "%d 个扩展名仍未检测到默认应用。",
            ]
        ))

        let snapshot = formatter.statusSnapshot(
            from: GlobalTextState(
                status: .single(bundleID: "com.microsoft.VSCode"),
                inspectedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                extensionAssociations: [
                    .init(
                        normalizedExtension: "txt",
                        contentTypeIdentifier: "public.plain-text",
                        bundleID: "com.microsoft.VSCode"
                    ),
                    .init(
                        normalizedExtension: "md",
                        contentTypeIdentifier: "net.daringfireball.markdown",
                        bundleID: nil
                    ),
                    .init(
                        normalizedExtension: "fish",
                        contentTypeIdentifier: "public.shell-script",
                        bundleID: nil
                    ),
                ]
            ),
            lastSwitchReport: nil,
            availableEditors: [
                EditorCandidate(
                    bundleID: "com.microsoft.VSCode",
                    displayName: "Visual Studio Code",
                    iconLookupPath: "/Applications/Visual Studio Code.app",
                    source: .recommendedCatalog,
                    capability: .full
                )
            ]
        )

        XCTAssertEqual(snapshot.summary, "当前应用覆盖 3 个已声明文本扩展名，例如 .fish, .md, .txt。")
        XCTAssertEqual(
            snapshot.pendingGroups,
            [
                SettingsStatusGroup(
                    title: "2 个扩展名仍未检测到默认应用。",
                    extensions: [".fish", ".md"]
                )
            ]
        )
    }

    func testStatusSnapshotUsesApplicationLocatorDisplayNameFallback() {
        let formatter = SettingsCopyFormatter(
            localizer: StubSettingsLocalizer(strings: [:]),
            applicationLocator: StubSettingsApplicationLocator(
                iconPathsByBundleID: ["company.thebrowser.Browser": "/Applications/TRAE.app"],
                displayNamesByBundleID: ["company.thebrowser.Browser": "TRAE"]
            )
        )

        let snapshot = formatter.statusSnapshot(
            from: GlobalTextState(
                status: .single(bundleID: "company.thebrowser.Browser"),
                inspectedContentTypeIdentifiers: ["public.html"],
                extensionAssociations: [
                    .init(
                        normalizedExtension: "html",
                        contentTypeIdentifier: "public.html",
                        bundleID: "company.thebrowser.Browser"
                    )
                ]
            ),
            lastSwitchReport: nil,
            availableEditors: []
        )

        XCTAssertEqual(snapshot.title, "TRAE")
        XCTAssertEqual(snapshot.iconLookupPath, "/Applications/TRAE.app")
    }

    func testExtensionLineChunkerWrapsLongListsIntoTwoLines() {
        let chunker = ExtensionLineChunker(maximumLineLength: 14)

        XCTAssertEqual(
            chunker.chunk([".bash", ".cfg", ".css", ".csv", ".go"]),
            [".bash, .cfg", ".css, .csv, .go"]
        )
    }

    func testExtensionLineChunkerKeepsShortListsOnOneLine() {
        let chunker = ExtensionLineChunker()

        XCTAssertEqual(
            chunker.chunk([".conf", ".env", ".mdx", ".svelte"]),
            [".conf, .env, .mdx, .svelte"]
        )
    }

    func testLaunchAtLoginDetailUsesLocalizedCopy() {
        let formatter = SettingsCopyFormatter(localizer: StubSettingsLocalizer(
            strings: [
                "Launch the app automatically when you sign in to macOS.": "在你登录 macOS 时自动启动应用。",
            ]
        ))

        XCTAssertEqual(
            formatter.launchAtLoginDetail(status: .enabled, errorMessage: nil),
            "在你登录 macOS 时自动启动应用。"
        )
    }

    func testStatusSnapshotBuildsRecentSwitchGroupsWithNeutralCopy() {
        let formatter = SettingsCopyFormatter(localizer: StubSettingsLocalizer(strings: [:]))

        let snapshot = formatter.statusSnapshot(
            from: GlobalTextState(
                status: .mixed(bundleIDs: ["com.google.antigravity", "com.apple.TextEdit"]),
                inspectedContentTypeIdentifiers: ["type-1"],
                representativeBundleID: "com.google.antigravity"
            ),
            lastSwitchReport: GlobalTextSwitchReport(
                requestedBundleID: "com.google.antigravity",
                matchedCount: 3,
                mismatchedCount: 2,
                unsupportedCount: 2,
                writeFailedCount: 1,
                processedContentTypeIdentifiers: [
                    "type-1",
                    "type-2",
                    "type-3",
                    "type-4",
                    "type-5",
                    "type-6",
                    "type-7",
                    "type-8",
                ],
                processedExtensions: ["txt", "conf", "env", "fish", "mdx"],
                failures: [
                    .init(
                        contentTypeIdentifier: "public.config",
                        scopeLabel: ".conf",
                        role: .editor,
                        status: "unsupportedTarget",
                        effectiveBundleID: nil,
                        statusCode: nil
                    ),
                    .init(
                        contentTypeIdentifier: "public.env",
                        scopeLabel: ".env",
                        role: .editor,
                        status: "unsupportedTarget",
                        effectiveBundleID: nil,
                        statusCode: nil
                    ),
                    .init(
                        contentTypeIdentifier: "public.fish-shell",
                        scopeLabel: ".fish",
                        role: .viewer,
                        status: "mismatched",
                        effectiveBundleID: "net.kovidgoyal.kitty",
                        statusCode: nil
                    ),
                    .init(
                        contentTypeIdentifier: "public.mdx",
                        scopeLabel: ".mdx",
                        role: .viewer,
                        status: "mismatched",
                        effectiveBundleID: "com.apple.TextEdit",
                        statusCode: nil
                    ),
                    .init(
                        contentTypeIdentifier: "public.svelte",
                        scopeLabel: ".svelte",
                        role: .viewer,
                        status: "writeFailed",
                        effectiveBundleID: "com.apple.TextEdit",
                        statusCode: -10810
                    ),
                ]
            ),
            availableEditors: [
                EditorCandidate(
                    bundleID: "com.google.antigravity",
                    displayName: "Antigravity",
                    iconLookupPath: "/Applications/Antigravity.app",
                    source: .recommendedCatalog,
                    capability: .full
                )
            ]
        )

        XCTAssertEqual(
            snapshot.recentSwitch,
            SettingsStatusActivitySnapshot(
                statusTitle: "Partially Completed",
                headline: "Last switch to Antigravity processed 8 text types: 3 succeeded, 5 failed.",
                groups: [
                    SettingsStatusGroup(
                        title: "This Mac does not currently declare support (2)",
                        extensions: [".conf", ".env"]
                    ),
                    SettingsStatusGroup(
                        title: "Still using another default app (2)",
                        extensions: [".fish", ".mdx"]
                    ),
                    SettingsStatusGroup(
                        title: "macOS did not accept this change (1)",
                        extensions: [".svelte"]
                    ),
                ]
            )
        )
    }

    func testStatusSnapshotBuildsSuccessfulRecentSwitchState() {
        let formatter = SettingsCopyFormatter(localizer: StubSettingsLocalizer(strings: [:]))

        let snapshot = formatter.statusSnapshot(
            from: GlobalTextState(
                status: .single(bundleID: "com.google.antigravity"),
                inspectedContentTypeIdentifiers: ["public.plain-text"]
            ),
            lastSwitchReport: GlobalTextSwitchReport(
                requestedBundleID: "com.google.antigravity",
                matchedCount: 23,
                mismatchedCount: 0,
                unsupportedCount: 0,
                writeFailedCount: 0,
                processedContentTypeIdentifiers: ["public.plain-text", "public.json"],
                processedExtensions: ["txt", "json"],
                failures: []
            ),
            availableEditors: [
                EditorCandidate(
                    bundleID: "com.google.antigravity",
                    displayName: "Antigravity",
                    iconLookupPath: "/Applications/Antigravity.app",
                    source: .recommendedCatalog,
                    capability: .full
                )
            ]
        )

        XCTAssertEqual(
            snapshot.recentSwitch,
            SettingsStatusActivitySnapshot(
                statusTitle: "Completed",
                headline: "Last switch to Antigravity completed for 2 text types.",
                groups: []
            )
        )
    }

    func testRecommendedEntriesAndSummaryUseLocalizedCopy() {
        let formatter = SettingsCopyFormatter(localizer: StubSettingsLocalizer(
            strings: [
                "Shown in the first-level menu": "会显示在一级菜单中",
                "Shown in More": "会显示在更多中",
                "Partial support": "支持不完整",
                "Needs verification": "需要进一步验证",
                "Currently unavailable on this Mac": "当前在这台 Mac 上不可用",
                "%lld editors": "%lld 个编辑器",
            ]
        ))

        let entries = formatter.recommendedEntries(
            availableEditors: [
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
                    bundleID: "com.apple.dt.Xcode",
                    displayName: "Xcode",
                    iconLookupPath: "/Applications/Xcode.app",
                    source: .recommendedCatalog,
                    capability: .partial
                ),
                EditorCandidate(
                    bundleID: "com.example.unknown",
                    displayName: "Unknown Editor",
                    iconLookupPath: "/Applications/Unknown Editor.app",
                    source: .recommendedCatalog,
                    capability: .unverified
                )
            ],
            configuration: RecommendedMenuAppsConfiguration(
                orderedBundleIDs: [
                    "com.microsoft.VSCode",
                    "com.apple.TextEdit",
                    "com.apple.dt.Xcode",
                    "com.example.unknown",
                    "com.example.missing",
                ],
                enabledBundleIDs: ["com.microsoft.VSCode"]
            )
        )

        XCTAssertEqual(entries[0].detail, "会显示在一级菜单中")
        XCTAssertEqual(entries[1].detail, "会显示在更多中")
        XCTAssertEqual(entries[2].detail, "支持不完整")
        XCTAssertEqual(entries[2].isAvailable, true)
        XCTAssertEqual(entries[3].detail, "需要进一步验证")
        XCTAssertEqual(entries[3].isAvailable, true)
        XCTAssertEqual(entries[4].detail, "当前在这台 Mac 上不可用")
        XCTAssertEqual(formatter.recommendedEditorsSummary(enabledCount: 1), "1 个编辑器")
    }
}

private final class StubSettingsLocalizer: AppTextLocalizing {
    private let strings: [String: String]

    init(strings: [String: String]) {
        self.strings = strings
    }

    var objectWillChangePublisher: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    func string(_ key: String) -> String {
        strings[key] ?? key
    }

    func formattedString(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: Locale(identifier: "zh-Hans"), arguments: arguments)
    }
}

private struct StubSettingsApplicationLocator: ApplicationLocating {
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
