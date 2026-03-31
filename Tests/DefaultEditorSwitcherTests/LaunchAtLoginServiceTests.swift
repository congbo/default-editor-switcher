import XCTest
@testable import DefaultEditorSwitcher

@MainActor
final class LaunchAtLoginServiceTests: XCTestCase {
    func testControllerStatusMappingTreatsNotFoundAsDisabledWithNeutralCopy() {
        XCTAssertEqual(
            LaunchAtLoginService.state(for: .notFound),
            LaunchAtLoginState(status: .disabled, detailKind: .neutral)
        )
    }

    func testControllerStatusMappingTreatsUnknownAsDisabledWithNeutralCopy() {
        XCTAssertEqual(
            LaunchAtLoginService.state(for: .unknown),
            LaunchAtLoginState(status: .disabled, detailKind: .neutral)
        )
    }

    func testSetEnabledTrueCallsRegisterPath() {
        let service = StubLaunchAtLoginService(state: LaunchAtLoginState(status: .disabled, detailKind: .disabled))
        let viewModel = GeneralSettingsViewModel(launchAtLoginService: service)

        viewModel.setLaunchAtLoginEnabled(true)

        XCTAssertEqual(service.actions, [.enable])
    }

    func testSetEnabledFalseCallsUnregisterPath() {
        let service = StubLaunchAtLoginService(state: LaunchAtLoginState(status: .enabled, detailKind: .enabled))
        let viewModel = GeneralSettingsViewModel(launchAtLoginService: service)

        viewModel.setLaunchAtLoginEnabled(false)

        XCTAssertEqual(service.actions, [.disable])
    }

    func testThrownRegistrationErrorIsSurfacedByViewModel() {
        let service = StubLaunchAtLoginService(
            state: LaunchAtLoginState(status: .disabled, detailKind: .neutral),
            error: StubLaunchAtLoginError.registrationFailed
        )
        let viewModel = GeneralSettingsViewModel(launchAtLoginService: service)

        viewModel.setLaunchAtLoginEnabled(true)

        XCTAssertEqual(viewModel.errorMessage, StubLaunchAtLoginError.registrationFailed.localizedDescription)
        XCTAssertFalse(viewModel.isBusy)
    }

    func testLoadStatusPublishesNeutralDetailForImplicitlyDisabledState() {
        let service = StubLaunchAtLoginService(state: LaunchAtLoginState(status: .disabled, detailKind: .neutral))
        let viewModel = GeneralSettingsViewModel(launchAtLoginService: service)

        XCTAssertFalse(viewModel.isEnabled)
        XCTAssertEqual(viewModel.status, .disabled)
        XCTAssertEqual(viewModel.detailKind, .neutral)
    }
}

private final class StubLaunchAtLoginService: LaunchAtLoginControlling {
    enum Action: Equatable {
        case enable
        case disable
    }

    private(set) var state: LaunchAtLoginState
    private let error: Error?
    private(set) var actions: [Action] = []

    init(state: LaunchAtLoginState, error: Error? = nil) {
        self.state = state
        self.error = error
    }

    func currentState() -> LaunchAtLoginState {
        state
    }

    func setEnabled(_ enabled: Bool) throws {
        actions.append(enabled ? .enable : .disable)
        if let error {
            throw error
        }
        state = enabled
            ? LaunchAtLoginState(status: .enabled, detailKind: .enabled)
            : LaunchAtLoginState(status: .disabled, detailKind: .disabled)
    }
}

private enum StubLaunchAtLoginError: LocalizedError {
    case registrationFailed

    var errorDescription: String? {
        "Launch at login status could not be updated."
    }
}
