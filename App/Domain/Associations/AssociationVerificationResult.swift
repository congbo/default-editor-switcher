import CoreServices
import Foundation
import UniformTypeIdentifiers

enum AssociationVerificationStatus: String, Hashable {
    case matched
    case mismatched
    case pendingVerification
    case unsupportedTarget
    case writeFailed

    var priority: Int {
        switch self {
        case .writeFailed:
            return 0
        case .unsupportedTarget:
            return 1
        case .mismatched:
            return 2
        case .pendingVerification:
            return 3
        case .matched:
            return 4
        }
    }
}

struct AssociationRoleVerificationResult: Hashable {
    let preferredHandler: PreferredHandler
    let status: AssociationVerificationStatus
    let statusCode: OSStatus?
    let diagnostic: String?

    static func matched(_ handler: PreferredHandler) -> Self {
        .init(preferredHandler: handler, status: .matched, statusCode: nil, diagnostic: nil)
    }

    static func mismatched(_ handler: PreferredHandler) -> Self {
        .init(preferredHandler: handler, status: .mismatched, statusCode: nil, diagnostic: nil)
    }

    static func pendingVerification(_ handler: PreferredHandler, diagnostic: String? = nil) -> Self {
        .init(preferredHandler: handler, status: .pendingVerification, statusCode: nil, diagnostic: diagnostic)
    }

    static func unsupportedTarget(_ handler: PreferredHandler) -> Self {
        .init(preferredHandler: handler, status: .unsupportedTarget, statusCode: nil, diagnostic: nil)
    }

    static func writeFailed(_ handler: PreferredHandler, status: OSStatus) -> Self {
        .init(preferredHandler: handler, status: .writeFailed, statusCode: status, diagnostic: nil)
    }

    static func writeFailed(_ handler: PreferredHandler, diagnostic: String) -> Self {
        .init(preferredHandler: handler, status: .writeFailed, statusCode: nil, diagnostic: diagnostic)
    }
}

struct AssociationVerificationResult: Hashable {
    let contentTypeIdentifier: String
    let requestedBundleID: String
    let roleResults: [AssociationRoleVerificationResult]

    init(
        contentTypeIdentifier: String,
        requestedBundleID: String,
        roleResults: [AssociationRoleVerificationResult]
    ) {
        self.contentTypeIdentifier = contentTypeIdentifier
        self.requestedBundleID = requestedBundleID
        self.roleResults = roleResults
    }

    init(
        contentType: UTType,
        requestedBundleID: String,
        roleResults: [AssociationRoleVerificationResult]
    ) {
        self.init(
            contentTypeIdentifier: contentType.identifier,
            requestedBundleID: requestedBundleID,
            roleResults: roleResults
        )
    }

    var status: String {
        aggregateStatus.rawValue
    }

    var aggregateStatus: AssociationVerificationStatus {
        primaryRoleResult?.status ?? .matched
    }

    var preferredHandler: PreferredHandler {
        primaryRoleResult?.preferredHandler
            ?? editorRoleResult?.preferredHandler
            ?? roleResults.first?.preferredHandler
            ?? PreferredHandler(
                contentTypeIdentifier: contentTypeIdentifier,
                requestedBundleID: requestedBundleID,
                effectiveBundleID: nil
            )
    }

    var effectiveBundleID: String? {
        preferredHandler.effectiveBundleID
    }

    var primaryRoleResult: AssociationRoleVerificationResult? {
        guard let openerRoleResult else {
            return roleResults
                .filter { $0.status != .matched }
                .sorted(by: preferredOrdering)
                .first
        }

        guard openerRoleResult.status != .matched else {
            return nil
        }

        return openerRoleResult
    }

    private var editorRoleResult: AssociationRoleVerificationResult? {
        roleResults.first { $0.preferredHandler.role == .editor }
    }

    private var openerRoleResult: AssociationRoleVerificationResult? {
        for role in PreferredHandlerRole.verificationOrder {
            guard let roleResult = roleResults.first(where: { $0.preferredHandler.role == role }) else {
                continue
            }

            if roleResult.preferredHandler.effectiveBundleID != nil
                || roleResult.status != .unsupportedTarget {
                return roleResult
            }
        }

        return roleResults.min {
            $0.preferredHandler.role.verificationIndex < $1.preferredHandler.role.verificationIndex
        }
    }

    private func preferredOrdering(
        _ lhs: AssociationRoleVerificationResult,
        _ rhs: AssociationRoleVerificationResult
    ) -> Bool {
        if lhs.status.priority != rhs.status.priority {
            return lhs.status.priority < rhs.status.priority
        }

        return lhs.preferredHandler.role.verificationIndex < rhs.preferredHandler.role.verificationIndex
    }
}

private extension PreferredHandlerRole {
    var verificationIndex: Int {
        PreferredHandlerRole.verificationOrder.firstIndex(of: self) ?? .max
    }
}
