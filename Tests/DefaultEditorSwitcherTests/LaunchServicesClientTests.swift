import XCTest
import UniformTypeIdentifiers
@testable import DefaultEditorSwitcher

final class LaunchServicesClientTests: XCTestCase {
    func testVerificationReturnsMatchedWhenReadbackMatchesRequestedHandler() {
        let contentType = UTType(filenameExtension: "txt")!
        var writtenRoles: [PreferredHandlerRole] = []
        let mock = MockLaunchServicesClient(
            currentHandlerBundleID: { _, _ in "com.example.editor" },
            allHandlerBundleIDs: { _, _ in ["com.example.editor"] },
            setDefaultHandler: { _, _, role in
                writtenRoles.append(role)
            }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(requestedBundleID: "com.example.editor", for: contentType)

        XCTAssertEqual(result.status, "matched")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.editor")
        XCTAssertEqual(writtenRoles, PreferredHandlerRole.verificationOrder)
    }

    func testVerificationReturnsMismatchedWhenOneRoleReadbackDiffers() {
        let contentType = UTType(filenameExtension: "md")!
        let mock = MockLaunchServicesClient(
            currentHandlerBundleID: { _, role in
                role == .viewer ? "com.example.other" : "com.example.editor"
            },
            allHandlerBundleIDs: { _, _ in ["com.example.editor", "com.example.other"] },
            setDefaultHandler: { _, _, _ in }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(requestedBundleID: "com.example.editor", for: contentType)

        XCTAssertEqual(result.status, "mismatched")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.other")
        XCTAssertEqual(result.primaryRoleResult?.preferredHandler.role, .viewer)
    }

    func testVerificationReturnsUnsupportedTargetWhenOneRoleCannotUseRequestedApp() {
        let contentType = UTType(filenameExtension: "py")!
        var writtenRoles: [PreferredHandlerRole] = []
        let mock = MockLaunchServicesClient(
            currentHandlerBundleID: { _, _ in "com.example.editor" },
            allHandlerBundleIDs: { _, role in
                role == .editor ? [] : ["com.example.editor"]
            },
            setDefaultHandler: { _, _, role in
                writtenRoles.append(role)
            }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(requestedBundleID: "com.example.editor", for: contentType)

        XCTAssertEqual(result.status, "unsupportedTarget")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.editor")
        XCTAssertEqual(result.primaryRoleResult?.preferredHandler.role, .editor)
        XCTAssertEqual(writtenRoles, [.all, .viewer])
    }

    func testVerificationReturnsWriteFailedWhenOneRoleSetOperationThrows() {
        let contentType = UTType(filenameExtension: "rs")!
        var writtenRoles: [PreferredHandlerRole] = []
        let mock = MockLaunchServicesClient(
            currentHandlerBundleID: { _, role in
                role == .viewer ? "com.example.other" : "com.example.editor"
            },
            allHandlerBundleIDs: { _, _ in ["com.example.editor"] },
            setDefaultHandler: { bundleID, type, role in
                writtenRoles.append(role)
                guard role == .viewer else {
                    return
                }

                throw LaunchServicesClientError.failedToSetDefaultHandler(
                    status: -10810,
                    contentTypeIdentifier: type.identifier,
                    bundleID: bundleID,
                    role: role
                )
            }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(requestedBundleID: "com.example.editor", for: contentType)

        XCTAssertEqual(result.status, "writeFailed")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.other")
        XCTAssertEqual(result.primaryRoleResult?.preferredHandler.role, .viewer)
        XCTAssertEqual(result.primaryRoleResult?.statusCode, -10810)
        XCTAssertEqual(writtenRoles, PreferredHandlerRole.verificationOrder)
    }
}

private struct MockLaunchServicesClient: LaunchServicesClienting {
    let currentHandlerBundleIDProvider: (UTType, PreferredHandlerRole) -> String?
    let allHandlerBundleIDsProvider: (UTType, PreferredHandlerRole) -> [String]
    let setDefaultHandlerProvider: (String, UTType, PreferredHandlerRole) throws -> Void

    init(
        currentHandlerBundleID: @escaping (UTType, PreferredHandlerRole) -> String?,
        allHandlerBundleIDs: @escaping (UTType, PreferredHandlerRole) -> [String],
        setDefaultHandler: @escaping (String, UTType, PreferredHandlerRole) throws -> Void
    ) {
        self.currentHandlerBundleIDProvider = currentHandlerBundleID
        self.allHandlerBundleIDsProvider = allHandlerBundleIDs
        self.setDefaultHandlerProvider = setDefaultHandler
    }

    func currentHandlerBundleID(for contentType: UTType, role: PreferredHandlerRole) -> String? {
        currentHandlerBundleIDProvider(contentType, role)
    }

    func allHandlerBundleIDs(for contentType: UTType, role: PreferredHandlerRole) -> [String] {
        allHandlerBundleIDsProvider(contentType, role)
    }

    func setDefaultHandler(bundleID: String, for contentType: UTType, role: PreferredHandlerRole) throws {
        try setDefaultHandlerProvider(bundleID, contentType, role)
    }
}
