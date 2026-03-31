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

protocol GlobalTextSwitchCoordinating {
    func apply(bundleID: String) -> GlobalTextSwitchReport
}

struct GlobalTextSwitchCoordinator: GlobalTextSwitchCoordinating {
    private let verifier: LaunchServicesAssociationVerifying
    private let resolutionsProvider: () -> [ContentTypeResolver.Resolution]
    private let verificationRoles: [PreferredHandlerRole]

    init(
        verifier: LaunchServicesAssociationVerifying = LaunchServicesAssociationVerifier(),
        resolutionsProvider: (() -> [ContentTypeResolver.Resolution])? = nil,
        enabledExtensionsProvider: @escaping () -> Set<String> = {
            ContentTypeResolver.defaultEnabledGlobalTextExtensions
        },
        verificationRoles: [PreferredHandlerRole] = [.editor]
    ) {
        self.verifier = verifier
        self.resolutionsProvider = resolutionsProvider ?? {
            ContentTypeResolver.resolutions(forExtensions: enabledExtensionsProvider())
        }
        self.verificationRoles = verificationRoles
    }

    func apply(bundleID: String) -> GlobalTextSwitchReport {
        let declaredResolutions = declaredResolutions()
        let scopeLabelsByContentType = scopeLabelsByContentType(from: declaredResolutions)
        let results = declaredContentTypes(from: declaredResolutions).map { contentType in
            verifier.verify(
                requestedBundleID: bundleID,
                for: contentType,
                roles: verificationRoles
            )
        }

        return GlobalTextSwitchReport(
            requestedBundleID: bundleID,
            matchedCount: results.filter { $0.aggregateStatus == .matched }.count,
            mismatchedCount: results.filter { $0.aggregateStatus == .mismatched }.count,
            unsupportedCount: results.filter { $0.aggregateStatus == .unsupportedTarget }.count,
            writeFailedCount: results.filter { $0.aggregateStatus == .writeFailed }.count,
            processedContentTypeIdentifiers: results.map(\.contentTypeIdentifier),
            processedExtensions: declaredResolutions.map(\.normalizedExtension),
            failures: results.compactMap {
                failure(for: $0, scopeLabelsByContentType: scopeLabelsByContentType)
            }
        )
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
            statusCode: roleResult.statusCode
        )
    }
}
