import XCTest
import UniformTypeIdentifiers
@testable import DefaultEditorSwitcher

final class GlobalTextSwitchCoordinatorTests: XCTestCase {
    func testApplySkipsFullyMatchedTypesAndWritesAllEligibleRoles() {
        let textType = UTType(filenameExtension: "txt")!
        let markdownType = UTType(filenameExtension: "md")!
        let pythonType = UTType(filenameExtension: "py")!
        let reader = StubAssociationReader(
            currentHandlersByIdentifierAndRole: [
                key(textType, .all): "com.microsoft.VSCode",
                key(textType, .viewer): "com.microsoft.VSCode",
                key(textType, .editor): "com.microsoft.VSCode",
                key(markdownType, .all): "com.apple.TextEdit",
                key(markdownType, .viewer): "com.apple.TextEdit",
                key(markdownType, .editor): "com.apple.TextEdit",
                key(pythonType, .all): "com.apple.TextEdit",
                key(pythonType, .viewer): "com.apple.TextEdit",
                key(pythonType, .editor): "com.apple.TextEdit",
            ],
            eligibleHandlersByIdentifierAndRole: [
                key(markdownType, .all): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(markdownType, .viewer): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(markdownType, .editor): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(pythonType, .all): ["com.apple.TextEdit"],
                key(pythonType, .viewer): ["com.apple.TextEdit"],
                key(pythonType, .editor): ["com.apple.TextEdit"],
            ]
        )
        let writer = StubPreferenceWriter()
        let coordinator = GlobalTextSwitchCoordinator(
            associationReader: reader,
            preferenceWriter: writer,
            resolutionsProvider: {
                [
                    ContentTypeResolver.Resolution(normalizedExtension: "txt", type: textType),
                    ContentTypeResolver.Resolution(normalizedExtension: "md", type: markdownType),
                    ContentTypeResolver.Resolution(normalizedExtension: "py", type: pythonType),
                ]
            }
        )

        let report = coordinator.apply(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(
            writer.writtenAssignments,
            [
                .init(contentTypeIdentifier: markdownType.identifier, roles: PreferredHandlerRole.verificationOrder)
            ]
        )
        XCTAssertEqual(report.matchedCount, 1)
        XCTAssertEqual(report.pendingVerificationCount, 1)
        XCTAssertEqual(report.unsupportedCount, 1)
        XCTAssertEqual(report.processedExtensions, ["txt", "md", "py"])
        XCTAssertEqual(
            report.failures.map(\.status),
            [
                AssociationVerificationStatus.pendingVerification.rawValue,
                AssociationVerificationStatus.unsupportedTarget.rawValue,
            ]
        )
        XCTAssertEqual(report.failures.first?.role, .all)
        XCTAssertEqual(report.sampleFailures.map(\.scopeLabel), [".py"])
    }

    func testApplyWritesOnlyUnmatchedRolesWhenSomeRolesAlreadyMatch() {
        let markdownType = UTType(filenameExtension: "md")!
        let reader = StubAssociationReader(
            currentHandlersByIdentifierAndRole: [
                key(markdownType, .all): "abnerworks.Typora",
                key(markdownType, .viewer): "abnerworks.Typora",
                key(markdownType, .editor): "com.google.antigravity",
            ],
            eligibleHandlersByIdentifierAndRole: [
                key(markdownType, .all): ["com.google.antigravity", "abnerworks.Typora"],
                key(markdownType, .viewer): ["com.google.antigravity", "abnerworks.Typora"],
            ]
        )
        let writer = StubPreferenceWriter()
        let coordinator = GlobalTextSwitchCoordinator(
            associationReader: reader,
            preferenceWriter: writer,
            resolutionsProvider: {
                [ContentTypeResolver.Resolution(normalizedExtension: "md", type: markdownType)]
            }
        )

        let report = coordinator.apply(bundleID: "com.google.antigravity")

        XCTAssertEqual(
            writer.writtenAssignments,
            [
                .init(contentTypeIdentifier: markdownType.identifier, roles: [.all, .viewer])
            ]
        )
        XCTAssertEqual(report.pendingVerificationCount, 1)
        XCTAssertEqual(report.failures.first?.role, .all)
        XCTAssertEqual(report.failures.first?.status, AssociationVerificationStatus.pendingVerification.rawValue)
    }

    func testApplyTreatsUnsupportedViewerAsSecondaryWhenAllRoleCanSwitch() {
        let configType = UTType(filenameExtension: "cfg")!
        let reader = StubAssociationReader(
            currentHandlersByIdentifierAndRole: [
                key(configType, .all): "com.apple.TextEdit",
                key(configType, .viewer): "com.apple.TextEdit",
                key(configType, .editor): "com.apple.TextEdit",
            ],
            eligibleHandlersByIdentifierAndRole: [
                key(configType, .all): ["dev.zed.Zed", "com.apple.TextEdit"],
                key(configType, .editor): ["dev.zed.Zed", "com.apple.TextEdit"],
            ]
        )
        let writer = StubPreferenceWriter()
        let coordinator = GlobalTextSwitchCoordinator(
            associationReader: reader,
            preferenceWriter: writer,
            resolutionsProvider: {
                [ContentTypeResolver.Resolution(normalizedExtension: "cfg", type: configType)]
            }
        )

        let report = coordinator.apply(bundleID: "dev.zed.Zed")

        XCTAssertEqual(
            writer.writtenAssignments,
            [
                .init(contentTypeIdentifier: configType.identifier, roles: [.all, .editor])
            ]
        )
        XCTAssertEqual(report.pendingVerificationCount, 1)
        XCTAssertEqual(report.unsupportedCount, 0)
        XCTAssertEqual(report.failures.first?.role, .all)
        XCTAssertEqual(report.failures.first?.status, AssociationVerificationStatus.pendingVerification.rawValue)
    }

    func testApplyReportsPartialFailureWhenOnlyEditorRoleSupportsRequestedApp() {
        let markdownType = UTType(filenameExtension: "md")!
        let reader = StubAssociationReader(
            currentHandlersByIdentifierAndRole: [
                key(markdownType, .all): "abnerworks.Typora",
                key(markdownType, .viewer): "abnerworks.Typora",
                key(markdownType, .editor): "com.apple.TextEdit",
            ],
            eligibleHandlersByIdentifierAndRole: [
                key(markdownType, .editor): ["com.google.antigravity", "com.apple.TextEdit"],
            ]
        )
        let writer = StubPreferenceWriter()
        let coordinator = GlobalTextSwitchCoordinator(
            associationReader: reader,
            preferenceWriter: writer,
            resolutionsProvider: {
                [ContentTypeResolver.Resolution(normalizedExtension: "md", type: markdownType)]
            }
        )

        let report = coordinator.apply(bundleID: "com.google.antigravity")

        XCTAssertEqual(
            writer.writtenAssignments,
            [
                .init(contentTypeIdentifier: markdownType.identifier, roles: [.editor])
            ]
        )
        XCTAssertEqual(report.unsupportedCount, 1)
        XCTAssertEqual(report.pendingVerificationCount, 0)
        XCTAssertEqual(report.failures.count, 1)
        XCTAssertEqual(report.failures.first?.role, .all)
        XCTAssertEqual(report.failures.first?.status, AssociationVerificationStatus.unsupportedTarget.rawValue)
    }

    func testApplyReturnsRecoveryFailuresWhenBatchWriteFails() {
        let textType = UTType(filenameExtension: "txt")!
        let markdownType = UTType(filenameExtension: "md")!
        let reader = StubAssociationReader(
            currentHandlersByIdentifierAndRole: [
                key(textType, .all): "com.apple.TextEdit",
                key(textType, .viewer): "com.apple.TextEdit",
                key(textType, .editor): "com.apple.TextEdit",
                key(markdownType, .all): "com.apple.TextEdit",
                key(markdownType, .viewer): "com.apple.TextEdit",
                key(markdownType, .editor): "com.apple.TextEdit",
            ],
            eligibleHandlersByIdentifierAndRole: [
                key(textType, .all): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(textType, .viewer): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(textType, .editor): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(markdownType, .all): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(markdownType, .viewer): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(markdownType, .editor): ["com.microsoft.VSCode", "com.apple.TextEdit"],
            ]
        )
        let writer = StubPreferenceWriter(error: LaunchServicesSilentPreferenceWriterError.failedToWritePreferences)
        let coordinator = GlobalTextSwitchCoordinator(
            associationReader: reader,
            preferenceWriter: writer,
            resolutionsProvider: {
                [
                    ContentTypeResolver.Resolution(normalizedExtension: "txt", type: textType),
                    ContentTypeResolver.Resolution(normalizedExtension: "md", type: markdownType),
                ]
            }
        )

        let report = coordinator.apply(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(
            writer.writtenAssignments,
            [
                .init(contentTypeIdentifier: textType.identifier, roles: PreferredHandlerRole.verificationOrder),
                .init(contentTypeIdentifier: markdownType.identifier, roles: PreferredHandlerRole.verificationOrder),
            ]
        )
        XCTAssertEqual(report.writeFailedCount, 2)
        XCTAssertEqual(report.failures.map(\.status), ["writeFailed", "writeFailed"])
        XCTAssertTrue(
            report.failures.allSatisfy {
                $0.diagnostic == "Silent switch could not write Launch Services preferences. Try again, or log out and back in."
            }
        )
        XCTAssertTrue(report.failures.allSatisfy { $0.statusCode == nil })
    }

    func testApplyMarksEveryWrittenEligibleTypeAsPendingVerification() {
        let textType = UTType(filenameExtension: "txt")!
        let markdownType = UTType(filenameExtension: "md")!
        let reader = StubAssociationReader(
            currentHandlersByIdentifierAndRole: [
                key(textType, .all): "com.apple.TextEdit",
                key(textType, .viewer): "com.apple.TextEdit",
                key(textType, .editor): "com.apple.TextEdit",
                key(markdownType, .all): "com.apple.TextEdit",
                key(markdownType, .viewer): "com.apple.TextEdit",
                key(markdownType, .editor): "com.apple.TextEdit",
            ],
            eligibleHandlersByIdentifierAndRole: [
                key(textType, .all): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(textType, .viewer): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(textType, .editor): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(markdownType, .all): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(markdownType, .viewer): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(markdownType, .editor): ["com.microsoft.VSCode", "com.apple.TextEdit"],
            ]
        )
        let writer = StubPreferenceWriter()
        let coordinator = GlobalTextSwitchCoordinator(
            associationReader: reader,
            preferenceWriter: writer,
            resolutionsProvider: {
                [
                    ContentTypeResolver.Resolution(normalizedExtension: "txt", type: textType),
                    ContentTypeResolver.Resolution(normalizedExtension: "md", type: markdownType),
                ]
            }
        )

        let report = coordinator.apply(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(report.matchedCount, 0)
        XCTAssertEqual(report.pendingVerificationCount, 2)
        XCTAssertEqual(report.mismatchedCount, 0)
        XCTAssertEqual(
            report.failures.map(\.status),
            [
                AssociationVerificationStatus.pendingVerification.rawValue,
                AssociationVerificationStatus.pendingVerification.rawValue,
            ]
        )
        XCTAssertEqual(report.failures.map(\.role), [.all, .all])
        XCTAssertEqual(report.failures.map(\.scopeLabel), [".txt", ".md"])
    }

    func testApplySkipsDisabledHTMLType() {
        let cssType = UTType(filenameExtension: "css")!
        let htmlType = UTType(filenameExtension: "html")!
        let reader = StubAssociationReader(
            currentHandlersByIdentifierAndRole: [
                key(cssType, .all): "com.apple.TextEdit",
                key(cssType, .viewer): "com.apple.TextEdit",
                key(cssType, .editor): "com.apple.TextEdit",
            ],
            eligibleHandlersByIdentifierAndRole: [
                key(cssType, .all): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(cssType, .viewer): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(cssType, .editor): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(htmlType, .all): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(htmlType, .viewer): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(htmlType, .editor): ["com.microsoft.VSCode", "com.apple.TextEdit"],
            ]
        )
        let writer = StubPreferenceWriter()
        let coordinator = GlobalTextSwitchCoordinator(
            associationReader: reader,
            preferenceWriter: writer,
            enabledExtensionsProvider: { ["css"] }
        )

        let report = coordinator.apply(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(
            writer.writtenAssignments,
            [
                .init(contentTypeIdentifier: cssType.identifier, roles: PreferredHandlerRole.verificationOrder)
            ]
        )
        XCTAssertEqual(report.processedExtensions, ["css"])
        XCTAssertEqual(report.processedContentTypeIdentifiers, [cssType.identifier])
        XCTAssertNotEqual(report.processedContentTypeIdentifiers, [htmlType.identifier])
    }

    func testApplyIncludesDeclaredCustomNonTextExtensionWhenEnabled() {
        let pngType = UTType(filenameExtension: "png")!
        let reader = StubAssociationReader(
            currentHandlersByIdentifierAndRole: [
                key(pngType, .all): "com.apple.Preview",
                key(pngType, .viewer): "com.apple.Preview",
                key(pngType, .editor): "com.apple.Preview",
            ],
            eligibleHandlersByIdentifierAndRole: [
                key(pngType, .all): ["com.microsoft.VSCode", "com.apple.Preview"],
                key(pngType, .viewer): ["com.microsoft.VSCode", "com.apple.Preview"],
                key(pngType, .editor): ["com.microsoft.VSCode", "com.apple.Preview"],
            ]
        )
        let writer = StubPreferenceWriter()
        let coordinator = GlobalTextSwitchCoordinator(
            associationReader: reader,
            preferenceWriter: writer,
            enabledExtensionsProvider: { ["png"] }
        )

        let report = coordinator.apply(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(
            writer.writtenAssignments,
            [
                .init(contentTypeIdentifier: pngType.identifier, roles: PreferredHandlerRole.verificationOrder)
            ]
        )
        XCTAssertEqual(report.processedExtensions, ["png"])
        XCTAssertEqual(report.processedContentTypeIdentifiers, [pngType.identifier])
    }

    func testApplySkipsUnresolvedCustomExtensionFromProcessedTypes() {
        let txtType = UTType(filenameExtension: "txt")!
        let reader = StubAssociationReader(
            currentHandlersByIdentifierAndRole: [
                key(txtType, .all): "com.apple.TextEdit",
                key(txtType, .viewer): "com.apple.TextEdit",
                key(txtType, .editor): "com.apple.TextEdit",
            ],
            eligibleHandlersByIdentifierAndRole: [
                key(txtType, .all): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(txtType, .viewer): ["com.microsoft.VSCode", "com.apple.TextEdit"],
                key(txtType, .editor): ["com.microsoft.VSCode", "com.apple.TextEdit"],
            ]
        )
        let writer = StubPreferenceWriter()
        let coordinator = GlobalTextSwitchCoordinator(
            associationReader: reader,
            preferenceWriter: writer,
            resolutionsProvider: {
                [
                    ContentTypeResolver.Resolution(normalizedExtension: "txt", type: txtType),
                    ContentTypeResolver.Resolution(normalizedExtension: "unknown-custom-type", type: nil),
                ]
            }
        )

        let report = coordinator.apply(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(
            writer.writtenAssignments,
            [
                .init(contentTypeIdentifier: txtType.identifier, roles: PreferredHandlerRole.verificationOrder)
            ]
        )
        XCTAssertEqual(report.processedExtensions, ["txt"])
        XCTAssertFalse(report.processedExtensions.contains("unknown-custom-type"))
        XCTAssertEqual(report.processedContentTypeIdentifiers, [txtType.identifier])
    }
}

private final class StubAssociationReader: LaunchServicesAssociationReading {
    private let currentHandlersByIdentifierAndRole: [String: String]
    private let eligibleHandlersByIdentifierAndRole: [String: [String]]

    init(
        currentHandlersByIdentifierAndRole: [String: String],
        eligibleHandlersByIdentifierAndRole: [String: [String]]
    ) {
        self.currentHandlersByIdentifierAndRole = currentHandlersByIdentifierAndRole
        self.eligibleHandlersByIdentifierAndRole = eligibleHandlersByIdentifierAndRole
    }

    func currentHandlerBundleID(for contentType: UTType, role: PreferredHandlerRole) -> String? {
        currentHandlersByIdentifierAndRole[key(contentType, role)]
    }

    func allHandlerBundleIDs(for contentType: UTType, role: PreferredHandlerRole) -> [String] {
        eligibleHandlersByIdentifierAndRole[key(contentType, role)] ?? []
    }
}

private final class StubPreferenceWriter: LaunchServicesPreferenceBatchWriting {
    struct RecordedAssignment: Equatable {
        let contentTypeIdentifier: String
        let roles: [PreferredHandlerRole]
    }

    private let error: Error?
    private(set) var writtenAssignments: [RecordedAssignment] = []

    init(error: Error? = nil) {
        self.error = error
    }

    func setDefaultHandlers(bundleID: String, assignments: [LaunchServicesRoleAssignment]) throws {
        writtenAssignments = assignments.map {
            RecordedAssignment(contentTypeIdentifier: $0.contentType.identifier, roles: $0.roles)
        }

        if let error {
            throw error
        }
    }
}

private func key(_ contentType: UTType, _ role: PreferredHandlerRole) -> String {
    "\(contentType.identifier)#\(role.rawValue)"
}
