import Combine
import Foundation
import UniformTypeIdentifiers

struct GlobalTextTypesConfiguration: Equatable {
    let availableExtensions: [String]
    let enabledExtensions: Set<String>

    func isEnabled(extension normalizedExtension: String) -> Bool {
        enabledExtensions.contains(normalizedExtension)
    }
}

struct GlobalTextTypeItem: Identifiable, Equatable {
    let normalizedExtension: String
    let contentTypeIdentifier: String?
    let isDefaultEnabled: Bool
    let isEnabled: Bool

    var id: String {
        normalizedExtension
    }
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
                isDefaultEnabled: ContentTypeResolver.defaultEnabledGlobalTextExtensions.contains(normalizedExtension),
                isEnabled: configuration.isEnabled(extension: normalizedExtension)
            )
        }
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

        let didPersist = persist(enabledExtensions: enabledExtensions)
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

    private func persist(enabledExtensions: Set<String>) -> Bool {
        let normalizedEnabledExtensions = Set(
            configuration.availableExtensions.filter { enabledExtensions.contains($0) }
        )
        guard configuration.enabledExtensions != normalizedEnabledExtensions else {
            return false
        }

        configuration = GlobalTextTypesConfiguration(
            availableExtensions: configuration.availableExtensions,
            enabledExtensions: normalizedEnabledExtensions
        )
        userDefaults.set(configuration.availableExtensions.filter { normalizedEnabledExtensions.contains($0) }, forKey: Keys.enabledExtensions)
        didChangeSubject.send(())
        return true
    }

    private static func loadConfiguration(from userDefaults: UserDefaults) -> GlobalTextTypesConfiguration {
        let availableExtensions = ContentTypeResolver.builtInGlobalTextExtensions.sorted()
        let storedEnabledExtensions = Set(
            (userDefaults.stringArray(forKey: Keys.enabledExtensions) ?? [])
                .map(ContentTypeResolver.normalizeExtension)
        )
        let enabledExtensions: Set<String>
        if storedEnabledExtensions.isEmpty {
            enabledExtensions = Set(availableExtensions.filter { ContentTypeResolver.defaultEnabledGlobalTextExtensions.contains($0) })
        } else {
            let normalizedStoredEnabledExtensions = Set(
                availableExtensions.filter { storedEnabledExtensions.contains($0) }
            )
            enabledExtensions = normalizedStoredEnabledExtensions.isEmpty
                ? Set(availableExtensions.filter { ContentTypeResolver.defaultEnabledGlobalTextExtensions.contains($0) })
                : normalizedStoredEnabledExtensions
        }

        return GlobalTextTypesConfiguration(
            availableExtensions: availableExtensions,
            enabledExtensions: enabledExtensions
        )
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
