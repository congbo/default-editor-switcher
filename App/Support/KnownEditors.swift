import Foundation

struct KnownEditor: Hashable {
    let bundleID: String
    let displayName: String
    let globalWeight: Int
    let bucketWeights: [LanguageBucket: Int]

    func weight(for bucket: LanguageBucket?) -> Int {
        globalWeight + (bucket.flatMap { bucketWeights[$0] } ?? 0)
    }
}

enum KnownEditors {
    static let catalog: [KnownEditor] = [
        KnownEditor(
            bundleID: "com.google.antigravity",
            displayName: "Antigravity",
            globalWeight: 118,
            bucketWeights: [
                .python: 8,
                .web: 10,
                .go: 6,
                .java: 6,
                .rust: 6,
                .markdown: 8,
            ]
        ),
        KnownEditor(
            bundleID: "com.todesktop.230313mzl4w4u92",
            displayName: "Cursor",
            globalWeight: 112,
            bucketWeights: [
                .python: 8,
                .web: 10,
                .go: 6,
                .java: 6,
                .rust: 6,
                .markdown: 8,
            ]
        ),
        KnownEditor(
            bundleID: "dev.kiro.desktop",
            displayName: "Kiro",
            globalWeight: 111,
            bucketWeights: [
                .python: 8,
                .web: 10,
                .go: 6,
                .java: 6,
                .rust: 6,
                .markdown: 8,
            ]
        ),
        KnownEditor(
            bundleID: "com.exafunction.windsurf",
            displayName: "Windsurf",
            globalWeight: 110,
            bucketWeights: [
                .python: 8,
                .web: 10,
                .go: 6,
                .java: 6,
                .rust: 6,
                .markdown: 8,
            ]
        ),
        KnownEditor(
            bundleID: "com.trae.app",
            displayName: "Trae",
            globalWeight: 108,
            bucketWeights: [
                .python: 8,
                .web: 10,
                .go: 6,
                .java: 6,
                .rust: 6,
                .markdown: 8,
            ]
        ),
        KnownEditor(
            bundleID: "com.tencent.codebuddy",
            displayName: "CodeBuddy",
            globalWeight: 104,
            bucketWeights: [
                .python: 8,
                .web: 10,
                .go: 6,
                .java: 6,
                .rust: 6,
                .markdown: 8,
            ]
        ),
        KnownEditor(
            bundleID: "dev.zed.Zed",
            displayName: "Zed",
            globalWeight: 106,
            bucketWeights: [
                .python: 6,
                .web: 8,
                .go: 6,
                .rust: 10,
                .markdown: 6,
            ]
        ),
        KnownEditor(
            bundleID: "com.qoder.ide",
            displayName: "Qoder",
            globalWeight: 103,
            bucketWeights: [
                .python: 8,
                .web: 10,
                .go: 6,
                .java: 6,
                .rust: 6,
                .markdown: 8,
            ]
        ),
        KnownEditor(
            bundleID: "com.microsoft.VSCode",
            displayName: "Visual Studio Code",
            globalWeight: 100,
            bucketWeights: [
                .python: 8,
                .web: 10,
                .go: 6,
                .java: 6,
                .rust: 6,
                .markdown: 8,
            ]
        ),
        KnownEditor(
            bundleID: "com.apple.dt.Xcode",
            displayName: "Xcode",
            globalWeight: 98,
            bucketWeights: [
                .web: 4,
                .go: 4,
                .markdown: 2,
            ]
        ),
        KnownEditor(
            bundleID: "com.sublimetext.4",
            displayName: "Sublime Text",
            globalWeight: 85,
            bucketWeights: [
                .web: 6,
                .markdown: 12,
            ]
        ),
        KnownEditor(
            bundleID: "com.apple.TextEdit",
            displayName: "TextEdit",
            globalWeight: 70,
            bucketWeights: [
                .markdown: 4,
            ]
        ),
        KnownEditor(
            bundleID: "abnerworks.Typora",
            displayName: "Typora",
            globalWeight: 84,
            bucketWeights: [
                .markdown: 18,
            ]
        ),
        KnownEditor(
            bundleID: "com.macromates.TextMate",
            displayName: "TextMate",
            globalWeight: 80,
            bucketWeights: [
                .web: 4,
                .markdown: 15,
            ]
        ),
        KnownEditor(
            bundleID: "com.coteditor.CotEditor",
            displayName: "CotEditor",
            globalWeight: 75,
            bucketWeights: [
                .markdown: 10,
            ]
        ),
        KnownEditor(
            bundleID: "com.barebones.bbedit",
            displayName: "BBEdit",
            globalWeight: 72,
            bucketWeights: [
                .markdown: 11,
            ]
        ),
        KnownEditor(
            bundleID: "com.jetbrains.intellij",
            displayName: "IntelliJ IDEA",
            globalWeight: 78,
            bucketWeights: [
                .java: 20,
            ]
        ),
        KnownEditor(
            bundleID: "com.jetbrains.pycharm",
            displayName: "PyCharm",
            globalWeight: 96,
            bucketWeights: [
                .python: 22,
            ]
        ),
        KnownEditor(
            bundleID: "com.jetbrains.webstorm",
            displayName: "WebStorm",
            globalWeight: 95,
            bucketWeights: [
                .web: 22,
            ]
        ),
        KnownEditor(
            bundleID: "com.jetbrains.goland",
            displayName: "GoLand",
            globalWeight: 94,
            bucketWeights: [
                .go: 22,
            ]
        ),
        KnownEditor(
            bundleID: "com.jetbrains.rustrover",
            displayName: "RustRover",
            globalWeight: 93,
            bucketWeights: [
                .rust: 22,
            ]
        ),
    ]

    static let catalogByBundleID: [String: KnownEditor] = Dictionary(
        uniqueKeysWithValues: catalog.map { ($0.bundleID, $0) }
    )

    static let defaultRecommendedBundleIDs = catalog.map(\.bundleID)
    static let defaultEnabledRecommendedBundleIDs = [
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

    static let defaultRecommendedEditors = catalog

    static func knownEditor(for bundleID: String) -> KnownEditor? {
        catalogByBundleID[bundleID]
    }

    static func isRecommended(bundleID: String) -> Bool {
        knownEditor(for: bundleID) != nil
    }

    static func menuSortOrder(for bundleID: String) -> Int? {
        catalog.firstIndex { $0.bundleID == bundleID }
    }

    static func weight(for bundleID: String, bucket: LanguageBucket? = nil) -> Int {
        knownEditor(for: bundleID)?.weight(for: bucket) ?? 0
    }
}
