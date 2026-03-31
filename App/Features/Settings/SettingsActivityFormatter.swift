import Foundation
import SwiftUI

@MainActor
struct SettingsActivityFormatter {
    let localizer: any AppTextLocalizing

    func refreshDescription() -> String {
        localizer.string("Refresh the current default editor, installed editor list, and derived status shown in settings.")
    }

    func refreshStatusDetail(
        refreshStatus: SettingsRefreshStatus,
        isBlockedBySwitch: Bool
    ) -> String {
        if isBlockedBySwitch {
            return localizer.string("Wait for the current editor switch to finish before refreshing.")
        }

        if refreshStatus.phase == .refreshing {
            return localizer.string("Refreshing current editor state and installed editors.")
        }

        if let errorMessage = refreshStatus.lastErrorMessage {
            return localizer.string("Last refresh failed: ") + errorMessage
        }

        if let lastAttemptAt = refreshStatus.lastAttemptAt {
            return localizer.string("Last refreshed at ") + lastAttemptAt.formatted(date: .omitted, time: .standard) + "."
        }

        return localizer.string("Refresh current editor state and installed editors.")
    }

    func activityEmptyStateText() -> String {
        localizer.string("No settings activity yet.")
    }

    func logLevelTitle(for level: SettingsLogEntry.Level) -> String {
        switch level {
        case .info:
            return localizer.string("Info")
        case .warning:
            return localizer.string("Warning")
        case .error:
            return localizer.string("Error")
        }
    }

    func logCategoryTitle(for category: SettingsLogEntry.Category) -> String {
        switch category {
        case .refresh:
            return localizer.string("Refresh")
        case .switching:
            return localizer.string("Switch")
        case .launchAtLogin:
            return localizer.string("Launch at login")
        case .supportedEditors:
            return localizer.string("Supported Editors")
        case .globalTextTypes:
            return localizer.string("Global Text Types")
        case .language:
            return localizer.string("Language")
        }
    }

    func logLevelColor(for level: SettingsLogEntry.Level) -> Color {
        switch level {
        case .info:
            return .secondary
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}
