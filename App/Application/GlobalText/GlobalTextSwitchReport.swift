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
    }

    typealias SampleFailure = Failure

    let requestedBundleID: String
    let matchedCount: Int
    let mismatchedCount: Int
    let unsupportedCount: Int
    let writeFailedCount: Int
    let processedContentTypeIdentifiers: [String]
    let processedExtensions: [String]
    let failures: [Failure]

    init(
        requestedBundleID: String,
        matchedCount: Int,
        mismatchedCount: Int,
        unsupportedCount: Int,
        writeFailedCount: Int,
        processedContentTypeIdentifiers: [String],
        processedExtensions: [String],
        failures: [Failure]
    ) {
        self.requestedBundleID = requestedBundleID
        self.matchedCount = matchedCount
        self.mismatchedCount = mismatchedCount
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

    var sampleFailures: [SampleFailure] {
        Array(failures.prefix(3))
    }

    var didFullyMatch: Bool {
        totalProcessedCount > 0 && affectedCount == 0
    }
}
