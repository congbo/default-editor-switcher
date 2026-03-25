import Foundation

enum FileScope: Hashable {
    case allText
    case language(LanguageBucket)
    case customExtensions(Set<String>)
}
