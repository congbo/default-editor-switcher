import CoreServices
import Foundation
import UniformTypeIdentifiers

struct LaunchServicesAssociationVerifier {
    private let client: LaunchServicesClienting

    init(client: LaunchServicesClienting = LaunchServicesClient()) {
        self.client = client
    }

    func verify(requestedBundleID: String, for contentType: UTType) -> AssociationVerificationResult {
        let roleResults = PreferredHandlerRole.verificationOrder.map { role in
            verify(requestedBundleID: requestedBundleID, for: contentType, role: role)
        }

        return AssociationVerificationResult(
            contentType: contentType,
            requestedBundleID: requestedBundleID,
            roleResults: roleResults
        )
    }

    private func verify(
        requestedBundleID: String,
        for contentType: UTType,
        role: PreferredHandlerRole
    ) -> AssociationRoleVerificationResult {
        let existingEffectiveBundleID = client.currentHandlerBundleID(for: contentType, role: role)
        let handler = PreferredHandler(
            contentType: contentType,
            requestedBundleID: requestedBundleID,
            effectiveBundleID: existingEffectiveBundleID,
            role: role
        )

        let eligibleBundleIDs = client.allHandlerBundleIDs(for: contentType, role: role)
        guard !eligibleBundleIDs.isEmpty, eligibleBundleIDs.contains(requestedBundleID) else {
            return .unsupportedTarget(handler)
        }

        do {
            try client.setDefaultHandler(bundleID: requestedBundleID, for: contentType, role: role)
        } catch let error as LaunchServicesClientError {
            let verifiedHandler = PreferredHandler(
                contentType: contentType,
                requestedBundleID: requestedBundleID,
                effectiveBundleID: client.currentHandlerBundleID(for: contentType, role: role),
                role: role
            )

            return .writeFailed(verifiedHandler, status: error.status)
        } catch {
            let verifiedHandler = PreferredHandler(
                contentType: contentType,
                requestedBundleID: requestedBundleID,
                effectiveBundleID: client.currentHandlerBundleID(for: contentType, role: role),
                role: role
            )

            return .writeFailed(verifiedHandler, status: OSStatus(-1))
        }

        let effectiveBundleID = client.currentHandlerBundleID(for: contentType, role: role)
        let verifiedHandler = PreferredHandler(
            contentType: contentType,
            requestedBundleID: requestedBundleID,
            effectiveBundleID: effectiveBundleID,
            role: role
        )

        guard let effectiveBundleID else {
            return .unsupportedTarget(verifiedHandler)
        }

        if effectiveBundleID == requestedBundleID {
            return .matched(verifiedHandler)
        }

        return .mismatched(verifiedHandler)
    }
}
