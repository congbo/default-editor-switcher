import Foundation

struct MenuBarSummary: Equatable {
    let title: String
    let detail: String
}

struct MenuBarEditorRow: Identifiable, Equatable {
    let bundleID: String
    let displayName: String
    let iconLookupPath: String
    let actionTitle: String
    let capabilityNote: String?
    let isCurrent: Bool
    let isBusy: Bool
    let capability: EditorCapability

    var id: String {
        bundleID
    }
}

enum MenuBarSection: Identifiable, Equatable {
    case recommendedFullSupport(rows: [MenuBarEditorRow])
    case otherEligible(rows: [MenuBarEditorRow])
    case needsVerification(rows: [MenuBarEditorRow])

    var id: String {
        switch self {
        case .recommendedFullSupport:
            return "recommendedFullSupport"
        case .otherEligible:
            return "otherEligible"
        case .needsVerification:
            return "needsVerification"
        }
    }

    var title: String {
        switch self {
        case .recommendedFullSupport:
            return "Recommended Editors"
        case .otherEligible:
            return "Other Eligible Editors"
        case .needsVerification:
            return "Needs Verification"
        }
    }

    var rows: [MenuBarEditorRow] {
        switch self {
        case .recommendedFullSupport(let rows),
             .otherEligible(let rows),
             .needsVerification(let rows):
            return rows
        }
    }
}

struct RulesWindowAction: Equatable {
    let title: String
    let windowID: String
}
