import Foundation
import UniformTypeIdentifiers

protocol GlobalTextStateServicing {
    func currentState() -> GlobalTextState
}

struct GlobalTextState: Equatable {
    enum Status: Equatable {
        case single(bundleID: String)
        case mixed(bundleIDs: [String])
        case unavailable
    }

    let status: Status
    let inspectedContentTypeIdentifiers: [String]
    let representativeBundleID: String?

    init(
        status: Status,
        inspectedContentTypeIdentifiers: [String],
        representativeBundleID: String? = nil
    ) {
        self.status = status
        self.inspectedContentTypeIdentifiers = inspectedContentTypeIdentifiers
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
    private let resolutionsProvider: (FileScope) -> [ContentTypeResolver.Resolution]

    init(
        client: LaunchServicesClienting = LaunchServicesClient(),
        resolutionsProvider: @escaping (FileScope) -> [ContentTypeResolver.Resolution] = ContentTypeResolver.resolutions(for:)
    ) {
        self.client = client
        self.resolutionsProvider = resolutionsProvider
    }

    func currentState() -> GlobalTextState {
        let contentTypes = declaredContentTypes()
        let inspectedContentTypeIdentifiers = contentTypes.map(\.identifier)
        let bundleIDs = contentTypes.compactMap { client.currentEditorBundleID(for: $0) }
        let representativeBundleID = representativeCurrentBundleID(bundleIDs: bundleIDs)

        guard !bundleIDs.isEmpty else {
            return GlobalTextState(
                status: .unavailable,
                inspectedContentTypeIdentifiers: inspectedContentTypeIdentifiers,
                representativeBundleID: nil
            )
        }

        let uniqueBundleIDs = orderedUnique(bundleIDs)
        if uniqueBundleIDs.count == 1, let bundleID = uniqueBundleIDs.first {
            return GlobalTextState(
                status: .single(bundleID: bundleID),
                inspectedContentTypeIdentifiers: inspectedContentTypeIdentifiers,
                representativeBundleID: bundleID
            )
        }

        return GlobalTextState(
            status: .mixed(bundleIDs: uniqueBundleIDs),
            inspectedContentTypeIdentifiers: inspectedContentTypeIdentifiers,
            representativeBundleID: representativeBundleID
        )
    }

    private func declaredContentTypes() -> [UTType] {
        orderedUnique(
            resolutionsProvider(.allText).compactMap { resolution in
                guard resolution.isDeclared, let type = resolution.type else {
                    return nil
                }

                return type
            },
            by: \.identifier
        )
    }

    private func orderedUnique(_ values: [String]) -> [String] {
        orderedUnique(values, by: \.self)
    }

    private func orderedUnique<Value>(_ values: [Value], by keyPath: KeyPath<Value, String>) -> [Value] {
        var seen = Set<String>()
        return values.filter { seen.insert($0[keyPath: keyPath]).inserted }
    }

    private func representativeCurrentBundleID(bundleIDs: [String]) -> String? {
        if let plainTextBundleID = client.currentEditorBundleID(for: .plainText) {
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
