import Foundation
import UniformTypeIdentifiers

protocol LaunchServicesAssociationVerifying {
    func verify(requestedBundleID: String, for contentType: UTType) -> AssociationVerificationResult
}

extension LaunchServicesAssociationVerifier: LaunchServicesAssociationVerifying {}

protocol GlobalTextSwitchCoordinating {
    func apply(bundleID: String) -> GlobalTextSwitchReport
}

struct GlobalTextSwitchCoordinator: GlobalTextSwitchCoordinating {
    private let verifier: LaunchServicesAssociationVerifying
    private let resolutionsProvider: (FileScope) -> [ContentTypeResolver.Resolution]

    init(
        verifier: LaunchServicesAssociationVerifying = LaunchServicesAssociationVerifier(),
        resolutionsProvider: @escaping (FileScope) -> [ContentTypeResolver.Resolution] = ContentTypeResolver.resolutions(for:)
    ) {
        self.verifier = verifier
        self.resolutionsProvider = resolutionsProvider
    }

    func apply(bundleID: String) -> GlobalTextSwitchReport {
        let declaredResolutions = declaredResolutions()
        let results = declaredContentTypes(from: declaredResolutions).map { contentType in
            verifier.verify(requestedBundleID: bundleID, for: contentType)
        }

        return GlobalTextSwitchReport(
            requestedBundleID: bundleID,
            matchedCount: results.filter { $0.status == "matched" }.count,
            mismatchedCount: results.filter { $0.status == "mismatched" }.count,
            unsupportedCount: results.filter { $0.status == "unsupportedTarget" }.count,
            writeFailedCount: results.filter { $0.status == "writeFailed" }.count,
            processedContentTypeIdentifiers: results.map { $0.preferredHandler.contentTypeIdentifier },
            processedExtensions: declaredResolutions.map(\.normalizedExtension),
            sampleFailures: results.compactMap(sampleFailure(for:)).prefix(3).map { $0 }
        )
    }

    private func declaredResolutions() -> [ContentTypeResolver.Resolution] {
        var seen = Set<String>()
        return resolutionsProvider(.allText).filter { resolution in
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

    private func sampleFailure(for result: AssociationVerificationResult) -> GlobalTextSwitchReport.SampleFailure? {
        switch result {
        case .matched:
            return nil
        case .mismatched(let handler):
            return GlobalTextSwitchReport.SampleFailure(
                contentTypeIdentifier: handler.contentTypeIdentifier,
                status: result.status,
                effectiveBundleID: handler.effectiveBundleID,
                statusCode: nil
            )
        case .unsupportedTarget(let handler):
            return GlobalTextSwitchReport.SampleFailure(
                contentTypeIdentifier: handler.contentTypeIdentifier,
                status: result.status,
                effectiveBundleID: handler.effectiveBundleID,
                statusCode: nil
            )
        case .writeFailed(let handler, let status):
            return GlobalTextSwitchReport.SampleFailure(
                contentTypeIdentifier: handler.contentTypeIdentifier,
                status: result.status,
                effectiveBundleID: handler.effectiveBundleID,
                statusCode: status
            )
        }
    }
}
