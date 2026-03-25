import XCTest
@testable import DefaultEditorSwitcher

@MainActor
final class LaunchAtLoginServiceTests: XCTestCase {
    func testSetEnabledTrueCallsRegisterPath() {
        let service = StubLaunchAtLoginService(status: .disabled)
        let viewModel = GeneralSettingsViewModel(launchAtLoginService: service)

        viewModel.setLaunchAtLoginEnabled(true)

        XCTAssertEqual(service.actions, [.enable])
    }

    func testSetEnabledFalseCallsUnregisterPath() {
        let service = StubLaunchAtLoginService(status: .enabled)
        let viewModel = GeneralSettingsViewModel(launchAtLoginService: service)

        viewModel.setLaunchAtLoginEnabled(false)

        XCTAssertEqual(service.actions, [.disable])
    }

    func testThrownRegistrationErrorIsSurfacedByViewModel() {
        let service = StubLaunchAtLoginService(
            status: .disabled,
            error: StubLaunchAtLoginError.registrationFailed
        )
        let viewModel = GeneralSettingsViewModel(launchAtLoginService: service)

        viewModel.setLaunchAtLoginEnabled(true)

        XCTAssertEqual(viewModel.errorMessage, StubLaunchAtLoginError.registrationFailed.localizedDescription)
        XCTAssertFalse(viewModel.isBusy)
    }
}

private final class StubLaunchAtLoginService: LaunchAtLoginControlling {
    enum Action: Equatable {
        case enable
        case disable
    }

    private(set) var status: LaunchAtLoginStatus
    private let error: Error?
    private(set) var actions: [Action] = []

    init(status: LaunchAtLoginStatus, error: Error? = nil) {
        self.status = status
        self.error = error
    }

    func currentStatus() -> LaunchAtLoginStatus {
        status
    }

    func setEnabled(_ enabled: Bool) throws {
        actions.append(enabled ? .enable : .disable)
        if let error {
            throw error
        }
        status = enabled ? .enabled : .disabled
    }
}

private enum StubLaunchAtLoginError: LocalizedError {
    case registrationFailed

    var errorDescription: String? {
        "Launch at login status could not be updated."
    }
}
