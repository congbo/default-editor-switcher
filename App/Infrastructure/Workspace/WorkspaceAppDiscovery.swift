import AppKit
import Foundation
import UniformTypeIdentifiers

protocol WorkspaceApplicationURLProviding {
    func urlsForApplications(toOpen contentType: UTType) -> [URL]
}

protocol ApplicationBundleInspecting {
    func bundleIdentifier(for bundleURL: URL) -> String?
    func displayName(for bundleURL: URL) -> String?
    func iconLookupPath(for bundleURL: URL) -> String
    func metadata(for bundleURL: URL) -> BundleDocumentTypeMetadata
}

struct SystemWorkspaceApplicationURLProvider: WorkspaceApplicationURLProviding {
    func urlsForApplications(toOpen contentType: UTType) -> [URL] {
        NSWorkspace.shared.urlsForApplications(toOpen: contentType)
    }
}

struct SystemApplicationBundleInspector: ApplicationBundleInspecting {
    private let reader = BundleDocumentTypeReader()

    func bundleIdentifier(for bundleURL: URL) -> String? {
        Bundle(url: bundleURL)?.bundleIdentifier
    }

    func displayName(for bundleURL: URL) -> String? {
        guard let bundle = Bundle(url: bundleURL) else {
            return nil
        }

        return bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
    }

    func iconLookupPath(for bundleURL: URL) -> String {
        bundleURL.path
    }

    func metadata(for bundleURL: URL) -> BundleDocumentTypeMetadata {
        reader.metadata(for: bundleURL)
    }
}

struct WorkspaceAppDiscovery {
    private let workspace: WorkspaceApplicationURLProviding
    private let bundleInspector: ApplicationBundleInspecting
    private let rankingPolicy: EditorRankingPolicy

    init(
        workspace: WorkspaceApplicationURLProviding = SystemWorkspaceApplicationURLProvider(),
        bundleInspector: ApplicationBundleInspecting = SystemApplicationBundleInspector(),
        rankingPolicy: EditorRankingPolicy = EditorRankingPolicy()
    ) {
        self.workspace = workspace
        self.bundleInspector = bundleInspector
        self.rankingPolicy = rankingPolicy
    }

    func discoverEditors(
        for contentType: UTType,
        bucket: LanguageBucket? = nil
    ) -> [EditorCandidate] {
        let candidates = workspace.urlsForApplications(toOpen: contentType).map { bundleURL in
            candidate(for: bundleURL, requestedContentType: contentType)
        }

        return rankingPolicy.rank(deduplicatedCandidates(candidates), for: bucket)
    }

    func candidate(for bundleURL: URL, requestedContentType: UTType) -> EditorCandidate {
        let metadata = bundleInspector.metadata(for: bundleURL)
        let bundleID = bundleInspector.bundleIdentifier(for: bundleURL) ?? metadata.bundleID
        let displayName = bundleInspector.displayName(for: bundleURL) ?? metadata.displayName
        let source: EditorCandidateSource = KnownEditors.isRecommended(bundleID: bundleID)
            ? .recommendedCatalog
            : .systemEligible

        return EditorCandidate(
            bundleID: bundleID,
            displayName: displayName,
            iconLookupPath: bundleInspector.iconLookupPath(for: bundleURL),
            source: source,
            capability: capability(for: metadata, requestedContentType: requestedContentType),
            supportedTextExtensionCount: metadata.supportedExtensionCount(for: .allText)
        )
    }

    func capability(
        for metadata: BundleDocumentTypeMetadata,
        requestedContentType: UTType
    ) -> EditorCapability {
        capability(for: Optional(metadata), requestedContentType: requestedContentType)
    }

    func capability(
        for metadata: BundleDocumentTypeMetadata?,
        requestedContentType: UTType
    ) -> EditorCapability {
        guard let metadata else {
            return .unverified
        }

        guard metadata.hasDocumentTypes else {
            return .unverified
        }

        if metadata.supports(contentType: requestedContentType) {
            return .full
        }

        return .partial
    }

    private func deduplicatedCandidates(_ candidates: [EditorCandidate]) -> [EditorCandidate] {
        var candidatesByBundleID: [String: EditorCandidate] = [:]
        var orderedBundleIDs: [String] = []

        for candidate in candidates {
            if let existing = candidatesByBundleID[candidate.bundleID] {
                if shouldReplace(existing, with: candidate) {
                    candidatesByBundleID[candidate.bundleID] = candidate
                }
            } else {
                orderedBundleIDs.append(candidate.bundleID)
                candidatesByBundleID[candidate.bundleID] = candidate
            }
        }

        return orderedBundleIDs.compactMap { candidatesByBundleID[$0] }
    }

    private func shouldReplace(_ existing: EditorCandidate, with candidate: EditorCandidate) -> Bool {
        let existingCapabilityScore = capabilityScore(existing.capability)
        let candidateCapabilityScore = capabilityScore(candidate.capability)
        if candidateCapabilityScore != existingCapabilityScore {
            return candidateCapabilityScore > existingCapabilityScore
        }

        if candidate.supportedTextExtensionCount != existing.supportedTextExtensionCount {
            return candidate.supportedTextExtensionCount > existing.supportedTextExtensionCount
        }

        return false
    }

    private func capabilityScore(_ capability: EditorCapability) -> Int {
        switch capability {
        case .full:
            return 3
        case .partial:
            return 2
        case .unverified:
            return 1
        }
    }
}
