import Foundation

enum AppLanguage: String, CaseIterable, Codable {
    case system
    case english
    case simplifiedChinese

    var localeIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .english:
            return "en"
        case .simplifiedChinese:
            return "zh-Hans"
        }
    }
}
