import Foundation
import UniformTypeIdentifiers

protocol LaunchServicesAssociationVerifying {
    func verify(
        requestedBundleID: String,
        for contentType: UTType,
        roles: [PreferredHandlerRole]
    ) -> AssociationVerificationResult
}

extension LaunchServicesAssociationVerifier: LaunchServicesAssociationVerifying {}

extension LaunchServicesAssociationVerifying {
    func verify(requestedBundleID: String, for contentType: UTType) -> AssociationVerificationResult {
        verify(
            requestedBundleID: requestedBundleID,
            for: contentType,
            roles: PreferredHandlerRole.verificationOrder
        )
    }
}

protocol LaunchServicesAssociationReading {
    func currentHandlerBundleID(for contentType: UTType, role: PreferredHandlerRole) -> String?
    func allHandlerBundleIDs(for contentType: UTType, role: PreferredHandlerRole) -> [String]
}

extension LaunchServicesClient: LaunchServicesAssociationReading {}

protocol GlobalTextSwitchCoordinating {
    func apply(bundleID: String) -> GlobalTextSwitchReport
}

struct GlobalTextSwitchCoordinator: GlobalTextSwitchCoordinating {
    private let associationReader: LaunchServicesAssociationReading
    private let preferenceWriter: LaunchServicesPreferenceBatchWriting
    private let resolutionsProvider: () -> [ContentTypeResolver.Resolution]

    init(
        associationReader: LaunchServicesAssociationReading = LaunchServicesClient(),
        preferenceWriter: LaunchServicesPreferenceBatchWriting = LaunchServicesSilentPreferenceWriter(),
        resolutionsProvider: (() -> [ContentTypeResolver.Resolution])? = nil,
        enabledExtensionsProvider: @escaping () -> Set<String> = {
            ContentTypeResolver.defaultEnabledGlobalTextExtensions
        }
    ) {
        self.associationReader = associationReader
        self.preferenceWriter = preferenceWriter
        self.resolutionsProvider = resolutionsProvider ?? {
            ContentTypeResolver.resolutions(forExtensions: enabledExtensionsProvider())
        }
    }

    func apply(bundleID: String) -> GlobalTextSwitchReport {
        let declaredResolutions = declaredResolutions()
        let scopeLabelsByContentType = scopeLabelsByContentType(from: declaredResolutions)
        let contentTypes = declaredContentTypes(from: declaredResolutions)
        var roleResultsByIdentifier: [String: [AssociationRoleVerificationResult]] = [:]
        let assignments: [LaunchServicesRoleAssignment] = contentTypes.compactMap { contentType in
            let evaluation = evaluatedRoleResults(for: contentType, requestedBundleID: bundleID)
            roleResultsByIdentifier[contentType.identifier] = evaluation.roleResults
            guard !evaluation.rolesToWrite.isEmpty else {
                return nil
            }

            return LaunchServicesRoleAssignment(
                contentType: contentType,
                roles: evaluation.rolesToWrite
            )
        }

        if !assignments.isEmpty {
            do {
                try preferenceWriter.setDefaultHandlers(bundleID: bundleID, assignments: assignments)
            } catch {
                let diagnostic = error.localizedDescription
                for assignment in assignments {
                    let identifier = assignment.contentType.identifier
                    let existingResults = roleResultsByIdentifier[identifier] ?? []
                    roleResultsByIdentifier[identifier] = existingResults.map { roleResult in
                        guard assignment.roles.contains(roleResult.preferredHandler.role),
                              roleResult.status == .pendingVerification else {
                            return roleResult
                        }

                        return .writeFailed(roleResult.preferredHandler, diagnostic: diagnostic)
                    }
                }
            }
        }

        let results = contentTypes.map { contentType in
            AssociationVerificationResult(
                contentType: contentType,
                requestedBundleID: bundleID,
                roleResults: roleResultsByIdentifier[contentType.identifier] ?? []
            )
        }

        return GlobalTextSwitchReport(
            requestedBundleID: bundleID,
            matchedCount: results.filter { $0.aggregateStatus == .matched }.count,
            mismatchedCount: results.filter { $0.aggregateStatus == .mismatched }.count,
            pendingVerificationCount: results.filter { $0.aggregateStatus == .pendingVerification }.count,
            unsupportedCount: results.filter { $0.aggregateStatus == .unsupportedTarget }.count,
            writeFailedCount: results.filter { $0.aggregateStatus == .writeFailed }.count,
            processedContentTypeIdentifiers: results.map(\.contentTypeIdentifier),
            processedExtensions: declaredResolutions.map(\.normalizedExtension),
            failures: results.compactMap {
                failure(for: $0, scopeLabelsByContentType: scopeLabelsByContentType)
            }
        )
    }

    private func evaluatedRoleResults(
        for contentType: UTType,
        requestedBundleID: String
    ) -> (roleResults: [AssociationRoleVerificationResult], rolesToWrite: [PreferredHandlerRole]) {
        var roleResults: [AssociationRoleVerificationResult] = []
        var rolesToWrite: [PreferredHandlerRole] = []

        for role in PreferredHandlerRole.verificationOrder {
            let currentBundleID = associationReader.currentHandlerBundleID(for: contentType, role: role)
            let handler = PreferredHandler(
                contentType: contentType,
                requestedBundleID: requestedBundleID,
                effectiveBundleID: currentBundleID,
                role: role
            )

            if currentBundleID == requestedBundleID {
                roleResults.append(.matched(handler))
                continue
            }

            let eligibleBundleIDs = associationReader.allHandlerBundleIDs(for: contentType, role: role)
            guard !eligibleBundleIDs.isEmpty, eligibleBundleIDs.contains(requestedBundleID) else {
                roleResults.append(.unsupportedTarget(handler))
                continue
            }

            rolesToWrite.append(role)
            roleResults.append(.pendingVerification(handler))
        }

        return (roleResults, rolesToWrite)
    }

    private func declaredResolutions() -> [ContentTypeResolver.Resolution] {
        var seen = Set<String>()
        return resolutionsProvider().filter { resolution in
            guard resolution.isDeclared else {
                return false
            }

            return seen.insert(resolution.normalizedExtension).inserted
        }
    }

    private func declaredContentTypes(from resolutions: [ContentTypeResolver.Resolution]) -> [UTType] {
        var seen = Set<String>()
        return resolutions.compactMap { resolution in
            guard let type = resolution.type else {
                return nil
            }

            guard seen.insert(type.identifier).inserted else {
                return nil
            }

            return type
        }
    }

    private func scopeLabelsByContentType(
        from resolutions: [ContentTypeResolver.Resolution]
    ) -> [String: String] {
        var labels: [String: String] = [:]

        for resolution in resolutions {
            guard let type = resolution.type else {
                continue
            }

            labels[type.identifier] = labels[type.identifier] ?? ".\(resolution.normalizedExtension)"
        }

        return labels
    }

    private func failure(
        for result: AssociationVerificationResult,
        scopeLabelsByContentType: [String: String]
    ) -> GlobalTextSwitchReport.Failure? {
        guard let roleResult = result.primaryRoleResult else {
            return nil
        }

        let handler = roleResult.preferredHandler
        return GlobalTextSwitchReport.Failure(
            contentTypeIdentifier: handler.contentTypeIdentifier,
            scopeLabel: scopeLabelsByContentType[handler.contentTypeIdentifier] ?? handler.contentTypeIdentifier,
            role: handler.role,
            status: roleResult.status.rawValue,
            effectiveBundleID: handler.effectiveBundleID,
            statusCode: roleResult.statusCode,
            diagnostic: roleResult.diagnostic
        )
    }
}
