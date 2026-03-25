import CoreServices
import Foundation

enum AssociationVerificationResult: Hashable {
    case matched(PreferredHandler)
    case mismatched(PreferredHandler)
    case unsupportedTarget(PreferredHandler)
    case writeFailed(PreferredHandler, status: OSStatus)

    var status: String {
        switch self {
        case .matched:
            return "matched"
        case .mismatched:
            return "mismatched"
        case .unsupportedTarget:
            return "unsupportedTarget"
        case .writeFailed:
            return "writeFailed"
        }
    }

    var preferredHandler: PreferredHandler {
        switch self {
        case .matched(let handler),
             .mismatched(let handler),
             .unsupportedTarget(let handler),
             .writeFailed(let handler, _):
            return handler
        }
    }

    var requestedBundleID: String {
        preferredHandler.requestedBundleID
    }

    var effectiveBundleID: String? {
        preferredHandler.effectiveBundleID
    }
}
