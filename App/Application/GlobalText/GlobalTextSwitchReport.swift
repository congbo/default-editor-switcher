import CoreServices
import Foundation

struct GlobalTextSwitchReport: Equatable {
    struct Failure: Equatable, Hashable {
        let contentTypeIdentifier: String
        let scopeLabel: String
        let role: PreferredHandlerRole
        let status: String
        let effectiveBundleID: String?
        let statusCode: OSStatus?
        let diagnostic: String?

        init(
            contentTypeIdentifier: String,
            scopeLabel: String,
            role: PreferredHandlerRole,
            status: String,
            effectiveBundleID: String?,
            statusCode: OSStatus?,
            diagnostic: String? = nil
        ) {
            self.contentTypeIdentifier = contentTypeIdentifier
            self.scopeLabel = scopeLabel
            self.role = role
            self.status = status
            self.effectiveBundleID = effectiveBundleID
            self.statusCode = statusCode
            self.diagnostic = diagnostic
        }
    }

    typealias SampleFailure = Failure

    let requestedBundleID: String
    let matchedCount: Int
    let mismatchedCount: Int
    let pendingVerificationCount: Int
    let unsupportedCount: Int
    let writeFailedCount: Int
    let processedContentTypeIdentifiers: [String]
    let processedExtensions: [String]
    let failures: [Failure]

    init(
        requestedBundleID: String,
        matchedCount: Int,
        mismatchedCount: Int,
        pendingVerificationCount: Int = 0,
        unsupportedCount: Int,
        writeFailedCount: Int,
        processedContentTypeIdentifiers: [String],
        processedExtensions: [String],
        failures: [Failure]
    ) {
        self.requestedBundleID = requestedBundleID
        self.matchedCount = matchedCount
        self.mismatchedCount = mismatchedCount
        self.pendingVerificationCount = pendingVerificationCount
        self.unsupportedCount = unsupportedCount
        self.writeFailedCount = writeFailedCount
        self.processedContentTypeIdentifiers = processedContentTypeIdentifiers
        self.processedExtensions = processedExtensions
        self.failures = failures
    }

    init(
        requestedBundleID: String,
        matchedCount: Int,
        mismatchedCount: Int,
        pendingVerificationCount: Int = 0,
        unsupportedCount: Int,
        writeFailedCount: Int,
        processedContentTypeIdentifiers: [String],
        processedExtensions: [String],
        sampleFailures: [SampleFailure]
    ) {
        self.init(
            requestedBundleID: requestedBundleID,
            matchedCount: matchedCount,
            mismatchedCount: mismatchedCount,
            pendingVerificationCount: pendingVerificationCount,
            unsupportedCount: unsupportedCount,
            writeFailedCount: writeFailedCount,
            processedContentTypeIdentifiers: processedContentTypeIdentifiers,
            processedExtensions: processedExtensions,
            failures: sampleFailures
        )
    }

    var totalProcessedCount: Int {
        processedContentTypeIdentifiers.count
    }

    var affectedCount: Int {
        mismatchedCount + unsupportedCount + writeFailedCount
    }

    var hasBlockingFailures: Bool {
        affectedCount > 0
    }

    var sampleFailures: [SampleFailure] {
        Array(
            failures
                .filter { $0.status != AssociationVerificationStatus.pendingVerification.rawValue }
                .prefix(3)
        )
    }

    var didFullyMatch: Bool {
        totalProcessedCount > 0 && affectedCount == 0 && pendingVerificationCount == 0
    }

    var canOptimisticallyPresentRequestedEditor: Bool {
        totalProcessedCount > 0 && !hasBlockingFailures
    }
}
