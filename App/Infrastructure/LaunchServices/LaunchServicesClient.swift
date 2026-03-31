import CoreServices
import Foundation
import UniformTypeIdentifiers

protocol LaunchServicesClienting {
    func currentHandlerBundleID(for contentType: UTType, role: PreferredHandlerRole) -> String?
    func allHandlerBundleIDs(for contentType: UTType, role: PreferredHandlerRole) -> [String]
    func setDefaultHandler(bundleID: String, for contentType: UTType, role: PreferredHandlerRole) throws
}

enum LaunchServicesClientError: Error, Hashable {
    case failedToSetDefaultHandler(
        status: OSStatus,
        contentTypeIdentifier: String,
        bundleID: String,
        role: PreferredHandlerRole
    )

    var status: OSStatus {
        switch self {
        case .failedToSetDefaultHandler(let status, _, _, _):
            return status
        }
    }
}

struct LaunchServicesClient: LaunchServicesClienting {
    func currentHandlerBundleID(for contentType: UTType, role: PreferredHandlerRole) -> String? {
        string(
            from: LSCopyDefaultRoleHandlerForContentType(
                contentType.identifier as CFString,
                role.lsRolesMask
            )
        )
    }

    func allHandlerBundleIDs(for contentType: UTType, role: PreferredHandlerRole) -> [String] {
        deduplicating(
            strings(
                from: LSCopyAllRoleHandlersForContentType(
                    contentType.identifier as CFString,
                    role.lsRolesMask
                )
            )
        )
    }

    func setDefaultHandler(bundleID: String, for contentType: UTType, role: PreferredHandlerRole) throws {
        let status = LSSetDefaultRoleHandlerForContentType(
            contentType.identifier as CFString,
            role.lsRolesMask,
            bundleID as CFString
        )

        guard status == noErr else {
            throw LaunchServicesClientError.failedToSetDefaultHandler(
                status: status,
                contentTypeIdentifier: contentType.identifier,
                bundleID: bundleID,
                role: role
            )
        }
    }

    private func string(from unmanaged: Unmanaged<CFString>?) -> String? {
        unmanaged?.takeRetainedValue() as String?
    }

    private func strings(from unmanaged: Unmanaged<CFArray>?) -> [String] {
        guard let array = unmanaged?.takeRetainedValue() else {
            return []
        }

        return (array as NSArray).compactMap { $0 as? String }
    }

    private func deduplicating(_ bundleIDs: [String]) -> [String] {
        var seen = Set<String>()
        return bundleIDs.filter { seen.insert($0).inserted }
    }
}

protocol LaunchServicesPreferenceBatchWriting {
    func setDefaultHandlers(bundleID: String, assignments: [LaunchServicesRoleAssignment]) throws
}

struct LaunchServicesRoleAssignment: Equatable {
    let contentType: UTType
    let roles: [PreferredHandlerRole]

    init(contentType: UTType, roles: [PreferredHandlerRole]) {
        self.contentType = contentType
        self.roles = roles
    }
}

enum LaunchServicesSilentPreferenceWriterError: LocalizedError {
    case invalidPreferencesFormat
    case failedToCreatePreferencesDirectory
    case failedToSerializePreferences
    case failedToWritePreferences

    var errorDescription: String? {
        switch self {
        case .invalidPreferencesFormat:
            return "Silent switch could not read Launch Services preferences. Try again, or log out and back in."
        case .failedToCreatePreferencesDirectory:
            return "Silent switch could not prepare Launch Services preferences. Try again, or log out and back in."
        case .failedToSerializePreferences:
            return "Silent switch could not save Launch Services preferences. Try again, or log out and back in."
        case .failedToWritePreferences:
            return "Silent switch could not write Launch Services preferences. Try again, or log out and back in."
        }
    }
}

struct LaunchServicesSilentPreferenceWriter: LaunchServicesPreferenceBatchWriting {
    private enum Keys {
        static let handlers = "LSHandlers"
        static let contentType = "LSHandlerContentType"
        static let preferredVersions = "LSHandlerPreferredVersions"
    }

    private let plistURL: URL
    private let fileManager: FileManager

    init(
        plistURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.plistURL = plistURL ?? Self.defaultPreferencesURL(fileManager: fileManager)
        self.fileManager = fileManager
    }

