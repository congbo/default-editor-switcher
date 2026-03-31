import Foundation
import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
    case enabled
    case disabled
    case requiresApproval
}

enum LaunchAtLoginDetailKind: Equatable {
    case neutral
    case enabled
    case disabled
    case approvalRequired
}

struct LaunchAtLoginState: Equatable {
    let status: LaunchAtLoginStatus
    let detailKind: LaunchAtLoginDetailKind
}

enum LaunchAtLoginControllerStatus: Equatable {
    case enabled
    case notRegistered
    case notFound
    case requiresApproval
    case unknown
}

protocol LaunchAtLoginControlling {
    func currentState() -> LaunchAtLoginState
    func setEnabled(_ enabled: Bool) throws
}

struct LaunchAtLoginService: LaunchAtLoginControlling {
    func currentState() -> LaunchAtLoginState {
        Self.state(for: currentControllerStatus())
    }

    static func state(for status: LaunchAtLoginControllerStatus) -> LaunchAtLoginState {
        switch status {
        case .enabled:
            return LaunchAtLoginState(status: .enabled, detailKind: .enabled)
        case .notRegistered:
            return LaunchAtLoginState(status: .disabled, detailKind: .disabled)
        case .notFound, .unknown:
            return LaunchAtLoginState(status: .disabled, detailKind: .neutral)
        case .requiresApproval:
            return LaunchAtLoginState(status: .requiresApproval, detailKind: .approvalRequired)
        }
    }

    private func currentControllerStatus() -> LaunchAtLoginControllerStatus {
        switch SMAppService.mainApp.status {
        case .enabled:
            return .enabled
        case .notRegistered:
            return .notRegistered
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .notFound
        @unknown default:
            return .unknown
        }
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
