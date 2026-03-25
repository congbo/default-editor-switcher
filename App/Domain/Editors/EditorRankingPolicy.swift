import Foundation

struct EditorRankingPolicy {
    func rank(
        _ candidates: [EditorCandidate],
        for bucket: LanguageBucket? = nil,
        preferredBundleIDs: [String] = []
    ) -> [EditorCandidate] {
        let preferredOrder = Dictionary(
            uniqueKeysWithValues: preferredBundleIDs.enumerated().map { ($1, $0) }
        )

        return candidates.sorted { lhs, rhs in
            let lhsPreferredOrder = preferredOrder[lhs.bundleID]
            let rhsPreferredOrder = preferredOrder[rhs.bundleID]

            if let lhsPreferredOrder, let rhsPreferredOrder, lhsPreferredOrder != rhsPreferredOrder {
                return lhsPreferredOrder < rhsPreferredOrder
            }

            if lhsPreferredOrder != nil, rhsPreferredOrder == nil {
                return true
            }

            if lhsPreferredOrder == nil, rhsPreferredOrder != nil {
                return false
            }

            if lhs.isRecommended != rhs.isRecommended {
                return lhs.isRecommended && !rhs.isRecommended
            }

            if bucket == nil {
                if lhs.isRecommended && rhs.isRecommended {
                    let lhsOrder = KnownEditors.menuSortOrder(for: lhs.bundleID) ?? Int.max
                    let rhsOrder = KnownEditors.menuSortOrder(for: rhs.bundleID) ?? Int.max

                    if lhsOrder != rhsOrder {
                        return lhsOrder < rhsOrder
                    }
                }

                if !lhs.isRecommended && !rhs.isRecommended,
                   lhs.supportedTextExtensionCount != rhs.supportedTextExtensionCount {
                    return lhs.supportedTextExtensionCount > rhs.supportedTextExtensionCount
                }
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
