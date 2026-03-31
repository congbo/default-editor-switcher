import Combine
import Foundation

struct SettingsLogEntry: Identifiable, Equatable {
    enum Level: String, Equatable {
        case info
        case warning
        case error
    }

    enum Category: String, Equatable {
        case refresh
        case switching
        case launchAtLogin
        case supportedEditors
        case globalTextTypes
        case language
    }

    let id: UUID
    let timestamp: Date
    let level: Level
    let category: Category
    let message: String
    let targetDisplayName: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = .now,
        level: Level,
        category: Category,
        message: String,
        targetDisplayName: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.targetDisplayName = targetDisplayName
    }
}

@MainActor
protocol SettingsActivityLogging: AnyObject {
    func log(
        level: SettingsLogEntry.Level,
        category: SettingsLogEntry.Category,
        message: String,
        targetDisplayName: String?
    )
}

@MainActor
final class SettingsActivityStore: ObservableObject, SettingsActivityLogging {
    private enum Layout {
        static let logLimit = 200
    }

    @Published private(set) var entries: [SettingsLogEntry] = []

    func log(
        level: SettingsLogEntry.Level,
        category: SettingsLogEntry.Category,
        message: String,
        targetDisplayName: String? = nil
    ) {
        entries.append(
            SettingsLogEntry(
                level: level,
                category: category,
                message: message,
                targetDisplayName: targetDisplayName
            )
        )

        if entries.count > Layout.logLimit {
            entries.removeFirst(entries.count - Layout.logLimit)
        }
    }
}
