import Foundation

@MainActor
final class GeneralSettingsViewModel: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var isBusy = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var status: LaunchAtLoginStatus = .disabled
    @Published private(set) var detailKind: LaunchAtLoginDetailKind = .neutral

    private let launchAtLoginService: LaunchAtLoginControlling
    private weak var activityLogger: (any SettingsActivityLogging)?

    init(
        launchAtLoginService: LaunchAtLoginControlling = LaunchAtLoginService(),
        activityLogger: (any SettingsActivityLogging)? = nil
    ) {
        self.launchAtLoginService = launchAtLoginService
        self.activityLogger = activityLogger
        loadStatus()
    }

    func loadStatus() {
        let state = launchAtLoginService.currentState()
        status = state.status
        detailKind = state.detailKind
        isEnabled = status == .enabled
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        isBusy = true
        errorMessage = nil
        let actionLabel = enabled ? "Enable" : "Disable"

        do {
            try launchAtLoginService.setEnabled(enabled)
            activityLogger?.log(
                level: .info,
                category: .launchAtLogin,
                message: enabled
                    ? "Enabled launch at login."
                    : "Disabled launch at login.",
                targetDisplayName: actionLabel
            )
        } catch {
            errorMessage = error.localizedDescription
            activityLogger?.log(
                level: .error,
                category: .launchAtLogin,
                message: "Failed to update launch at login: \(error.localizedDescription)",
                targetDisplayName: actionLabel
            )
        }

        loadStatus()
        isBusy = false
    }
}
