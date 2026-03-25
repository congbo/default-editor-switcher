import Foundation

enum EditorCandidateSource: Hashable {
    case recommendedCatalog
    case systemEligible
}

enum EditorCapability: Hashable {
    case full
    case partial
    case unverified
}

struct EditorCandidate: Hashable {
    let bundleID: String
    let displayName: String
    let iconLookupPath: String
    let source: EditorCandidateSource
    let capability: EditorCapability
    let isRecommended: Bool

    init(
        bundleID: String,
        displayName: String,
        iconLookupPath: String = "<placeholder>",
        source: EditorCandidateSource,
        capability: EditorCapability
    ) {
        self.bundleID = bundleID
        self.displayName = displayName
        self.iconLookupPath = iconLookupPath
        self.source = source
        self.capability = capability
        self.isRecommended = source == .recommendedCatalog
    }
}
