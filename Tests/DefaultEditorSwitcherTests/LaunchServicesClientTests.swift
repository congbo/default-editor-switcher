import XCTest
import UniformTypeIdentifiers
@testable import DefaultEditorSwitcher

final class LaunchServicesClientTests: XCTestCase {
    func testVerificationSkipsWriteWhenRequestedHandlerAlreadyMatches() {
        let contentType = UTType(filenameExtension: "txt")!
        var fetchedEligibleRoles: [PreferredHandlerRole] = []
        var writtenRoles: [PreferredHandlerRole] = []
        let mock = MockLaunchServicesClient(
            currentHandlerBundleID: { _, _ in "com.example.editor" },
            allHandlerBundleIDs: { _, role in
                fetchedEligibleRoles.append(role)
                return ["com.example.editor"]
            },
            setDefaultHandler: { _, _, role in
                writtenRoles.append(role)
            }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(requestedBundleID: "com.example.editor", for: contentType)

        XCTAssertEqual(result.status, "matched")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.editor")
        XCTAssertTrue(fetchedEligibleRoles.isEmpty)
        XCTAssertTrue(writtenRoles.isEmpty)
    }

    func testVerificationReturnsMismatchedWhenReadbackDiffersForEditorRole() {
        let contentType = UTType(filenameExtension: "md")!
        let mock = MockLaunchServicesClient(
            currentHandlerBundleID: { _, _ in "com.example.other" },
            allHandlerBundleIDs: { _, _ in ["com.example.editor", "com.example.other"] },
            setDefaultHandler: { _, _, _ in }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(
            requestedBundleID: "com.example.editor",
            for: contentType,
            roles: [.editor]
        )

        XCTAssertEqual(result.status, "mismatched")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.other")
        XCTAssertEqual(result.primaryRoleResult?.preferredHandler.role, .editor)
    }

    func testVerificationReturnsUnsupportedTargetWhenEditorRoleCannotUseRequestedApp() {
        let contentType = UTType(filenameExtension: "py")!
        var writtenRoles: [PreferredHandlerRole] = []
        let mock = MockLaunchServicesClient(
            currentHandlerBundleID: { _, _ in "com.example.other" },
            allHandlerBundleIDs: { _, role in
                role == .editor ? [] : ["com.example.editor"]
            },
            setDefaultHandler: { _, _, role in
                writtenRoles.append(role)
            }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(
            requestedBundleID: "com.example.editor",
            for: contentType,
            roles: [.editor]
        )

        XCTAssertEqual(result.status, "unsupportedTarget")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.other")
        XCTAssertEqual(result.primaryRoleResult?.preferredHandler.role, .editor)
        XCTAssertTrue(writtenRoles.isEmpty)
    }

    func testVerificationReturnsWriteFailedWhenSetOperationThrows() {
        let contentType = UTType(filenameExtension: "rs")!
        var writtenRoles: [PreferredHandlerRole] = []
        let mock = MockLaunchServicesClient(
            currentHandlerBundleID: { _, _ in "com.example.other" },
            allHandlerBundleIDs: { _, _ in ["com.example.editor"] },
            setDefaultHandler: { bundleID, type, role in
                writtenRoles.append(role)
                throw LaunchServicesClientError.failedToSetDefaultHandler(
                    status: -10810,
                    contentTypeIdentifier: type.identifier,
                    bundleID: bundleID,
                    role: role
                )
            }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(
            requestedBundleID: "com.example.editor",
            for: contentType,
            roles: [.editor]
        )

        XCTAssertEqual(result.status, "writeFailed")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.other")
        XCTAssertEqual(result.primaryRoleResult?.preferredHandler.role, .editor)
        XCTAssertEqual(result.primaryRoleResult?.statusCode, -10810)
        XCTAssertEqual(writtenRoles, [.editor])
    }

    func testVerificationDefaultsToLegacyVerificationOrderWhenRolesNotSpecified() {
        let contentType = UTType(filenameExtension: "log")!
        var writtenRoles: [PreferredHandlerRole] = []
        let mock = MockLaunchServicesClient(
            currentHandlerBundleID: { _, _ in "com.example.other" },
            allHandlerBundleIDs: { _, _ in ["com.example.editor"] },
            setDefaultHandler: { _, _, role in
                writtenRoles.append(role)
            }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        _ = verifier.verify(requestedBundleID: "com.example.editor", for: contentType)

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
