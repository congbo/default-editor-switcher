import CoreServices
import Foundation
import UniformTypeIdentifiers

struct LaunchServicesAssociationVerifier {
    private let client: LaunchServicesClienting

    init(client: LaunchServicesClienting = LaunchServicesClient()) {
        self.client = client
    }

    func verify(requestedBundleID: String, for contentType: UTType) -> AssociationVerificationResult {
        let existingEffectiveBundleID = client.currentEditorBundleID(for: contentType)
        let handler = PreferredHandler(
            contentType: contentType,
            requestedBundleID: requestedBundleID,
            effectiveBundleID: existingEffectiveBundleID
        )

        let eligibleBundleIDs = client.allEditorBundleIDs(for: contentType)
        guard !eligibleBundleIDs.isEmpty, eligibleBundleIDs.contains(requestedBundleID) else {
            return .unsupportedTarget(handler)
        }

        do {
            try client.setDefaultEditor(bundleID: requestedBundleID, for: contentType)
        } catch let error as LaunchServicesClientError {
            let verifiedHandler = PreferredHandler(
                contentType: contentType,
                requestedBundleID: requestedBundleID,
                effectiveBundleID: client.currentEditorBundleID(for: contentType)
            )

            return .writeFailed(verifiedHandler, status: error.status)
        } catch {
            let verifiedHandler = PreferredHandler(
                contentType: contentType,
                requestedBundleID: requestedBundleID,
                effectiveBundleID: client.currentEditorBundleID(for: contentType)
            )

            return .writeFailed(verifiedHandler, status: OSStatus(-1))
        }

        let effectiveBundleID = client.currentEditorBundleID(for: contentType)
        let verifiedHandler = PreferredHandler(
            contentType: contentType,
            requestedBundleID: requestedBundleID,
            effectiveBundleID: effectiveBundleID
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