    func setDefaultHandlers(bundleID: String, assignments: [LaunchServicesRoleAssignment]) throws {
        let normalizedAssignments = normalizedAssignments(from: assignments)
        guard !normalizedAssignments.isEmpty else {
            return
        }

        var propertyList = try loadPropertyList()
        let existingHandlers = propertyList[Keys.handlers] as? [[String: Any]] ?? []
        propertyList[Keys.handlers] = upsertHandlers(
            existingHandlers,
            bundleID: bundleID,
            assignments: normalizedAssignments
        )

        let directoryURL = plistURL.deletingLastPathComponent()
        do {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            throw LaunchServicesSilentPreferenceWriterError.failedToCreatePreferencesDirectory
        }

        let data: Data
        do {
            data = try PropertyListSerialization.data(
                fromPropertyList: propertyList,
                format: .binary,
                options: 0
            )
        } catch {
            throw LaunchServicesSilentPreferenceWriterError.failedToSerializePreferences
        }

        do {
            try data.write(to: plistURL, options: .atomic)
        } catch {
            throw LaunchServicesSilentPreferenceWriterError.failedToWritePreferences
        }
    }

    private func loadPropertyList() throws -> [String: Any] {
        guard fileManager.fileExists(atPath: plistURL.path) else {
            return [:]
        }

        let data = try Data(contentsOf: plistURL)
        let propertyList = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let dictionary = propertyList as? [String: Any] else {
            throw LaunchServicesSilentPreferenceWriterError.invalidPreferencesFormat
        }
        return dictionary
    }

    private func normalizedAssignments(
        from assignments: [LaunchServicesRoleAssignment]
    ) -> [String: [PreferredHandlerRole]] {
        var groupedRoles: [String: Set<PreferredHandlerRole>] = [:]

        for assignment in assignments {
            let identifier = assignment.contentType.identifier
            groupedRoles[identifier, default: []].formUnion(assignment.roles)
        }

        return groupedRoles.reduce(into: [:]) { partialResult, entry in
            partialResult[entry.key] = PreferredHandlerRole.verificationOrder.filter(entry.value.contains)
        }
    }

    private func upsertHandlers(
        _ handlers: [[String: Any]],
        bundleID: String,
        assignments: [String: [PreferredHandlerRole]]
    ) -> [[String: Any]] {
        let targetIdentifiers = Set(assignments.keys)
        var updatedIdentifiers = Set<String>()
        var updatedHandlers: [[String: Any]] = []

        for handler in handlers {
            guard let contentTypeIdentifier = handler[Keys.contentType] as? String,
                  targetIdentifiers.contains(contentTypeIdentifier) else {
                updatedHandlers.append(handler)
                continue
            }

            if updatedIdentifiers.insert(contentTypeIdentifier).inserted {
                updatedHandlers.append(
                    updatedHandler(
                        handler,
                        contentTypeIdentifier: contentTypeIdentifier,
                        bundleID: bundleID,
                        roles: assignments[contentTypeIdentifier] ?? []
                    )
                )
                continue
            }

            if let strippedHandler = strippedRegistration(
                from: handler,
                roles: assignments[contentTypeIdentifier] ?? []
            ) {
                updatedHandlers.append(strippedHandler)
            }
        }

        for contentTypeIdentifier in targetIdentifiers.sorted() where !updatedIdentifiers.contains(contentTypeIdentifier) {
            updatedHandlers.append(
                updatedHandler(
                    [:],
                    contentTypeIdentifier: contentTypeIdentifier,
                    bundleID: bundleID,
                    roles: assignments[contentTypeIdentifier] ?? []
                )
            )
        }

        return updatedHandlers
    }

    private func updatedHandler(
        _ handler: [String: Any],
        contentTypeIdentifier: String,
        bundleID: String,
        roles: [PreferredHandlerRole]
    ) -> [String: Any] {
        var updated = handler
        updated[Keys.contentType] = contentTypeIdentifier

        var preferredVersions = handler[Keys.preferredVersions] as? [String: Any] ?? [:]

        for role in roles {
            let roleKey = role.preferenceKey
            updated[roleKey] = bundleID
            preferredVersions[roleKey] = "-"
        }

        updated[Keys.preferredVersions] = preferredVersions

        return updated
    }

    private func strippedRegistration(
        from handler: [String: Any],
        roles: [PreferredHandlerRole]
    ) -> [String: Any]? {
        var stripped = handler

        for role in roles {
            stripped.removeValue(forKey: role.preferenceKey)
        }

        if var preferredVersions = stripped[Keys.preferredVersions] as? [String: Any] {
            for role in roles {
                preferredVersions.removeValue(forKey: role.preferenceKey)
            }
            if preferredVersions.isEmpty {
                stripped.removeValue(forKey: Keys.preferredVersions)
            } else {
                stripped[Keys.preferredVersions] = preferredVersions
            }
        }

        let meaningfulKeys = Set(stripped.keys).subtracting([Keys.contentType])
        return meaningfulKeys.isEmpty ? nil : stripped
    }

    private static func defaultPreferencesURL(fileManager: FileManager) -> URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Preferences", isDirectory: true)
            .appendingPathComponent("com.apple.LaunchServices", isDirectory: true)
            .appendingPathComponent("com.apple.launchservices.secure.plist", isDirectory: false)
    }
}

