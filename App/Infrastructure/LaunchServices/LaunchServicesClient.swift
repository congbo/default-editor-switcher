import CoreServices
import Foundation
import UniformTypeIdentifiers

protocol LaunchServicesClienting {
    func currentEditorBundleID(for contentType: UTType) -> String?
    func allEditorBundleIDs(for contentType: UTType) -> [String]
    func setDefaultEditor(bundleID: String, for contentType: UTType) throws
}

enum LaunchServicesClientError: Error, Hashable {
    case failedToSetDefaultEditor(status: OSStatus, contentTypeIdentifier: String, bundleID: String)

    var status: OSStatus {
        switch self {
        case .failedToSetDefaultEditor(let status, _, _):
            return status
        }
    }
}

struct LaunchServicesClient: LaunchServicesClienting {
    func currentEditorBundleID(for contentType: UTType) -> String? {
        string(
            from: LSCopyDefaultRoleHandlerForContentType(
                contentType.identifier as CFString,
                .editor
            )
        )
    }

    func allEditorBundleIDs(for contentType: UTType) -> [String] {
        deduplicating(
            strings(
                from: LSCopyAllRoleHandlersForContentType(
                    contentType.identifier as CFString,
                    .editor
                )
            )
        )
    }

    func setDefaultEditor(bundleID: String, for contentType: UTType) throws {
        let status = LSSetDefaultRoleHandlerForContentType(
            contentType.identifier as CFString,
            .editor,
            bundleID as CFString
        )

        guard status == noErr else {
            throw LaunchServicesClientError.failedToSetDefaultEditor(
                status: status,
                contentTypeIdentifier: contentType.identifier,
                bundleID: bundleID
            )
        }
    }

    private func string(from unmanaged: Unmanaged<CFString>?) -> String? {
        unmanaged?.takeRetainedValue() as String?
    }

    private func strings(from unmanaged: Unmanaged<CFArray>?) -> [String] {
        guard let array = unmanaged?.takeRetainedValue() else {
            return []
        }

        return (array as NSArray).compactMap { $0 as? String }
    }

    private func deduplicating(_ bundleIDs: [String]) -> [String] {
        var seen = Set<String>()
        return bundleIDs.filter { seen.insert($0).inserted }
    }
}
