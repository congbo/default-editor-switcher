import XCTest
import UniformTypeIdentifiers
@testable import DefaultEditorSwitcher

final class GlobalTextSwitchCoordinatorTests: XCTestCase {
    func testApplyWritesAllDeclaredTypes() {
        let textType = UTType(filenameExtension: "txt")!
        let markdownType = UTType(filenameExtension: "md")!
        let verifier = StubAssociationVerifier(
            resultsByIdentifier: [
                textType.identifier: makeResult(
                    for: textType,
                    requestedBundleID: "com.microsoft.VSCode",
                    roleResults: PreferredHandlerRole.verificationOrder.map {
                        .matched(
                            PreferredHandler(
                                contentType: textType,
                                requestedBundleID: "com.microsoft.VSCode",
                                effectiveBundleID: "com.microsoft.VSCode",
                                role: $0
                            )
                        )
                    }
                ),
                markdownType.identifier: makeResult(
                    for: markdownType,
                    requestedBundleID: "com.microsoft.VSCode",
                    roleResults: PreferredHandlerRole.verificationOrder.map {
                        .matched(
                            PreferredHandler(
                                contentType: markdownType,
                                requestedBundleID: "com.microsoft.VSCode",
                                effectiveBundleID: "com.microsoft.VSCode",
                                role: $0
                            )
                        )
                    }
                ),
            ]
        )
        let coordinator = GlobalTextSwitchCoordinator(
            verifier: verifier,
            resolutionsProvider: { _ in
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
                    roleResults: PreferredHandlerRole.verificationOrder.map {
                        .matched(
                            PreferredHandler(
                                contentType: textType,
                                requestedBundleID: "com.example.editor",
                                effectiveBundleID: "com.example.editor",
                                role: $0
                            )
                        )
                    }
                ),
                markdownType.identifier: makeResult(
                    for: markdownType,
                    requestedBundleID: "com.example.editor",
                    roleResults: [
                        .matched(
                            PreferredHandler(
                                contentType: markdownType,
                                requestedBundleID: "com.example.editor",
                                effectiveBundleID: "com.example.editor",
                                role: .all
                            )
                        ),
                        .mismatched(
                            PreferredHandler(
                                contentType: markdownType,
                                requestedBundleID: "com.example.editor",
                                effectiveBundleID: "com.apple.TextEdit",
                                role: .viewer
                            )
                        ),
                        .matched(
                            PreferredHandler(
                                contentType: markdownType,
                                requestedBundleID: "com.example.editor",
                                effectiveBundleID: "com.example.editor",
                                role: .editor
                            )
                        ),
                    ]
                ),
                pythonType.identifier: makeResult(
                    for: pythonType,
                    requestedBundleID: "com.example.editor",
                    roleResults: [
                        .matched(
                            PreferredHandler(
                                contentType: pythonType,
                                requestedBundleID: "com.example.editor",
                                effectiveBundleID: "com.example.editor",
                                role: .all
                            )
                        ),
                        .matched(
                            PreferredHandler(
                                contentType: pythonType,
                                requestedBundleID: "com.example.editor",
                                effectiveBundleID: "com.example.editor",
                                role: .viewer
                            )
                        ),
                        .unsupportedTarget(
                            PreferredHandler(
                                contentType: pythonType,
                                requestedBundleID: "com.example.editor",
                                effectiveBundleID: nil,
                                role: .editor
                            )
                        ),
                    ]
                ),
                rustType.identifier: makeResult(
                    for: rustType,
                    requestedBundleID: "com.example.editor",
                    roleResults: [
                        .matched(
                            PreferredHandler(
                                contentType: rustType,
                                requestedBundleID: "com.example.editor",
                                effectiveBundleID: "com.example.editor",
                                role: .all
                            )
                        ),
                        .writeFailed(
                            PreferredHandler(
                                contentType: rustType,
                                requestedBundleID: "com.example.editor",
                                effectiveBundleID: "com.apple.TextEdit",
                                role: .viewer
                            ),
                            status: -10810
                        ),
                        .matched(
                            PreferredHandler(
                                contentType: rustType,
                                requestedBundleID: "com.example.editor",
                                effectiveBundleID: "com.example.editor",
                                role: .editor
                            )
                        ),
                    ]
                ),
            ]
        )
        let coordinator = GlobalTextSwitchCoordinator(
            verifier: verifier,
            resolutionsProvider: { _ in
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
        XCTAssertEqual(report.processedExtensions, ["txt", "md", "py", "rs"])
        XCTAssertEqual(report.sampleFailures.map(\.status), ["mismatched", "unsupportedTarget", "writeFailed"])
        XCTAssertEqual(report.sampleFailures.map(\.role), [.viewer, .editor, .viewer])
        XCTAssertEqual(report.sampleFailures.last?.statusCode, -10810)
    }
}

private final class StubAssociationVerifier: LaunchServicesAssociationVerifying {
    private let resultsByIdentifier: [String: AssociationVerificationResult]
    private(set) var verifiedIdentifiers: [String] = []

    init(resultsByIdentifier: [String: AssociationVerificationResult]) {
        self.resultsByIdentifier = resultsByIdentifier
    }

    func verify(requestedBundleID: String, for contentType: UTType) -> AssociationVerificationResult {
        verifiedIdentifiers.append(contentType.identifier)
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
                            role: .all
                        )
                    ),
                    .unsupportedTarget(
                        PreferredHandler(
                            contentType: contentType,
                            requestedBundleID: requestedBundleID,
                            effectiveBundleID: nil,
                            role: .viewer
                        )
                    ),
                    .unsupportedTarget(
                        PreferredHandler(
                            contentType: contentType,
                            requestedBundleID: requestedBundleID,
                            effectiveBundleID: nil,
                            role: .editor
                        )
                    ),
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
