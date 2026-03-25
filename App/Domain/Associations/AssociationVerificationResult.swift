import CoreServices
import Foundation
import UniformTypeIdentifiers

enum AssociationVerificationStatus: String, Hashable {
    case matched
    case mismatched
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
        case .matched:
            return 3
        }
    }
}

struct AssociationRoleVerificationResult: Hashable {
    let preferredHandler: PreferredHandler
    let status: AssociationVerificationStatus
    let statusCode: OSStatus?

    static func matched(_ handler: PreferredHandler) -> Self {
        .init(preferredHandler: handler, status: .matched, statusCode: nil)
    }

    static func mismatched(_ handler: PreferredHandler) -> Self {
        .init(preferredHandler: handler, status: .mismatched, statusCode: nil)
    }

    static func unsupportedTarget(_ handler: PreferredHandler) -> Self {
        .init(preferredHandler: handler, status: .unsupportedTarget, statusCode: nil)
    }

    static func writeFailed(_ handler: PreferredHandler, status: OSStatus) -> Self {
        .init(preferredHandler: handler, status: .writeFailed, statusCode: status)
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
        roleResults
            .filter { $0.status != .matched }
            .sorted(by: preferredOrdering)
            .first
    }

    private var editorRoleResult: AssociationRoleVerificationResult? {
        roleResults.first { $0.preferredHandler.role == .editor }
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
