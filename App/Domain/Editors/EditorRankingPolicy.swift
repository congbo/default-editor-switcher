import Foundation

struct EditorRankingPolicy {
    func rank(_ candidates: [EditorCandidate], for bucket: LanguageBucket? = nil) -> [EditorCandidate] {
        candidates.sorted { lhs, rhs in
            if lhs.isRecommended != rhs.isRecommended {
                return lhs.isRecommended && !rhs.isRecommended
            }

            let lhsWeight = KnownEditors.weight(for: lhs.bundleID, bucket: bucket)
            let rhsWeight = KnownEditors.weight(for: rhs.bundleID, bucket: bucket)

            if lhsWeight != rhsWeight {
                return lhsWeight > rhsWeight
            }

            if lhs.displayName != rhs.displayName {
                return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }

            return lhs.bundleID < rhs.bundleID
        }
    }
}
