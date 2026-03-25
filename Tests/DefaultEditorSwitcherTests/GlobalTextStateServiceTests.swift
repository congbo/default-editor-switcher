import XCTest
import UniformTypeIdentifiers
@testable import DefaultEditorSwitcher

final class GlobalTextStateServiceTests: XCTestCase {
    func testCurrentStateReturnsSingleWhenAllDeclaredTypesShareOneBundleID() {
        let textType = UTType(filenameExtension: "txt")!
        let markdownType = UTType(filenameExtension: "md")!
        let service = GlobalTextStateService(
            client: StubLaunchServicesClient(
                currentEditorBundleIDs: [
                    textType.identifier: "com.microsoft.VSCode",
                    markdownType.identifier: "com.microsoft.VSCode",
                ]
            ),
            resolutionsProvider: { _ in
                [
                    ContentTypeResolver.Resolution(normalizedExtension: "txt", type: textType),
                    ContentTypeResolver.Resolution(normalizedExtension: "md", type: markdownType),
                ]
            }
        )

        let state = service.currentState()

        XCTAssertEqual(state.status, .single(bundleID: "com.microsoft.VSCode"))
        XCTAssertEqual(state.inspectedContentTypeIdentifiers, [textType.identifier, markdownType.identifier])
        XCTAssertEqual(state.currentBundleID, "com.microsoft.VSCode")
        XCTAssertEqual(
            state.extensionAssociations,
            [
                .init(
                    normalizedExtension: "txt",
                    contentTypeIdentifier: textType.identifier,
                    bundleID: "com.microsoft.VSCode"
                ),
                .init(
                    normalizedExtension: "md",
                    contentTypeIdentifier: markdownType.identifier,
                    bundleID: "com.microsoft.VSCode"
                ),
            ]
        )
    }

    func testCurrentStateReturnsMixedWhenDeclaredTypesUseDifferentBundleIDs() {
        let textType = UTType(filenameExtension: "txt")!
        let markdownType = UTType(filenameExtension: "md")!
        let service = GlobalTextStateService(
            client: StubLaunchServicesClient(
                currentEditorBundleIDs: [
                    textType.identifier: "com.microsoft.VSCode",
                    markdownType.identifier: "com.apple.TextEdit",
                ]
            ),
            resolutionsProvider: { _ in
                [
                    ContentTypeResolver.Resolution(normalizedExtension: "txt", type: textType),
                    ContentTypeResolver.Resolution(normalizedExtension: "md", type: markdownType),
                ]
            }
        )

        let state = service.currentState()

        XCTAssertEqual(
            state.status,
            .mixed(bundleIDs: ["com.microsoft.VSCode", "com.apple.TextEdit"])
        )
        XCTAssertEqual(state.currentBundleID, "com.microsoft.VSCode")
        XCTAssertEqual(
            state.extensionAssociations,
            [
                .init(
                    normalizedExtension: "txt",
                    contentTypeIdentifier: textType.identifier,
                    bundleID: "com.microsoft.VSCode"
                ),
                .init(
                    normalizedExtension: "md",
                    contentTypeIdentifier: markdownType.identifier,
                    bundleID: "com.apple.TextEdit"
                ),
            ]
        )
    }

    func testCurrentStateTracksDeclaredExtensionsWithoutDetectedHandler() {
        let textType = UTType(filenameExtension: "txt")!
        let markdownType = UTType(filenameExtension: "md")!
        let service = GlobalTextStateService(
            client: StubLaunchServicesClient(
                currentEditorBundleIDs: [
                    textType.identifier: "com.microsoft.VSCode",
                ]
            ),
            resolutionsProvider: { _ in
                [
                    ContentTypeResolver.Resolution(normalizedExtension: "txt", type: textType),
                    ContentTypeResolver.Resolution(normalizedExtension: "md", type: markdownType),
                ]
            }
        )

        let state = service.currentState()

        XCTAssertEqual(state.status, .single(bundleID: "com.microsoft.VSCode"))
        XCTAssertEqual(
            state.extensionAssociations,
            [
                .init(
                    normalizedExtension: "txt",
                    contentTypeIdentifier: textType.identifier,
                    bundleID: "com.microsoft.VSCode"
                ),
                .init(
                    normalizedExtension: "md",
                    contentTypeIdentifier: markdownType.identifier,
                    bundleID: nil
                ),
            ]
        )
    }

    func testCurrentStateReturnsUnavailableWhenNoDeclaredTypeHasCurrentHandler() {
        let textType = UTType(filenameExtension: "txt")!
        let service = GlobalTextStateService(
            client: StubLaunchServicesClient(currentEditorBundleIDs: [:]),
            resolutionsProvider: { _ in
                [
                    ContentTypeResolver.Resolution(normalizedExtension: "txt", type: textType),
                    ContentTypeResolver.Resolution(normalizedExtension: "mystery", type: nil),
                ]
            }
        )

        let state = service.currentState()

        XCTAssertEqual(state.status, .unavailable)
        XCTAssertEqual(state.inspectedContentTypeIdentifiers, [textType.identifier])
        XCTAssertNil(state.currentBundleID)
    }
}

private struct StubLaunchServicesClient: LaunchServicesClienting {
    let currentEditorBundleIDs: [String: String]

    func currentHandlerBundleID(for contentType: UTType, role: PreferredHandlerRole) -> String? {
        guard role == .editor else {
            return nil
        }

        return currentEditorBundleIDs[contentType.identifier]
    }

    func allHandlerBundleIDs(for contentType: UTType, role: PreferredHandlerRole) -> [String] {
        []
    }

    func setDefaultHandler(bundleID: String, for contentType: UTType, role: PreferredHandlerRole) throws {}
}
