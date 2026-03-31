import XCTest
import UniformTypeIdentifiers
@testable import DefaultEditorSwitcher

final class GlobalTextSwitchCoordinatorTests: XCTestCase {
    func testApplyWritesAllDeclaredTypesUsingEditorRoleOnly() {
        let textType = UTType(filenameExtension: "txt")!
        let markdownType = UTType(filenameExtension: "md")!
        let verifier = StubAssociationVerifier(
            resultsByIdentifier: [
                textType.identifier: makeResult(
                    for: textType,
                    requestedBundleID: "com.microsoft.VSCode",
                    roleResults: [
                        .matched(
                            PreferredHandler(
                                contentType: textType,
                                requestedBundleID: "com.microsoft.VSCode",
                                effectiveBundleID: "com.microsoft.VSCode",
                                role: .editor
                            )
                        )
                    ]
                ),
                markdownType.identifier: makeResult(
                    for: markdownType,
                    requestedBundleID: "com.microsoft.VSCode",
                    roleResults: [
                        .matched(
                            PreferredHandler(
                                contentType: markdownType,
                                requestedBundleID: "com.microsoft.VSCode",
                                effectiveBundleID: "com.microsoft.VSCode",
                                role: .editor
                            )
                        )
                    ]
                ),
            ]
        )
        let coordinator = GlobalTextSwitchCoordinator(
            verifier: verifier,
            resolutionsProvider: {
                [
                    ContentTypeResolver.Resolution(normalizedExtension: "txt", type: textType),
                    ContentTypeResolver.Resolution(normalizedExtension: "md", type: markdownType),
                    ContentTypeResolver.Resolution(normalizedExtension: "mystery", type: nil),
                    ContentTypeResolver.Resolution(normalizedExtension: "txt-copy", type: textType),
                ]
            }
        )

        let report = coordinator.apply(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(verifier.verifiedIdentifiers, [textType.identifier, markdownType.identifier])
        XCTAssertEqual(verifier.verifiedRoles, [[.editor], [.editor]])
        XCTAssertEqual(report.processedContentTypeIdentifiers, [textType.identifier, markdownType.identifier])
        XCTAssertEqual(report.processedExtensions, ["txt", "md", "txt-copy"])
        XCTAssertEqual(report.matchedCount, 2)
    }

    func testAggregateReportCountsMatchedAndFailedResults() {
        let textType = UTType(filenameExtension: "txt")!
        let markdownType = UTType(filenameExtension: "md")!
        let pythonType = UTType(filenameExtension: "py")!
        let rustType = UTType(filenameExtension: "rs")!
        let verifier = StubAssociationVerifier(
            resultsByIdentifier: [
                textType.identifier: makeResult(
                    for: textType,
                    requestedBundleID: "com.example.editor",
                    roleResults: [
                        .matched(
                            PreferredHandler(
                                contentType: textType,
                                requestedBundleID: "com.example.editor",
                                effectiveBundleID: "com.example.editor",
                                role: .editor
                            )
                        )
                    ]
                ),
                markdownType.identifier: makeResult(
                    for: markdownType,
                    requestedBundleID: "com.example.editor",
                    roleResults: [
                        .mismatched(
                            PreferredHandler(
                                contentType: markdownType,
                                requestedBundleID: "com.example.editor",
                                effectiveBundleID: "com.apple.TextEdit",
                                role: .editor
                            )
                        )
                    ]
                ),
                pythonType.identifier: makeResult(
                    for: pythonType,
                    requestedBundleID: "com.example.editor",
                    roleResults: [
                        .unsupportedTarget(
                            PreferredHandler(
                                contentType: pythonType,
                                requestedBundleID: "com.example.editor",
                                effectiveBundleID: nil,
                                role: .editor
                            )
                        )
                    ]
                ),
                rustType.identifier: makeResult(
                    for: rustType,
                    requestedBundleID: "com.example.editor",
                    roleResults: [
                        .writeFailed(
                            PreferredHandler(
                                contentType: rustType,
                                requestedBundleID: "com.example.editor",
                                effectiveBundleID: "com.apple.TextEdit",
                                role: .editor
                            ),
                            status: -10810
                        )
                    ]
                ),
            ]
        )
        let coordinator = GlobalTextSwitchCoordinator(
            verifier: verifier,
            resolutionsProvider: {
                [
                    ContentTypeResolver.Resolution(normalizedExtension: "txt", type: textType),
                    ContentTypeResolver.Resolution(normalizedExtension: "md", type: markdownType),
                    ContentTypeResolver.Resolution(normalizedExtension: "py", type: pythonType),
                    ContentTypeResolver.Resolution(normalizedExtension: "rs", type: rustType),
                ]
            }
        )

        let report = coordinator.apply(bundleID: "com.example.editor")

        XCTAssertEqual(report.matchedCount, 1)
        XCTAssertEqual(report.mismatchedCount, 1)
        XCTAssertEqual(report.unsupportedCount, 1)
        XCTAssertEqual(report.writeFailedCount, 1)
        XCTAssertEqual(report.failures.map(\.scopeLabel), [".md", ".py", ".rs"])
        XCTAssertEqual(report.failures.map(\.status), ["mismatched", "unsupportedTarget", "writeFailed"])
        XCTAssertEqual(report.processedExtensions, ["txt", "md", "py", "rs"])
        XCTAssertEqual(report.sampleFailures.map(\.scopeLabel), [".md", ".py", ".rs"])
        XCTAssertEqual(report.sampleFailures.map(\.status), ["mismatched", "unsupportedTarget", "writeFailed"])
        XCTAssertEqual(report.sampleFailures.map(\.role), [.editor, .editor, .editor])
        XCTAssertEqual(report.sampleFailures.last?.statusCode, -10810)
    }

    func testApplySkipsDisabledHTMLType() {
        let cssType = UTType(filenameExtension: "css")!
        let htmlType = UTType(filenameExtension: "html")!
        let verifier = StubAssociationVerifier(
            resultsByIdentifier: [
                cssType.identifier: makeResult(
                    for: cssType,
                    requestedBundleID: "com.microsoft.VSCode",
                    roleResults: [
                        .matched(
                            PreferredHandler(
                                contentType: cssType,
                                requestedBundleID: "com.microsoft.VSCode",
                                effectiveBundleID: "com.microsoft.VSCode",
                                role: .editor
                            )
                        )
                    ]
                ),
                htmlType.identifier: makeResult(
                    for: htmlType,
                    requestedBundleID: "com.microsoft.VSCode",
                    roleResults: [
                        .matched(
                            PreferredHandler(
                                contentType: htmlType,
                                requestedBundleID: "com.microsoft.VSCode",
                                effectiveBundleID: "com.microsoft.VSCode",
                                role: .editor
                            )
                        )
                    ]
                )
            ]
        )
        let coordinator = GlobalTextSwitchCoordinator(
            verifier: verifier,
            enabledExtensionsProvider: { ["css"] }
        )

        let report = coordinator.apply(bundleID: "com.microsoft.VSCode")

        XCTAssertEqual(verifier.verifiedIdentifiers, [cssType.identifier])
        XCTAssertEqual(report.processedExtensions, ["css"])
        XCTAssertEqual(report.processedContentTypeIdentifiers, [cssType.identifier])
        XCTAssertNotEqual(report.processedContentTypeIdentifiers, [htmlType.identifier])
    }
}

private final class StubAssociationVerifier: LaunchServicesAssociationVerifying {
    private let resultsByIdentifier: [String: AssociationVerificationResult]
    private(set) var verifiedIdentifiers: [String] = []
    private(set) var verifiedRoles: [[PreferredHandlerRole]] = []

    init(resultsByIdentifier: [String: AssociationVerificationResult]) {
        self.resultsByIdentifier = resultsByIdentifier
    }

    func verify(
        requestedBundleID: String,
        for contentType: UTType,
        roles: [PreferredHandlerRole]
    ) -> AssociationVerificationResult {
        verifiedIdentifiers.append(contentType.identifier)
        verifiedRoles.append(roles)
        return resultsByIdentifier[contentType.identifier]
            ?? makeResult(
                for: contentType,
                requestedBundleID: requestedBundleID,
                roleResults: [
                    .unsupportedTarget(
                        PreferredHandler(
                            contentType: contentType,
                            requestedBundleID: requestedBundleID,
                            effectiveBundleID: nil,
                            role: .editor
                        )
                    )
                ]
            )
    }
}

private func makeResult(
    for contentType: UTType,
    requestedBundleID: String,
    roleResults: [AssociationRoleVerificationResult]
) -> AssociationVerificationResult {
    AssociationVerificationResult(
        contentType: contentType,
        requestedBundleID: requestedBundleID,
        roleResults: roleResults
    )
}
