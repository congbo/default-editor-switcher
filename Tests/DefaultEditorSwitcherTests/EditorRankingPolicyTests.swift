import XCTest
@testable import DefaultEditorSwitcher

final class EditorRankingPolicyTests: XCTestCase {
    private let policy = EditorRankingPolicy()

    func testRecommendedEditorsSortAheadOfSystemEligibleEditors() {
        let candidates = [
            candidate(bundleID: "com.example.custom-editor", source: .systemEligible, weightName: "Custom"),
            candidate(bundleID: "com.microsoft.VSCode", source: .recommendedCatalog, weightName: "VS Code"),
        ]

        let ranked = policy.rank(candidates)

        XCTAssertEqual(ranked.map(\.bundleID), ["com.microsoft.VSCode", "com.example.custom-editor"])
    }

    func testPythonBucketBonusCanChangeOrderWithinRecommendedTier() {
        let candidates = [
            candidate(bundleID: "com.microsoft.VSCode", source: .recommendedCatalog, weightName: "VS Code"),
            candidate(bundleID: "com.jetbrains.pycharm", source: .recommendedCatalog, weightName: "PyCharm"),
        ]

        let ranked = policy.rank(candidates, for: .python)

        XCTAssertEqual(ranked.map(\.bundleID), ["com.jetbrains.pycharm", "com.microsoft.VSCode"])
    }

    func testWebBucketBonusCanChangeOrderWithinRecommendedTier() {
        let candidates = [
            candidate(bundleID: "com.microsoft.VSCode", source: .recommendedCatalog, weightName: "VS Code"),
            candidate(bundleID: "com.jetbrains.webstorm", source: .recommendedCatalog, weightName: "WebStorm"),
        ]

        let ranked = policy.rank(candidates, for: .web)

        XCTAssertEqual(ranked.map(\.bundleID), ["com.jetbrains.webstorm", "com.microsoft.VSCode"])
    }

    func testVibeCodingIDEsSortAheadOfVSCodeInRecommendedTier() {
        let candidates = [
            candidate(bundleID: "com.google.antigravity", source: .recommendedCatalog, weightName: "Antigravity"),
            candidate(bundleID: "com.todesktop.230313mzl4w4u92", source: .recommendedCatalog, weightName: "Cursor"),
            candidate(bundleID: "dev.kiro.desktop", source: .recommendedCatalog, weightName: "Kiro"),
            candidate(bundleID: "com.exafunction.windsurf", source: .recommendedCatalog, weightName: "Windsurf"),
            candidate(bundleID: "com.trae.app", source: .recommendedCatalog, weightName: "Trae"),
            candidate(bundleID: "com.tencent.codebuddy", source: .recommendedCatalog, weightName: "CodeBuddy"),
            candidate(bundleID: "dev.zed.Zed", source: .recommendedCatalog, weightName: "Zed"),
            candidate(bundleID: "com.microsoft.VSCode", source: .recommendedCatalog, weightName: "VS Code"),
        ]

        let ranked = policy.rank(candidates)

        XCTAssertEqual(
            ranked.map(\.bundleID),
            [
                "com.google.antigravity",
                "com.todesktop.230313mzl4w4u92",
                "dev.kiro.desktop",
                "com.exafunction.windsurf",
                "com.trae.app",
                "com.tencent.codebuddy",
                "dev.zed.Zed",
                "com.microsoft.VSCode",
            ]
        )
    }

    func testChatGPTAtlasIsNotInCuratedIDECatalog() {
        XCTAssertNil(KnownEditors.knownEditor(for: "com.openai.atlas"))
    }

    func testSystemEligibleEditorsSortBySupportedTextExtensionCountInGlobalMenu() {
        let candidates = [
            candidate(
                bundleID: "com.example.narrow-editor",
                source: .systemEligible,
                weightName: "Narrow",
                supportedTextExtensionCount: 3
            ),
            candidate(
                bundleID: "com.example.broad-editor",
                source: .systemEligible,
                weightName: "Broad",
                supportedTextExtensionCount: 9
            ),
            candidate(
                bundleID: "com.example.medium-editor",
                source: .systemEligible,
                weightName: "Medium",
                supportedTextExtensionCount: 5
            ),
        ]

        let ranked = policy.rank(candidates)

        XCTAssertEqual(
            ranked.map(\.bundleID),
            [
                "com.example.broad-editor",
                "com.example.medium-editor",
                "com.example.narrow-editor",
            ]
        )
    }

    private func candidate(
        bundleID: String,
        source: EditorCandidateSource,
        weightName: String,
        supportedTextExtensionCount: Int = 0
    ) -> EditorCandidate {
        EditorCandidate(
            bundleID: bundleID,
            displayName: weightName,
            iconLookupPath: "/Applications/\(weightName).app",
            source: source,
            capability: .full,
            supportedTextExtensionCount: supportedTextExtensionCount
        )
    }
}