protocol LaunchServicesDatabaseReloading {
    func reload() throws
}

protocol LaunchServicesRefreshScheduling {
    func scheduleFastRefresh()
    func scheduleRepairRefresh()
}

protocol LaunchServicesCommandRunning {
    func run(executableURL: URL, arguments: [String]) throws
}

protocol LaunchServicesDetachedCommandRunning {
    func runDetached(executableURL: URL, arguments: [String]) throws
}

enum LaunchServicesDatabaseReloadError: LocalizedError {
    case failedToRefresh(String)

    var errorDescription: String? {
        switch self {
        case .failedToRefresh(let detail):
            return "Silent switch saved, but macOS did not refresh Launch Services (\(detail)). Log out and back in, or restart."
        }
    }
}

struct LaunchServicesDatabaseReloader: LaunchServicesDatabaseReloading {
    private let commandRunner: LaunchServicesCommandRunning
    private let fileManager: FileManager
    private let lsregisterURL: URL
    private let killallURL: URL

    init(
        commandRunner: LaunchServicesCommandRunning = ProcessLaunchServicesCommandRunner(),
        fileManager: FileManager = .default,
        lsregisterURL: URL = URL(fileURLWithPath: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"),
        killallURL: URL = URL(fileURLWithPath: "/usr/bin/killall")
    ) {
        self.commandRunner = commandRunner
        self.fileManager = fileManager
        self.lsregisterURL = lsregisterURL
        self.killallURL = killallURL
    }

    func reload() throws {
        if fileManager.fileExists(atPath: lsregisterURL.path) {
            do {
                try commandRunner.run(
                    executableURL: lsregisterURL,
                    arguments: ["-gc", "-R", "-all", "user,system,local,network"]
                )
            } catch {
                throw LaunchServicesDatabaseReloadError.failedToRefresh("lsregister")
            }
        }

        do {
            try commandRunner.run(executableURL: killallURL, arguments: ["lsd"])
        } catch {
            throw LaunchServicesDatabaseReloadError.failedToRefresh("killall lsd")
        }
    }
}

final class LaunchServicesRefreshScheduler: LaunchServicesRefreshScheduling {
    private let commandRunner: LaunchServicesDetachedCommandRunning
    private let fileManager: FileManager
    private let lsregisterURL: URL
    private let killallURL: URL
    private let queue: OperationQueue

    init(
        commandRunner: LaunchServicesDetachedCommandRunning = ProcessLaunchServicesCommandRunner(),
        fileManager: FileManager = .default,
        lsregisterURL: URL = URL(fileURLWithPath: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"),
        killallURL: URL = URL(fileURLWithPath: "/usr/bin/killall"),
        queue: OperationQueue = LaunchServicesRefreshScheduler.makeQueue()
    ) {
        self.commandRunner = commandRunner
        self.fileManager = fileManager
        self.lsregisterURL = lsregisterURL
        self.killallURL = killallURL
        self.queue = queue
    }

    func scheduleFastRefresh() {
        queue.addOperation { [commandRunner, killallURL] in
            try? commandRunner.runDetached(executableURL: killallURL, arguments: ["lsd"])
        }
    }

    func scheduleRepairRefresh() {
        queue.addOperation { [commandRunner, fileManager, lsregisterURL, killallURL] in
            if fileManager.fileExists(atPath: lsregisterURL.path) {
                try? commandRunner.runDetached(
                    executableURL: lsregisterURL,
                    arguments: ["-gc", "-R", "-all", "user,system,local,network"]
                )
            }

            try? commandRunner.runDetached(executableURL: killallURL, arguments: ["lsd"])
        }
    }

    private static func makeQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.name = "io.github.congbo.DefaultEditorSwitcher.launch-services-refresh"
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = 1
        return queue
    }
}

struct ProcessLaunchServicesCommandRunner: LaunchServicesCommandRunning {
    func run(executableURL: URL, arguments: [String]) throws {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw LaunchServicesDatabaseReloadError.failedToRefresh(
                output?.isEmpty == false ? output! : executableURL.lastPathComponent
            )
        }
    }
}

extension ProcessLaunchServicesCommandRunner: LaunchServicesDetachedCommandRunning {
    func runDetached(executableURL: URL, arguments: [String]) throws {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        try process.run()
    }
}

private extension PreferredHandlerRole {
    var preferenceKey: String {
        switch self {
        case .all:
            return "LSHandlerRoleAll"
        case .viewer:
            return "LSHandlerRoleViewer"
        case .editor:
            return "LSHandlerRoleEditor"
        }
    }

    var lsRolesMask: LSRolesMask {
        switch self {
        case .all:
            return .all
        case .viewer:
            return .viewer
        case .editor:
            return .editor
        }
    }
}
