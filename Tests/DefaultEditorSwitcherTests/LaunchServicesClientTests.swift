import XCTest
import UniformTypeIdentifiers
@testable import DefaultEditorSwitcher

final class LaunchServicesClientTests: XCTestCase {
    func testVerificationSkipsWriteWhenRequestedHandlerAlreadyMatches() {
        let contentType = UTType(filenameExtension: "txt")!
        var fetchedEligibleRoles: [PreferredHandlerRole] = []
        var writtenRoles: [PreferredHandlerRole] = []
        let mock = MockLaunchServicesClient(
            currentHandlerBundleID: { _, _ in "com.example.editor" },
            allHandlerBundleIDs: { _, role in
                fetchedEligibleRoles.append(role)
                return ["com.example.editor"]
            },
            setDefaultHandler: { _, _, role in
                writtenRoles.append(role)
            }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(requestedBundleID: "com.example.editor", for: contentType)

        XCTAssertEqual(result.status, "matched")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.editor")
        XCTAssertTrue(fetchedEligibleRoles.isEmpty)
        XCTAssertTrue(writtenRoles.isEmpty)
    }

    func testVerificationReturnsMismatchedWhenReadbackDiffersForEditorRole() {
        let contentType = UTType(filenameExtension: "md")!
        let mock = MockLaunchServicesClient(
            currentHandlerBundleID: { _, _ in "com.example.other" },
            allHandlerBundleIDs: { _, _ in ["com.example.editor", "com.example.other"] },
            setDefaultHandler: { _, _, _ in }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(
            requestedBundleID: "com.example.editor",
            for: contentType,
            roles: [.editor]
        )

        XCTAssertEqual(result.status, "mismatched")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.other")
        XCTAssertEqual(result.primaryRoleResult?.preferredHandler.role, .editor)
    }

    func testVerificationReturnsUnsupportedTargetWhenEditorRoleCannotUseRequestedApp() {
        let contentType = UTType(filenameExtension: "py")!
        var writtenRoles: [PreferredHandlerRole] = []
        let mock = MockLaunchServicesClient(
            currentHandlerBundleID: { _, _ in "com.example.other" },
            allHandlerBundleIDs: { _, role in
                role == .editor ? [] : ["com.example.editor"]
            },
            setDefaultHandler: { _, _, role in
                writtenRoles.append(role)
            }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(
            requestedBundleID: "com.example.editor",
            for: contentType,
            roles: [.editor]
        )

        XCTAssertEqual(result.status, "unsupportedTarget")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.other")
        XCTAssertEqual(result.primaryRoleResult?.preferredHandler.role, .editor)
        XCTAssertTrue(writtenRoles.isEmpty)
    }

    func testVerificationReturnsWriteFailedWhenSetOperationThrows() {
        let contentType = UTType(filenameExtension: "rs")!
        var writtenRoles: [PreferredHandlerRole] = []
        let mock = MockLaunchServicesClient(
            currentHandlerBundleID: { _, _ in "com.example.other" },
            allHandlerBundleIDs: { _, _ in ["com.example.editor"] },
            setDefaultHandler: { bundleID, type, role in
                writtenRoles.append(role)
                throw LaunchServicesClientError.failedToSetDefaultHandler(
                    status: -10810,
                    contentTypeIdentifier: type.identifier,
                    bundleID: bundleID,
                    role: role
                )
            }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        let result = verifier.verify(
            requestedBundleID: "com.example.editor",
            for: contentType,
            roles: [.editor]
        )

        XCTAssertEqual(result.status, "writeFailed")
        XCTAssertEqual(result.requestedBundleID, "com.example.editor")
        XCTAssertEqual(result.effectiveBundleID, "com.example.other")
        XCTAssertEqual(result.primaryRoleResult?.preferredHandler.role, .editor)
        XCTAssertEqual(result.primaryRoleResult?.statusCode, -10810)
        XCTAssertEqual(writtenRoles, [.editor])
    }

    func testVerificationDefaultsToLegacyVerificationOrderWhenRolesNotSpecified() {
        let contentType = UTType(filenameExtension: "log")!
        var writtenRoles: [PreferredHandlerRole] = []
        let mock = MockLaunchServicesClient(
            currentHandlerBundleID: { _, _ in "com.example.other" },
            allHandlerBundleIDs: { _, _ in ["com.example.editor"] },
            setDefaultHandler: { _, _, role in
                writtenRoles.append(role)
            }
        )
        let verifier = LaunchServicesAssociationVerifier(client: mock)

        _ = verifier.verify(requestedBundleID: "com.example.editor", for: contentType)

        XCTAssertEqual(writtenRoles, PreferredHandlerRole.verificationOrder)
    }

    func testSilentPreferenceWriterCreatesNewHandlersForAllTargetRolesWhenPreferencesAreAbsent() throws {
        let plistURL = temporaryPlistURL()
        let writer = LaunchServicesSilentPreferenceWriter(plistURL: plistURL)

        try writer.setDefaultHandlers(
            bundleID: "com.microsoft.VSCode",
            assignments: [
                .init(contentType: UTType(filenameExtension: "txt")!, roles: PreferredHandlerRole.verificationOrder),
                .init(contentType: UTType(filenameExtension: "md")!, roles: PreferredHandlerRole.verificationOrder),
            ]
        )

        let handlers = try loadHandlers(from: plistURL)
        XCTAssertEqual(handlers.count, 2)
        XCTAssertEqual(
            Set(handlers.compactMap { $0["LSHandlerContentType"] as? String }),
            ["public.plain-text", "net.daringfireball.markdown"]
        )
        XCTAssertTrue(handlers.allSatisfy { $0["LSHandlerRoleAll"] as? String == "com.microsoft.VSCode" })
        XCTAssertTrue(handlers.allSatisfy { $0["LSHandlerRoleViewer"] as? String == "com.microsoft.VSCode" })
        XCTAssertTrue(handlers.allSatisfy { $0["LSHandlerRoleEditor"] as? String == "com.microsoft.VSCode" })
        XCTAssertTrue(
            handlers.allSatisfy {
                let preferredVersions = $0["LSHandlerPreferredVersions"] as? [String: String]
                return preferredVersions?["LSHandlerRoleAll"] == "-"
                    && preferredVersions?["LSHandlerRoleViewer"] == "-"
                    && preferredVersions?["LSHandlerRoleEditor"] == "-"
            }
        )
    }

    func testSilentPreferenceWriterUpdatesOnlyTargetedRolesForExistingContentTypeEntry() throws {
        let plistURL = temporaryPlistURL()
        try writeHandlers(
            [
                [
                    "LSHandlerContentType": "public.plain-text",
                    "LSHandlerRoleViewer": "com.apple.TextEdit",
                    "LSHandlerRoleAll": "com.apple.TextEdit",
                    "LSHandlerRoleEditor": "com.apple.TextEdit",
                ]
            ],
            to: plistURL
        )
        let writer = LaunchServicesSilentPreferenceWriter(plistURL: plistURL)

        try writer.setDefaultHandlers(
            bundleID: "com.microsoft.VSCode",
            assignments: [
                .init(
                    contentType: UTType(filenameExtension: "txt")!,
                    roles: [.viewer, .editor]
                )
            ]
        )

        let handlers = try loadHandlers(from: plistURL)
        XCTAssertEqual(handlers.count, 1)
        XCTAssertEqual(handlers[0]["LSHandlerRoleViewer"] as? String, "com.microsoft.VSCode")
        XCTAssertEqual(handlers[0]["LSHandlerRoleAll"] as? String, "com.apple.TextEdit")
        XCTAssertEqual(handlers[0]["LSHandlerRoleEditor"] as? String, "com.microsoft.VSCode")
    }

    func testSilentPreferenceWriterPreservesUnrelatedHandlersAndCollapsesDuplicates() throws {
        let plistURL = temporaryPlistURL()
        try writeHandlers(
            [
                [
                    "LSHandlerContentType": "public.plain-text",
                    "LSHandlerRoleAll": "com.apple.TextEdit",
                    "LSHandlerRoleEditor": "com.apple.TextEdit",
                    "LSHandlerPreferredVersions": [
                        "LSHandlerRoleAll": "-",
                        "LSHandlerRoleEditor": "-",
                    ],
                ],
                [
                    "LSHandlerContentType": "public.plain-text",
                    "LSHandlerRoleViewer": "com.apple.TextEdit",
                    "LSHandlerPreferredVersions": ["LSHandlerRoleViewer": "-"],
                ],
                [
                    "LSHandlerURLScheme": "https",
                    "LSHandlerRoleAll": "com.apple.Safari",
                ],
                [
                    "LSHandlerContentType": "public.json",
                    "LSHandlerRoleViewer": "com.apple.TextEdit",
                ],
            ],
            to: plistURL
        )
        let writer = LaunchServicesSilentPreferenceWriter(plistURL: plistURL)

        try writer.setDefaultHandlers(
            bundleID: "com.microsoft.VSCode",
            assignments: [
                .init(
                    contentType: UTType(filenameExtension: "txt")!,
                    roles: PreferredHandlerRole.verificationOrder
                )
            ]
        )

        let handlers = try loadHandlers(from: plistURL)
        let textHandlers = handlers.filter { $0["LSHandlerContentType"] as? String == "public.plain-text" }
        XCTAssertEqual(textHandlers.count, 1)
        XCTAssertEqual(textHandlers.first?["LSHandlerRoleAll"] as? String, "com.microsoft.VSCode")
        XCTAssertEqual(textHandlers.first?["LSHandlerRoleViewer"] as? String, "com.microsoft.VSCode")
        XCTAssertEqual(textHandlers.first?["LSHandlerRoleEditor"] as? String, "com.microsoft.VSCode")
        XCTAssertTrue(handlers.contains { $0["LSHandlerURLScheme"] as? String == "https" })
        XCTAssertTrue(
            handlers.contains {
                $0["LSHandlerContentType"] as? String == "public.json"
                    && $0["LSHandlerRoleViewer"] as? String == "com.apple.TextEdit"
            }
        )
    }

    func testRefreshSchedulerFastRefreshOnlySchedulesKillall() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let commandRunner = RecordingLaunchServicesDetachedCommandRunner()
        let lsregisterURL = temporaryCommandURL(named: "lsregister")
        let killallURL = temporaryCommandURL(named: "killall")
        let scheduler = LaunchServicesRefreshScheduler(
            commandRunner: commandRunner,
            lsregisterURL: lsregisterURL,
            killallURL: killallURL,
            queue: queue
        )

        scheduler.scheduleFastRefresh()
        queue.waitUntilAllOperationsAreFinished()

        XCTAssertEqual(
            commandRunner.invocations,
            [
                .init(executablePath: killallURL.path, arguments: ["lsd"])
            ]
        )
    }

    func testRefreshSchedulerRepairRefreshSchedulesLsregisterBeforeKillall() throws {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let commandRunner = RecordingLaunchServicesDetachedCommandRunner()
        let lsregisterURL = temporaryCommandURL(named: "lsregister")
        try FileManager.default.createDirectory(
            at: lsregisterURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data().write(to: lsregisterURL)
        let killallURL = temporaryCommandURL(named: "killall")
        let scheduler = LaunchServicesRefreshScheduler(
            commandRunner: commandRunner,
            lsregisterURL: lsregisterURL,
            killallURL: killallURL,
            queue: queue
        )

        scheduler.scheduleRepairRefresh()
        queue.waitUntilAllOperationsAreFinished()

        XCTAssertEqual(
            commandRunner.invocations,
            [
                .init(
                    executablePath: lsregisterURL.path,
                    arguments: ["-gc", "-R", "-all", "user,system,local,network"]
                ),
                .init(executablePath: killallURL.path, arguments: ["lsd"]),
            ]
        )
    }
}

private struct MockLaunchServicesClient: LaunchServicesClienting {
    let currentHandlerBundleIDProvider: (UTType, PreferredHandlerRole) -> String?
    let allHandlerBundleIDsProvider: (UTType, PreferredHandlerRole) -> [String]
    let setDefaultHandlerProvider: (String, UTType, PreferredHandlerRole) throws -> Void

    init(
        currentHandlerBundleID: @escaping (UTType, PreferredHandlerRole) -> String?,
        allHandlerBundleIDs: @escaping (UTType, PreferredHandlerRole) -> [String],
        setDefaultHandler: @escaping (String, UTType, PreferredHandlerRole) throws -> Void
    ) {
        self.currentHandlerBundleIDProvider = currentHandlerBundleID
        self.allHandlerBundleIDsProvider = allHandlerBundleIDs
        self.setDefaultHandlerProvider = setDefaultHandler
    }

    func currentHandlerBundleID(for contentType: UTType, role: PreferredHandlerRole) -> String? {
        currentHandlerBundleIDProvider(contentType, role)
    }

    func allHandlerBundleIDs(for contentType: UTType, role: PreferredHandlerRole) -> [String] {
        allHandlerBundleIDsProvider(contentType, role)
    }

    func setDefaultHandler(bundleID: String, for contentType: UTType, role: PreferredHandlerRole) throws {
        try setDefaultHandlerProvider(bundleID, contentType, role)
    }
}

private extension LaunchServicesClientTests {
    func temporaryPlistURL() -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        return directoryURL.appendingPathComponent("com.apple.launchservices.secure.plist")
    }

    func writeHandlers(_ handlers: [[String: Any]], to plistURL: URL) throws {
        try FileManager.default.createDirectory(
            at: plistURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        let data = try PropertyListSerialization.data(
            fromPropertyList: ["LSHandlers": handlers],
            format: .binary,
            options: 0
        )
        try data.write(to: plistURL)
    }

    func loadHandlers(from plistURL: URL) throws -> [[String: Any]] {
        let data = try Data(contentsOf: plistURL)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        let dictionary = try XCTUnwrap(plist as? [String: Any])
        return try XCTUnwrap(dictionary["LSHandlers"] as? [[String: Any]])
    }

    func temporaryCommandURL(named name: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent(name, isDirectory: false)
    }
}

private final class RecordingLaunchServicesDetachedCommandRunner: LaunchServicesDetachedCommandRunning {
    struct Invocation: Equatable {
        let executablePath: String
        let arguments: [String]
    }

    private(set) var invocations: [Invocation] = []

    func runDetached(executableURL: URL, arguments: [String]) throws {
        invocations.append(.init(executablePath: executableURL.path, arguments: arguments))
    }
}
