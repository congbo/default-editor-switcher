import Foundation
import UniformTypeIdentifiers

protocol GlobalTextStateServicing {
    func currentState() -> GlobalTextState
}

struct GlobalTextState: Equatable {
    struct ExtensionAssociation: Equatable {
        let normalizedExtension: String
        let contentTypeIdentifier: String
        let bundleID: String?
    }

    enum Status: Equatable {
        case single(bundleID: String)
        case mixed(bundleIDs: [String])
        case unavailable
    }

    let status: Status
    let inspectedContentTypeIdentifiers: [String]
    let extensionAssociations: [ExtensionAssociation]
    let representativeBundleID: String?

    init(
        status: Status,
        inspectedContentTypeIdentifiers: [String],
        extensionAssociations: [ExtensionAssociation] = [],
        representativeBundleID: String? = nil
    ) {
        self.status = status
        self.inspectedContentTypeIdentifiers = inspectedContentTypeIdentifiers
        self.extensionAssociations = extensionAssociations
        self.representativeBundleID = representativeBundleID
    }

    var currentBundleID: String? {
        switch status {
        case .single(let bundleID):
            representativeBundleID ?? bundleID
        case .mixed:
            representativeBundleID
        case .unavailable:
            nil
        }
    }
}

struct GlobalTextStateService: GlobalTextStateServicing {
    private let client: LaunchServicesClienting
    private let resolutionsProvider: () -> [ContentTypeResolver.Resolution]

    init(
        client: LaunchServicesClienting = LaunchServicesClient(),
        resolutionsProvider: (() -> [ContentTypeResolver.Resolution])? = nil,
        enabledExtensionsProvider: @escaping () -> Set<String> = {
            ContentTypeResolver.defaultEnabledGlobalTextExtensions
        }
    ) {
        self.client = client
        self.resolutionsProvider = resolutionsProvider ?? {
            ContentTypeResolver.resolutions(forExtensions: enabledExtensionsProvider())
        }
    }

    func currentState() -> GlobalTextState {
        let associations = declaredExtensionAssociations()
        let inspectedContentTypeIdentifiers = orderedUnique(associations.map(\.contentTypeIdentifier))
        let bundleIDs = associations.compactMap(\.bundleID)
        let representativeBundleID = representativeCurrentBundleID(bundleIDs: bundleIDs)

        guard !bundleIDs.isEmpty else {
            return GlobalTextState(
                status: .unavailable,
                inspectedContentTypeIdentifiers: inspectedContentTypeIdentifiers,
                extensionAssociations: associations,
                representativeBundleID: nil
            )
        }

        let uniqueBundleIDs = orderedUnique(bundleIDs)
        if uniqueBundleIDs.count == 1, let bundleID = uniqueBundleIDs.first {
            return GlobalTextState(
                status: .single(bundleID: bundleID),
                inspectedContentTypeIdentifiers: inspectedContentTypeIdentifiers,
                extensionAssociations: associations,
                representativeBundleID: bundleID
            )
        }

        return GlobalTextState(
            status: .mixed(bundleIDs: uniqueBundleIDs),
            inspectedContentTypeIdentifiers: inspectedContentTypeIdentifiers,
            extensionAssociations: associations,
            representativeBundleID: representativeBundleID
        )
    }

    private func declaredExtensionAssociations() -> [GlobalTextState.ExtensionAssociation] {
        resolutionsProvider().compactMap { resolution in
            guard resolution.isDeclared, let type = resolution.type else {
                return nil
            }

            return GlobalTextState.ExtensionAssociation(
                normalizedExtension: resolution.normalizedExtension,
                contentTypeIdentifier: type.identifier,
                bundleID: client.currentHandlerBundleID(for: type, role: .editor)
            )
        }
    }

    private func orderedUnique(_ values: [String]) -> [String] {
        orderedUnique(values, by: \.self)
    }

    private func orderedUnique<Value>(_ values: [Value], by keyPath: KeyPath<Value, String>) -> [Value] {
        var seen = Set<String>()
        return values.filter { seen.insert($0[keyPath: keyPath]).inserted }
    }

    private func representativeCurrentBundleID(bundleIDs: [String]) -> String? {
        if let plainTextBundleID = client.currentHandlerBundleID(for: .plainText, role: .editor) {
            return plainTextBundleID
        }

        var counts: [String: Int] = [:]
        for bundleID in bundleIDs {
            counts[bundleID, default: 0] += 1
        }

        return counts.max { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key > rhs.key
            }

            return lhs.value < rhs.value
        }?.key
    }
}
