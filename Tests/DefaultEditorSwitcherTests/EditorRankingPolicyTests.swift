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

    private func candidate(
        bundleID: String,
        source: EditorCandidateSource,
        weightName: String
    ) -> EditorCandidate {
        EditorCandidate(
            bundleID: bundleID,
            displayName: weightName,
            iconLookupPath: "/Applications/\(weightName).app",
            source: source,
            capability: .full
        )
    }
}
