import Combine
import Foundation
import UniformTypeIdentifiers

struct GlobalTextTypesConfiguration: Equatable {
    let availableExtensions: [String]
    let customExtensions: [String]
    let enabledExtensions: Set<String>

    func isEnabled(extension normalizedExtension: String) -> Bool {
        enabledExtensions.contains(normalizedExtension)
    }
}

enum GlobalTextTypeSource: Equatable {
    case builtIn
    case custom
}

enum GlobalTextTypeResolutionStatus: Equatable {
    case declaredTextLike
    case declaredNonText
    case unresolved
}

struct GlobalTextTypeItem: Identifiable, Equatable {
    let normalizedExtension: String
    let contentTypeIdentifier: String?
    let source: GlobalTextTypeSource
    let resolutionStatus: GlobalTextTypeResolutionStatus
    let isDefaultEnabled: Bool
    let isEnabled: Bool

    var id: String {
        normalizedExtension
    }
}

enum AddCustomGlobalTextTypeResult: Equatable {
    case added(String)
    case emptyInput
    case duplicateBuiltIn(String)
    case duplicateCustom(String)
}

@MainActor
protocol GlobalTextTypesStoring: AnyObject {
    var objectWillChangePublisher: AnyPublisher<Void, Never> { get }
    func enabledExtensions() -> Set<String>
}

@MainActor
final class GlobalTextTypesStore: ObservableObject, GlobalTextTypesStoring {
    private enum Keys {
        static let enabledExtensions = "globalTextTypes.enabledExtensions"
        static let customExtensions = "globalTextTypes.customExtensions"
    }

    @Published private var configuration: GlobalTextTypesConfiguration

    private let userDefaults: UserDefaults
    private let didChangeSubject = PassthroughSubject<Void, Never>()
    private weak var activityLogger: (any SettingsActivityLogging)?

    init(
        userDefaults: UserDefaults = .standard,
        activityLogger: (any SettingsActivityLogging)? = nil
    ) {
        self.userDefaults = userDefaults
        self.activityLogger = activityLogger
        self.configuration = Self.loadConfiguration(from: userDefaults)
    }

    var objectWillChangePublisher: AnyPublisher<Void, Never> {
        didChangeSubject.eraseToAnyPublisher()
    }

    func loadConfiguration() -> GlobalTextTypesConfiguration {
        configuration
    }

    func enabledExtensions() -> Set<String> {
        configuration.enabledExtensions
    }

    func items() -> [GlobalTextTypeItem] {
        configuration.availableExtensions.map { normalizedExtension in
            let resolution = ContentTypeResolver.resolve(for: normalizedExtension)
            return GlobalTextTypeItem(
                normalizedExtension: normalizedExtension,
                contentTypeIdentifier: resolution.type?.identifier,
                source: configuration.customExtensions.contains(normalizedExtension) ? .custom : .builtIn,
                resolutionStatus: resolutionStatus(for: resolution),
                isDefaultEnabled: ContentTypeResolver.defaultEnabledGlobalTextExtensions.contains(normalizedExtension),
                isEnabled: configuration.isEnabled(extension: normalizedExtension)
            )
        }
    }

    func addCustomExtension(_ rawExtension: String) -> AddCustomGlobalTextTypeResult {
        let normalizedExtension = ContentTypeResolver.normalizeExtension(rawExtension)
        guard !normalizedExtension.isEmpty else {
            return .emptyInput
        }

        guard !ContentTypeResolver.builtInGlobalTextExtensions.contains(normalizedExtension) else {
            return .duplicateBuiltIn(normalizedExtension)
        }

        guard !configuration.customExtensions.contains(normalizedExtension) else {
            return .duplicateCustom(normalizedExtension)
        }

        let customExtensions = (configuration.customExtensions + [normalizedExtension]).sorted()
        let enabledExtensions = configuration.enabledExtensions.union([normalizedExtension])
        persist(customExtensions: customExtensions, enabledExtensions: enabledExtensions)

        activityLogger?.log(
            level: .info,
            category: .globalTextTypes,
            message: "Added custom global type .\(normalizedExtension).",
            targetDisplayName: ".\(normalizedExtension)"
        )

        return .added(normalizedExtension)
    }

    func removeCustomExtension(_ rawExtension: String) {
        let normalizedExtension = ContentTypeResolver.normalizeExtension(rawExtension)
        guard configuration.customExtensions.contains(normalizedExtension) else {
            return
        }

        let customExtensions = configuration.customExtensions.filter { $0 != normalizedExtension }
        let enabledExtensions = configuration.enabledExtensions.subtracting([normalizedExtension])
        persist(customExtensions: customExtensions, enabledExtensions: enabledExtensions)

        activityLogger?.log(
            level: .info,
            category: .globalTextTypes,
            message: "Removed custom global type .\(normalizedExtension).",
            targetDisplayName: ".\(normalizedExtension)"
        )
    }

