import XCTest
import UniformTypeIdentifiers
@testable import DefaultEditorSwitcher

final class WorkspaceDiscoveryTests: XCTestCase {
    func testBundleMetadataReaderParsesDocumentDeclarations() {
        let reader = BundleDocumentTypeReader()
        let metadata = reader.metadata(
            from: [
                "CFBundleDocumentTypes": [
                    [
                        "LSItemContentTypes": ["public.source-code", "public.python-script"],
                        "CFBundleTypeRole": "Editor",
                        "LSHandlerRank": "Owner",
                    ],
                    [
                        "LSItemContentTypes": ["public.plain-text"],
                        "CFBundleTypeRole": "Editor",
                        "LSHandlerRank": "Alternate",
                    ],
                ]
            ],
            bundleIdentifier: "com.example.editor",
            displayName: "Example Editor"
        )

        XCTAssertEqual(metadata.bundleID, "com.example.editor")
        XCTAssertEqual(metadata.displayName, "Example Editor")
        XCTAssertEqual(metadata.documentTypes.count, 2)
        XCTAssertEqual(metadata.documentTypes[0].contentTypeIdentifiers, ["public.source-code", "public.python-script"])
        XCTAssertEqual(metadata.documentTypes[0].role, "Editor")
        XCTAssertEqual(metadata.documentTypes[0].handlerRank, "Owner")
        XCTAssertEqual(metadata.documentTypes[1].contentTypeIdentifiers, ["public.plain-text"])
        XCTAssertEqual(metadata.documentTypes[1].role, "Editor")
        XCTAssertEqual(metadata.documentTypes[1].handlerRank, "Alternate")
    }

    func testWorkspaceDiscoveryKeepsRecommendedEditorsFirstAndClassifiesCapabilities() {
        let reader = BundleDocumentTypeReader()
        let requestedType = UTType(filenameExtension: "py")!
        let recommendedURL = URL(fileURLWithPath: "/Applications/Visual Studio Code.app")
        let partialURL = URL(fileURLWithPath: "/Applications/Example Partial.app")
        let unverifiedURL = URL(fileURLWithPath: "/Applications/Example Unknown.app")

        let recommendedMetadata = reader.metadata(
            from: [
                "CFBundleDocumentTypes": [
                    [
                        "LSItemContentTypes": [requestedType.identifier],
                        "CFBundleTypeRole": "Editor",
                        "LSHandlerRank": "Owner",
                    ]
                ]
            ],
            bundleIdentifier: "com.microsoft.VSCode",
            displayName: "Visual Studio Code"
        )

        let partialMetadata = reader.metadata(
            from: [
                "CFBundleDocumentTypes": [
                    [
                        "LSItemContentTypes": ["public.plain-text"],
                        "CFBundleTypeRole": "Editor",
                        "LSHandlerRank": "Alternate",
                    ]
                ]
            ],
            bundleIdentifier: "com.example.partial",
            displayName: "Partial Editor"
        )

        let unverifiedMetadata = reader.metadata(
            from: [:],
            bundleIdentifier: "com.example.unknown",
            displayName: "Unknown Editor"
        )

        let discovery = WorkspaceAppDiscovery(
            workspace: FakeWorkspaceApplicationURLProvider(urls: [partialURL, unverifiedURL, recommendedURL]),
            bundleInspector: FakeBundleInspector(
                bundleIdentifiers: [
                    recommendedURL: recommendedMetadata.bundleID,
                    partialURL: partialMetadata.bundleID,
                    unverifiedURL: unverifiedMetadata.bundleID,
                ],
                displayNames: [
                    recommendedURL: recommendedMetadata.displayName,
                    partialURL: partialMetadata.displayName,
                    unverifiedURL: unverifiedMetadata.displayName,
                ],
                metadata: [
                    recommendedURL: recommendedMetadata,
                    partialURL: partialMetadata,
                    unverifiedURL: unverifiedMetadata,
                ]
            )
        )

        let ranked = discovery.discoverEditors(for: requestedType, bucket: .python)

        XCTAssertEqual(ranked.map(\.bundleID), ["com.microsoft.VSCode", "com.example.partial", "com.example.unknown"])
        XCTAssertEqual(ranked.map(\.capability), [.full, .partial, .unverified])
        XCTAssertEqual(ranked[0].source, .recommendedCatalog)
        XCTAssertEqual(ranked[1].source, .systemEligible)
        XCTAssertEqual(ranked[2].source, .systemEligible)
        XCTAssertEqual(ranked[0].iconLookupPath, recommendedURL.path)
    }

    private struct FakeWorkspaceApplicationURLProvider: WorkspaceApplicationURLProviding {
        let urls: [URL]

        func urlsForApplications(toOpen contentType: UTType) -> [URL] {
            urls
        }
    }

    private struct FakeBundleInspector: ApplicationBundleInspecting {
        let bundleIdentifiers: [URL: String]
        let displayNames: [URL: String]
        let metadata: [URL: BundleDocumentTypeMetadata]

        func bundleIdentifier(for bundleURL: URL) -> String? {
            bundleIdentifiers[bundleURL]
        }

        func displayName(for bundleURL: URL) -> String? {
            displayNames[bundleURL]
        }

        func iconLookupPath(for bundleURL: URL) -> String {
            bundleURL.path
        }

        func metadata(for bundleURL: URL) -> BundleDocumentTypeMetadata {
            metadata[bundleURL] ?? BundleDocumentTypeMetadata(
                bundleID: bundleURL.deletingPathExtension().lastPathComponent,
                displayName: bundleURL.deletingPathExtension().lastPathComponent,
                documentTypes: []
            )
        }
    }
}
