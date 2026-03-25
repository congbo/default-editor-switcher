import Foundation
import UniformTypeIdentifiers

enum PreferredHandlerRole: String, Hashable {
    case editor
}

struct PreferredHandler: Hashable {
    let contentTypeIdentifier: String
    let role: PreferredHandlerRole
    let requestedBundleID: String
    let effectiveBundleID: String?

    init(
        contentTypeIdentifier: String,
        requestedBundleID: String,
        effectiveBundleID: String?,
        role: PreferredHandlerRole = .editor
    ) {
        self.contentTypeIdentifier = contentTypeIdentifier
        self.role = role
        self.requestedBundleID = requestedBundleID
        self.effectiveBundleID = effectiveBundleID
    }

    init(
        contentType: UTType,
        requestedBundleID: String,
        effectiveBundleID: String?,
        role: PreferredHandlerRole = .editor
    ) {
        self.init(
            contentTypeIdentifier: contentType.identifier,
            requestedBundleID: requestedBundleID,
            effectiveBundleID: effectiveBundleID,
            role: role
        )
    }
}
