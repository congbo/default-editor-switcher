import XCTest
@testable import DefaultEditorSwitcher

@MainActor
final class SettingsActivityFormatterTests: XCTestCase {
    func testRefreshStatusUsesLoadingCopyWhenRefreshing() {
        let formatter = SettingsActivityFormatter(localizer: PassthroughLocalizer())

        let detail = formatter.refreshStatusDetail(
            refreshStatus: SettingsRefreshStatus(phase: .refreshing),
            isBlockedBySwitch: false
        )

        XCTAssertEqual(detail, "Refreshing current editor state and installed editors.")
    }

    func testRefreshStatusUsesFailureCopyWhenRefreshFails() {
        let formatter = SettingsActivityFormatter(localizer: PassthroughLocalizer())

        let detail = formatter.refreshStatusDetail(
            refreshStatus: SettingsRefreshStatus(
                phase: .idle,
                lastAttemptAt: Date(timeIntervalSince1970: 1_710_000_000),
                lastErrorMessage: "Editor discovery failed."
            ),
            isBlockedBySwitch: false
        )

        XCTAssertEqual(detail, "Last refresh failed: Editor discovery failed.")
    }

    func testActivityEmptyStateCopyIsStable() {
        let formatter = SettingsActivityFormatter(localizer: PassthroughLocalizer())

        XCTAssertEqual(formatter.activityEmptyStateText(), "No settings activity yet.")
        XCTAssertEqual(formatter.logLevelTitle(for: .warning), "Warning")
        XCTAssertEqual(formatter.logCategoryTitle(for: .globalTextTypes), "Global Text Types")
    }
}
