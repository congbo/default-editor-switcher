import Combine
import Foundation

@MainActor
final class AppLanguageStore: ObservableObject {
    private enum Keys {
        static let selectedLanguage = "app.language.selected"
    }

    @Published var selectedLanguage: AppLanguage {
        didSet {
            guard selectedLanguage != oldValue else {
                return
            }

            userDefaults.set(selectedLanguage.rawValue, forKey: Keys.selectedLanguage)
            activityLogger?.log(
                level: .info,
                category: .language,
                message: "Language changed to \(label(for: selectedLanguage)).",
                targetDisplayName: label(for: selectedLanguage)
            )
        }
    }

    private let userDefaults: UserDefaults
    private let systemLocaleProvider: () -> Locale
    private weak var activityLogger: (any SettingsActivityLogging)?

    init(
        userDefaults: UserDefaults = .standard,
        systemLocaleProvider: @escaping () -> Locale = { .autoupdatingCurrent },
        activityLogger: (any SettingsActivityLogging)? = nil
    ) {
        self.userDefaults = userDefaults
        self.systemLocaleProvider = systemLocaleProvider
        self.activityLogger = activityLogger
        if let rawValue = userDefaults.string(forKey: Keys.selectedLanguage),
           let selectedLanguage = AppLanguage(rawValue: rawValue) {
            self.selectedLanguage = selectedLanguage
        } else {
            self.selectedLanguage = .system
        }
    }

    var effectiveLanguage: AppLanguage {
        switch selectedLanguage {
        case .system:
            return Self.defaultLanguage(for: systemLocaleProvider())
        case .english, .simplifiedChinese:
            return selectedLanguage
        }
    }

    var effectiveLocale: Locale {
        Locale(identifier: effectiveLanguage.localeIdentifier ?? "en")
    }

    private static func defaultLanguage(for locale: Locale) -> AppLanguage {
        locale.identifier.lowercased().hasPrefix("zh") ? .simplifiedChinese : .english
    }

    private func label(for language: AppLanguage) -> String {
        switch language {
        case .system:
            return "Follow System"
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        }
    }
}

@MainActor
protocol AppTextLocalizing: AnyObject {
    var objectWillChangePublisher: AnyPublisher<Void, Never> { get }
    func string(_ key: String) -> String
    func formattedString(_ key: String, _ arguments: CVarArg...) -> String
}

@MainActor
final class AppLocalizer: ObservableObject, AppTextLocalizing {
    private let languageStore: AppLanguageStore
    private var cancellables: Set<AnyCancellable> = []

    init(languageStore: AppLanguageStore) {
        self.languageStore = languageStore

        languageStore.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var objectWillChangePublisher: AnyPublisher<Void, Never> {
        objectWillChange
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func string(_ key: String) -> String {
        localizedBundle.localizedString(forKey: key, value: key, table: nil)
    }

    func formattedString(_ key: String, _ arguments: CVarArg...) -> String {
        String(
            format: string(key),
            locale: languageStore.effectiveLocale,
            arguments: arguments
        )
    }

    private var localizedBundle: Bundle {
        guard let localeIdentifier = languageStore.effectiveLanguage.localeIdentifier,
              let path = Bundle.main.path(forResource: localeIdentifier, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }

        return bundle
    }
}

@MainActor
final class PassthroughLocalizer: AppTextLocalizing {
    var objectWillChangePublisher: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    func string(_ key: String) -> String {
        key
    }

    func formattedString(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: key, locale: .autoupdatingCurrent, arguments: arguments)
    }
}
