import XCTest
import UniformTypeIdentifiers
@testable import DefaultEditorSwitcher

final class LaunchServicesClientTests: XCTestCase {
    func testVerificationReturnsMatchedWhenReadbackMatchesRequestedHandler() {
        let contentType = UTType(filenameExtension: "txt")!
        let mock = MockLaunchServicesClient(
            currentEditorBundleID: { _ in "com.example.editor" },
            allEditorBundleIDs: { _ in ["com.example.editor"] },
            setDefaultEditor: { _, _ in }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(requestedBundleID: "com.example.editor", for: contentType)

        XCTAssertEqual(result.status, "matched")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.editor")
    }

    func testVerificationReturnsMismatchedWhenEffectiveHandlerDiffers() {
        let contentType = UTType(filenameExtension: "md")!
        let mock = MockLaunchServicesClient(
            currentEditorBundleID: { _ in "com.example.other" },
            allEditorBundleIDs: { _ in ["com.example.editor", "com.example.other"] },
            setDefaultEditor: { _, _ in }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(requestedBundleID: "com.example.editor", for: contentType)

        XCTAssertEqual(result.status, "mismatched")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.other")
    }

    func testVerificationReturnsUnsupportedTargetWhenNoEligibleHandlersExist() {
        let contentType = UTType(filenameExtension: "py")!
        var writeAttempted = false
        let mock = MockLaunchServicesClient(
            currentEditorBundleID: { _ in "com.example.editor" },
            allEditorBundleIDs: { _ in [] },
            setDefaultEditor: { _, _ in writeAttempted = true }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(requestedBundleID: "com.example.editor", for: contentType)

        XCTAssertEqual(result.status, "unsupportedTarget")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.editor")
        XCTAssertFalse(writeAttempted)
    }

    func testVerificationReturnsWriteFailedWhenSetOperationThrows() {
        let contentType = UTType(filenameExtension: "rs")!
        let mock = MockLaunchServicesClient(
            currentEditorBundleID: { _ in "com.example.other" },
            allEditorBundleIDs: { _ in ["com.example.editor"] },
            setDefaultEditor: { bundleID, type in
                throw LaunchServicesClientError.failedToSetDefaultEditor(
                    status: -10810,
                    contentTypeIdentifier: type.identifier,
                    bundleID: bundleID
                )
            }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(requestedBundleID: "com.example.editor", for: contentType)

        XCTAssertEqual(result.status, "writeFailed")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.other")
    }
}

private struct MockLaunchServicesClient: LaunchServicesClienting {
    let currentEditorBundleIDProvider: (UTType) -> String?
    let allEditorBundleIDsProvider: (UTType) -> [String]
    let setDefaultEditorProvider: (String, UTType) throws -> Void

    init(
        currentEditorBundleID: @escaping (UTType) -> String?,
        allEditorBundleIDs: @escaping (UTType) -> [String],
        setDefaultEditor: @escaping (String, UTType) throws -> Void
    ) {
        self.currentEditorBundleIDProvider = currentEditorBundleID
        self.allEditorBundleIDsProvider = allEditorBundleIDs
        self.setDefaultEditorProvider = setDefaultEditor
    }

    func currentEditorBundleID(for contentType: UTType) -> String? {
        currentEditorBundleIDProvider(contentType)
    }

    func allEditorBundleIDs(for contentType: UTType) -> [String] {
        allEditorBundleIDsProvider(contentType)
    }

    func setDefaultEditor(bundleID: String, for contentType: UTType) throws {
        try setDefaultEditorProvider(bundleID, contentType)
    }
}
