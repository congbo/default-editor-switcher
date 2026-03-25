import CoreServices
import Foundation
import UniformTypeIdentifiers

protocol LaunchServicesClienting {
    func currentHandlerBundleID(for contentType: UTType, role: PreferredHandlerRole) -> String?
    func allHandlerBundleIDs(for contentType: UTType, role: PreferredHandlerRole) -> [String]
    func setDefaultHandler(bundleID: String, for contentType: UTType, role: PreferredHandlerRole) throws
}

enum LaunchServicesClientError: Error, Hashable {
    case failedToSetDefaultHandler(
        status: OSStatus,
        contentTypeIdentifier: String,
        bundleID: String,
        role: PreferredHandlerRole
    )

    var status: OSStatus {
        switch self {
        case .failedToSetDefaultHandler(let status, _, _, _):
            return status
        }
    }
}

struct LaunchServicesClient: LaunchServicesClienting {
    func currentHandlerBundleID(for contentType: UTType, role: PreferredHandlerRole) -> String? {
        string(
            from: LSCopyDefaultRoleHandlerForContentType(
                contentType.identifier as CFString,
                role.lsRolesMask
            )
        )
    }

    func allHandlerBundleIDs(for contentType: UTType, role: PreferredHandlerRole) -> [String] {
        deduplicating(
            strings(
                from: LSCopyAllRoleHandlersForContentType(
                    contentType.identifier as CFString,
                    role.lsRolesMask
                )
            )
        )
    }

    func setDefaultHandler(bundleID: String, for contentType: UTType, role: PreferredHandlerRole) throws {
        let status = LSSetDefaultRoleHandlerForContentType(
            contentType.identifier as CFString,
            role.lsRolesMask,
            bundleID as CFString
        )

        guard status == noErr else {
            throw LaunchServicesClientError.failedToSetDefaultHandler(
                status: status,
                contentTypeIdentifier: contentType.identifier,
                bundleID: bundleID,
                role: role
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

private extension PreferredHandlerRole {
    var lsRolesMask: LSRolesMask {
        switch self {
        case .all:
            return .all
        case .viewer:
            return .viewer
        case .editor:
            return .editor
        }
    }
}
