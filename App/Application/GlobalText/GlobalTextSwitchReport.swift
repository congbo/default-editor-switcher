import CoreServices
import Foundation

struct GlobalTextSwitchReport: Equatable {
    struct SampleFailure: Equatable, Hashable {
        let contentTypeIdentifier: String
        let role: PreferredHandlerRole
        let status: String
        let effectiveBundleID: String?
        let statusCode: OSStatus?
    }

    let requestedBundleID: String
    let matchedCount: Int
    let mismatchedCount: Int
    let unsupportedCount: Int
    let writeFailedCount: Int
    let processedContentTypeIdentifiers: [String]
    let processedExtensions: [String]
    let sampleFailures: [SampleFailure]

    var totalProcessedCount: Int {
        processedContentTypeIdentifiers.count
    }

    var affectedCount: Int {
        mismatchedCount + unsupportedCount + writeFailedCount
    }

    var didFullyMatch: Bool {
        totalProcessedCount > 0 && affectedCount == 0
    }
}
