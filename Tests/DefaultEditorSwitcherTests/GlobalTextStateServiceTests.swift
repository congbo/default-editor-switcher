import XCTest
import UniformTypeIdentifiers
@testable import DefaultEditorSwitcher

final class GlobalTextStateServiceTests: XCTestCase {
    func testCurrentStateReturnsSingleWhenAllDeclaredTypesShareOneOpenerBundleID() {
        let textType = UTType(filenameExtension: "txt")!
        let markdownType = UTType(filenameExtension: "md")!
        let service = GlobalTextStateService(
            client: StubLaunchServicesClient(
                currentBundleIDsByIdentifierAndRole: [
                    key(textType, .all): "com.microsoft.VSCode",
                    key(markdownType, .viewer): "com.microsoft.VSCode",
                    key(markdownType, .editor): "com.microsoft.VSCode",
                ]
            ),
            resolutionsProvider: {
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
                    bundleID: "com.microsoft.VSCode",
                    allBundleID: "com.microsoft.VSCode"
                ),
                .init(
                    normalizedExtension: "md",
                    contentTypeIdentifier: markdownType.identifier,
                    bundleID: "com.microsoft.VSCode",
                    viewerBundleID: "com.microsoft.VSCode",
                    editorBundleID: "com.microsoft.VSCode"
                ),
            ]
        )
    }

    func testCurrentStateUsesOpenerRoleBeforeEditorRole() {
        let markdownType = UTType(filenameExtension: "md")!
        let service = GlobalTextStateService(
            client: StubLaunchServicesClient(
                currentBundleIDsByIdentifierAndRole: [
                    key(markdownType, .all): "abnerworks.Typora",
                    key(markdownType, .editor): "com.google.antigravity",
                ]
            ),
            resolutionsProvider: {
                [ContentTypeResolver.Resolution(normalizedExtension: "md", type: markdownType)]
            }
        )

        let state = service.currentState()

        XCTAssertEqual(state.status, .single(bundleID: "abnerworks.Typora"))
        XCTAssertEqual(state.currentBundleID, "abnerworks.Typora")
        XCTAssertEqual(
            state.extensionAssociations,
            [
                .init(
                    normalizedExtension: "md",
                    contentTypeIdentifier: markdownType.identifier,
                    bundleID: "abnerworks.Typora",
                    allBundleID: "abnerworks.Typora",
                    editorBundleID: "com.google.antigravity"
                )
            ]
        )
    }

    func testCurrentStateReturnsMixedWhenDeclaredTypesUseDifferentOpeners() {
        let textType = UTType(filenameExtension: "txt")!
        let markdownType = UTType(filenameExtension: "md")!
        let service = GlobalTextStateService(
            client: StubLaunchServicesClient(
                currentBundleIDsByIdentifierAndRole: [
                    key(textType, .all): "com.microsoft.VSCode",
                    key(markdownType, .all): "abnerworks.Typora",
                    key(markdownType, .editor): "com.google.antigravity",
                ]
            ),
            resolutionsProvider: {
                [
                    ContentTypeResolver.Resolution(normalizedExtension: "txt", type: textType),
                    ContentTypeResolver.Resolution(normalizedExtension: "md", type: markdownType),
                ]
            }
        )

        let state = service.currentState()

        XCTAssertEqual(
            state.status,
            .mixed(bundleIDs: ["com.microsoft.VSCode", "abnerworks.Typora"])
        )
        XCTAssertEqual(state.currentBundleID, "com.microsoft.VSCode")
        XCTAssertEqual(state.extensionAssociations.last?.bundleID, "abnerworks.Typora")
    }

    func testCurrentStateTracksDeclaredExtensionsWithoutDetectedHandler() {
        let textType = UTType(filenameExtension: "txt")!
        let markdownType = UTType(filenameExtension: "md")!
        let service = GlobalTextStateService(
            client: StubLaunchServicesClient(
                currentBundleIDsByIdentifierAndRole: [
                    key(textType, .editor): "com.microsoft.VSCode",
                ]
            ),
            resolutionsProvider: {
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
                    bundleID: "com.microsoft.VSCode",
                    editorBundleID: "com.microsoft.VSCode"
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
            client: StubLaunchServicesClient(currentBundleIDsByIdentifierAndRole: [:]),
            resolutionsProvider: {
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

    func testCurrentStateIgnoresDisabledHTMLType() {
        let cssType = UTType(filenameExtension: "css")!
        let htmlType = UTType(filenameExtension: "html")!
        let service = GlobalTextStateService(
            client: StubLaunchServicesClient(
                currentBundleIDsByIdentifierAndRole: [
                    key(cssType, .all): "com.microsoft.VSCode",
                    key(htmlType, .all): "com.apple.Safari",
                ]
            ),
            enabledExtensionsProvider: { ["css"] }
        )

        let state = service.currentState()

        XCTAssertEqual(state.inspectedContentTypeIdentifiers, [cssType.identifier])
        XCTAssertEqual(state.currentBundleID, "com.microsoft.VSCode")
        XCTAssertEqual(
            state.extensionAssociations,
            [
                .init(
                    normalizedExtension: "css",
                    contentTypeIdentifier: cssType.identifier,
                    bundleID: "com.microsoft.VSCode",
                    allBundleID: "com.microsoft.VSCode"
                )
            ]
        )
        XCTAssertNotEqual(state.inspectedContentTypeIdentifiers, [htmlType.identifier])
    }

    func testCurrentStateIncludesDeclaredCustomNonTextExtension() {
        let pngType = UTType(filenameExtension: "png")!
        let service = GlobalTextStateService(
            client: StubLaunchServicesClient(
                currentBundleIDsByIdentifierAndRole: [
                    key(pngType, .viewer): "com.apple.Preview",
                ]
            ),
            enabledExtensionsProvider: { ["png"] }
        )

        let state = service.currentState()

        XCTAssertEqual(state.inspectedContentTypeIdentifiers, [pngType.identifier])
        XCTAssertEqual(
            state.extensionAssociations,
            [
                .init(
                    normalizedExtension: "png",
                    contentTypeIdentifier: pngType.identifier,
                    bundleID: "com.apple.Preview",
                    viewerBundleID: "com.apple.Preview"
                )
            ]
        )
    }

    func testCurrentStateSkipsUnresolvedCustomExtension() {
        let txtType = UTType(filenameExtension: "txt")!
        let service = GlobalTextStateService(
            client: StubLaunchServicesClient(
                currentBundleIDsByIdentifierAndRole: [
                    key(txtType, .all): "com.microsoft.VSCode",
                ]
            ),
            resolutionsProvider: {
                [
                    ContentTypeResolver.Resolution(normalizedExtension: "txt", type: txtType),
                    ContentTypeResolver.Resolution(normalizedExtension: "unknown-custom-type", type: nil),
                ]
            }
        )

        let state = service.currentState()

        XCTAssertEqual(state.inspectedContentTypeIdentifiers, [txtType.identifier])
        XCTAssertEqual(
            state.extensionAssociations,
            [
                .init(
                    normalizedExtension: "txt",
                    contentTypeIdentifier: txtType.identifier,
                    bundleID: "com.microsoft.VSCode",
                    allBundleID: "com.microsoft.VSCode"
                )
            ]
        )
    }
}

private struct StubLaunchServicesClient: LaunchServicesClienting {
    let currentBundleIDsByIdentifierAndRole: [String: String]

    func currentHandlerBundleID(for contentType: UTType, role: PreferredHandlerRole) -> String? {
        currentBundleIDsByIdentifierAndRole[key(contentType, role)]
    }

    func allHandlerBundleIDs(for contentType: UTType, role: PreferredHandlerRole) -> [String] {
        []
    }

    func setDefaultHandler(bundleID: String, for contentType: UTType, role: PreferredHandlerRole) throws {}
}

private func key(_ contentType: UTType, _ role: PreferredHandlerRole) -> String {
    "\(contentType.identifier)#\(role.rawValue)"
}
