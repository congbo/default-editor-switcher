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

    func currentEditorBundleID(for contentType: UTType) -> String? {
        currentEditorBundleIDs[contentType.identifier]
    }

    func allEditorBundleIDs(for contentType: UTType) -> [String] {
        []
    }

    func setDefaultEditor(bundleID: String, for contentType: UTType) throws {}
}
