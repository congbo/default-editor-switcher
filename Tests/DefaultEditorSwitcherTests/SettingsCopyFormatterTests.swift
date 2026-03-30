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
    }

    func testStatusSnapshotUsesMixedStateSummary() {
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
        XCTAssertEqual(snapshot.iconLookupPath, "/Applications/Visual Studio Code.app")
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
            availableEditors: []
        )

        XCTAssertEqual(snapshot.title, "TRAE")
        XCTAssertEqual(snapshot.iconLookupPath, "/Applications/TRAE.app")
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

    func testRecommendedEntriesAndSummaryUseLocalizedCopy() {
        let formatter = SettingsCopyFormatter(localizer: StubSettingsLocalizer(
            strings: [
                "Shown in the first-level menu": "会显示在一级菜单中",
                "Shown in More": "会显示在更多中",
                "Partial support": "支持不完整",
                "Needs verification": "需要进一步验证",
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
                    source: .systemEligible,
                    capability: .unverified
                ),
                EditorCandidate(
                    bundleID: "com.openai.atlas",
                    displayName: "ChatGPT Atlas",
                    iconLookupPath: "/Applications/ChatGPT Atlas.app",
                    source: .systemEligible,
                    capability: .full
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
        XCTAssertEqual(entries.map(\.bundleID), [
            "com.microsoft.VSCode",
            "com.apple.TextEdit",
            "com.apple.dt.Xcode",
            "com.example.unknown",
            "com.openai.atlas",
        ])
        XCTAssertEqual(entries[4].detail, "会显示在更多中")
        XCTAssertFalse(entries[4].isEnabled)
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
