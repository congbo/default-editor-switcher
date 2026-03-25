import Foundation

@MainActor
final class GeneralSettingsViewModel: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var isBusy = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var status: LaunchAtLoginStatus = .disabled

    private let launchAtLoginService: LaunchAtLoginControlling

    init(launchAtLoginService: LaunchAtLoginControlling = LaunchAtLoginService()) {
        self.launchAtLoginService = launchAtLoginService
        loadStatus()
    }

    func loadStatus() {
        status = launchAtLoginService.currentStatus()
        isEnabled = status == .enabled
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        isBusy = true
        errorMessage = nil

        do {
            try launchAtLoginService.setEnabled(enabled)
        } catch {
            errorMessage = error.localizedDescription
        }

        loadStatus()
        isBusy = false
    }
}
