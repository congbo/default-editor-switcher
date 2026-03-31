import Combine
import XCTest
@testable import DefaultEditorSwitcher

@MainActor
final class GlobalTextTypesStoreTests: XCTestCase {
    func testDefaultConfigurationKeepsCSSEnabledAndHTMLDisabled() {
        let userDefaults = makeUserDefaults(testName: #function)
        let store = GlobalTextTypesStore(userDefaults: userDefaults)

        let configuration = store.loadConfiguration()
        let items = store.items()

        XCTAssertTrue(configuration.enabledExtensions.contains("css"))
        XCTAssertFalse(configuration.enabledExtensions.contains("html"))
        XCTAssertTrue(items.contains(where: { $0.normalizedExtension == "css" && $0.isEnabled }))
        XCTAssertTrue(items.contains(where: { $0.normalizedExtension == "html" && !$0.isEnabled }))
    }

    func testConfigurationPersistsAcrossStoreInstances() {
        let userDefaults = makeUserDefaults(testName: #function)
        let store = GlobalTextTypesStore(userDefaults: userDefaults)

        store.setEnabled(extension: "html", isEnabled: true)
        store.setEnabled(extension: "css", isEnabled: false)

        let reloadedStore = GlobalTextTypesStore(userDefaults: userDefaults)
        let configuration = reloadedStore.loadConfiguration()

        XCTAssertTrue(configuration.enabledExtensions.contains("html"))
        XCTAssertFalse(configuration.enabledExtensions.contains("css"))
    }

    func testPublisherEmitsPersistedConfiguration() {
        let userDefaults = makeUserDefaults(testName: #function)
        let store = GlobalTextTypesStore(userDefaults: userDefaults)
        var observedConfigurations: [GlobalTextTypesConfiguration] = []
        let cancellable = store.objectWillChangePublisher.sink {
            observedConfigurations.append(store.loadConfiguration())
        }
        defer { cancellable.cancel() }

        store.setEnabled(extension: "html", isEnabled: true)

        XCTAssertFalse(observedConfigurations.isEmpty)
        XCTAssertTrue(observedConfigurations.last?.enabledExtensions.contains("html") == true)
    }

    func testSetEnabledWritesActivityLog() {
        let userDefaults = makeUserDefaults(testName: #function)
        let activityStore = SettingsActivityStore()
        let store = GlobalTextTypesStore(
            userDefaults: userDefaults,
            activityLogger: activityStore
        )

        store.setEnabled(extension: "html", isEnabled: true)

        XCTAssertEqual(activityStore.entries.count, 1)
        XCTAssertEqual(activityStore.entries.last?.category, .globalTextTypes)
        XCTAssertEqual(activityStore.entries.last?.message, "Included .html in the global text switch.")
    }

    private func makeUserDefaults(testName: String) -> UserDefaults {
        let suiteName = "GlobalTextTypesStoreTests.\(testName)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
