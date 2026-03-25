import Foundation
import UniformTypeIdentifiers

struct BundleDocumentTypeDescriptor: Hashable {
    let contentTypeIdentifiers: [String]
    let role: String?
    let handlerRank: String?
}

struct BundleDocumentTypeMetadata: Hashable {
    let bundleID: String
    let displayName: String
    let documentTypes: [BundleDocumentTypeDescriptor]

    var declaredContentTypeIdentifiers: Set<String> {
        Set(documentTypes.flatMap(\.contentTypeIdentifiers))
    }

    var hasDocumentTypes: Bool {
        !documentTypes.isEmpty
    }

    func supports(contentType: UTType) -> Bool {
        declaredContentTypeIdentifiers.contains(contentType.identifier)
    }
}

struct BundleDocumentTypeReader {
    func metadata(for bundleURL: URL) -> BundleDocumentTypeMetadata {
        guard let bundle = Bundle(url: bundleURL) else {
            let fallbackIdentifier = bundleURL.deletingPathExtension().lastPathComponent
            return BundleDocumentTypeMetadata(
                bundleID: fallbackIdentifier,
                displayName: fallbackIdentifier,
                documentTypes: []
            )
        }

        let infoDictionary = bundle.infoDictionary ?? [:]
        let bundleIdentifier = bundle.bundleIdentifier ?? bundleURL.deletingPathExtension().lastPathComponent
        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? bundleIdentifier

        return metadata(
            from: infoDictionary,
            bundleIdentifier: bundleIdentifier,
            displayName: displayName
        )
    }

    func metadata(
        from infoDictionary: [String: Any],
        bundleIdentifier: String,
        displayName: String
    ) -> BundleDocumentTypeMetadata {
        let rawDocumentTypes = infoDictionary["CFBundleDocumentTypes"]
        let documentTypes = documentTypeDictionaries(from: rawDocumentTypes).map { dictionary in
            BundleDocumentTypeDescriptor(
                contentTypeIdentifiers: stringArray(from: dictionary["LSItemContentTypes"]),
                role: dictionary["CFBundleTypeRole"] as? String,
                handlerRank: dictionary["LSHandlerRank"] as? String
            )
        }

        return BundleDocumentTypeMetadata(
            bundleID: bundleIdentifier,
            displayName: displayName,
            documentTypes: documentTypes
        )
    }

    private func documentTypeDictionaries(from rawValue: Any?) -> [[String: Any]] {
        if let dictionaries = rawValue as? [[String: Any]] {
            return dictionaries
        }

        if let dictionaries = rawValue as? [NSDictionary] {
            return dictionaries.compactMap { $0 as? [String: Any] }
        }

        if let dictionaries = rawValue as? NSArray {
            return dictionaries.compactMap { $0 as? [String: Any] }
        }

        return []
    }

    private func stringArray(from rawValue: Any?) -> [String] {
        if let strings = rawValue as? [String] {
            return strings
        }

        if let strings = rawValue as? NSArray {
            return strings.compactMap { $0 as? String }
        }

        return []
    }
}