    func setEnabled(extension rawExtension: String, isEnabled: Bool) {
        let normalizedExtension = ContentTypeResolver.normalizeExtension(rawExtension)
        guard configuration.availableExtensions.contains(normalizedExtension) else {
            return
        }

        var enabledExtensions = configuration.enabledExtensions
        if isEnabled {
            enabledExtensions.insert(normalizedExtension)
        } else {
            enabledExtensions.remove(normalizedExtension)
        }

        let didPersist = persist(
            customExtensions: configuration.customExtensions,
            enabledExtensions: enabledExtensions
        )
        guard didPersist else {
            return
        }

        activityLogger?.log(
            level: .info,
            category: .globalTextTypes,
            message: isEnabled
                ? "Included .\(normalizedExtension) in the global text switch."
                : "Excluded .\(normalizedExtension) from the global text switch.",
            targetDisplayName: ".\(normalizedExtension)"
        )
    }

    private func resolutionStatus(
        for resolution: ContentTypeResolver.Resolution
    ) -> GlobalTextTypeResolutionStatus {
        guard resolution.isDeclared else {
            return .unresolved
        }

        if resolution.conformsToText || resolution.conformsToSourceCode {
            return .declaredTextLike
        }

        return .declaredNonText
    }

    @discardableResult
    private func persist(
        customExtensions: [String],
        enabledExtensions: Set<String>
    ) -> Bool {
        let normalizedCustomExtensions = Self.normalizedCustomExtensions(from: customExtensions)
        let availableExtensions = Self.mergedAvailableExtensions(customExtensions: normalizedCustomExtensions)
        let normalizedEnabledExtensions = Set(
            availableExtensions.filter { enabledExtensions.contains($0) }
        )
        let nextConfiguration = GlobalTextTypesConfiguration(
            availableExtensions: availableExtensions,
            customExtensions: normalizedCustomExtensions,
            enabledExtensions: normalizedEnabledExtensions
        )

        guard configuration != nextConfiguration else {
            return false
        }

        configuration = nextConfiguration
        userDefaults.set(configuration.customExtensions, forKey: Keys.customExtensions)
        userDefaults.set(
            configuration.availableExtensions.filter { normalizedEnabledExtensions.contains($0) },
            forKey: Keys.enabledExtensions
        )
        didChangeSubject.send(())
        return true
    }

    private static func loadConfiguration(from userDefaults: UserDefaults) -> GlobalTextTypesConfiguration {
        let customExtensions = normalizedCustomExtensions(
            from: userDefaults.stringArray(forKey: Keys.customExtensions) ?? []
        )
        let availableExtensions = mergedAvailableExtensions(customExtensions: customExtensions)
        let storedEnabledExtensions = Set(
            (userDefaults.stringArray(forKey: Keys.enabledExtensions) ?? [])
                .map(ContentTypeResolver.normalizeExtension)
        )
        let enabledExtensions: Set<String>
        if userDefaults.object(forKey: Keys.enabledExtensions) == nil {
            enabledExtensions = Set(
                availableExtensions.filter {
                    ContentTypeResolver.defaultEnabledGlobalTextExtensions.contains($0)
                    || customExtensions.contains($0)
                }
            )
        } else {
            let normalizedStoredEnabledExtensions = Set(
                availableExtensions.filter { storedEnabledExtensions.contains($0) }
            )
            enabledExtensions = normalizedStoredEnabledExtensions
        }

        return GlobalTextTypesConfiguration(
            availableExtensions: availableExtensions,
            customExtensions: customExtensions,
            enabledExtensions: enabledExtensions
        )
    }

    private static func normalizedCustomExtensions(from rawExtensions: [String]) -> [String] {
        Array(
            Set(
                rawExtensions
                    .map(ContentTypeResolver.normalizeExtension)
                    .filter { !$0.isEmpty && !ContentTypeResolver.builtInGlobalTextExtensions.contains($0) }
            )
        )
        .sorted()
    }

    private static func mergedAvailableExtensions(customExtensions: [String]) -> [String] {
        Array(ContentTypeResolver.builtInGlobalTextExtensions.union(customExtensions)).sorted()
    }
}

@MainActor
final class TransientGlobalTextTypesStore: GlobalTextTypesStoring {
    var objectWillChangePublisher: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    func enabledExtensions() -> Set<String> {
        ContentTypeResolver.defaultEnabledGlobalTextExtensions
    }
}
