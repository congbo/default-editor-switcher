import Foundation

@MainActor
final class GeneralSettingsViewModel: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var isBusy = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var status: LaunchAtLoginStatus = .disabled
    @Published private(set) var detailKind: LaunchAtLoginDetailKind = .neutral

    private let launchAtLoginService: LaunchAtLoginControlling

    init(launchAtLoginService: LaunchAtLoginControlling = LaunchAtLoginService()) {
        self.launchAtLoginService = launchAtLoginService
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

        do {
            try launchAtLoginService.setEnabled(enabled)
        } catch {
            errorMessage = error.localizedDescription
        }

        loadStatus()
        isBusy = false
    }
}
