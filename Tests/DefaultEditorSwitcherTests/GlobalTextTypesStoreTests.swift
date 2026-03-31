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
        XCTAssertEqual(store.addCustomExtension("  .foo  "), .added("foo"))
        store.setEnabled(extension: "foo", isEnabled: false)

        let reloadedStore = GlobalTextTypesStore(userDefaults: userDefaults)
        let configuration = reloadedStore.loadConfiguration()

        XCTAssertTrue(configuration.enabledExtensions.contains("html"))
        XCTAssertFalse(configuration.enabledExtensions.contains("css"))
        XCTAssertEqual(configuration.customExtensions, ["foo"])
        XCTAssertFalse(configuration.enabledExtensions.contains("foo"))
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

    func testAddCustomExtensionNormalizesPersistsAndEnablesIt() {
        let userDefaults = makeUserDefaults(testName: #function)
        let store = GlobalTextTypesStore(userDefaults: userDefaults)

        let result = store.addCustomExtension("  .foo/bar  ")
        let configuration = store.loadConfiguration()
        let item = store.items().first { $0.normalizedExtension == "foo/bar" }

        XCTAssertEqual(result, .added("foo/bar"))
        XCTAssertEqual(configuration.customExtensions, ["foo/bar"])
        XCTAssertTrue(configuration.enabledExtensions.contains("foo/bar"))
        XCTAssertEqual(item?.source, .custom)
        XCTAssertEqual(item?.resolutionStatus, .unresolved)
        XCTAssertEqual(userDefaults.stringArray(forKey: "globalTextTypes.customExtensions"), ["foo/bar"])
    }

    func testAddCustomExtensionRejectsBuiltInAndDuplicateCustomTypes() {
        let userDefaults = makeUserDefaults(testName: #function)
        let store = GlobalTextTypesStore(userDefaults: userDefaults)

        XCTAssertEqual(store.addCustomExtension(".md"), .duplicateBuiltIn("md"))
        XCTAssertEqual(store.addCustomExtension(".foo"), .added("foo"))
        XCTAssertEqual(store.addCustomExtension("foo"), .duplicateCustom("foo"))
        XCTAssertEqual(store.loadConfiguration().customExtensions, ["foo"])
    }

    func testRemoveCustomExtensionAlsoRemovesEnabledState() {
        let userDefaults = makeUserDefaults(testName: #function)
        let activityStore = SettingsActivityStore()
        let store = GlobalTextTypesStore(
            userDefaults: userDefaults,
            activityLogger: activityStore
        )

        _ = store.addCustomExtension(".foo")
        store.removeCustomExtension("foo")

        let configuration = store.loadConfiguration()

        XCTAssertFalse(configuration.customExtensions.contains("foo"))
        XCTAssertFalse(configuration.enabledExtensions.contains("foo"))
        XCTAssertFalse(store.items().contains { $0.normalizedExtension == "foo" })
        XCTAssertEqual(activityStore.entries.last?.message, "Removed custom global type .foo.")
    }

    func testItemsClassifyResolvedTextNonTextAndUnresolvedCustomTypes() {
        let userDefaults = makeUserDefaults(testName: #function)
        let store = GlobalTextTypesStore(userDefaults: userDefaults)

        _ = store.addCustomExtension(".swift")
        _ = store.addCustomExtension(".png")
        _ = store.addCustomExtension(".foo/bar")

        let itemsByExtension = Dictionary(uniqueKeysWithValues: store.items().map { ($0.normalizedExtension, $0) })

        XCTAssertEqual(itemsByExtension["swift"]?.resolutionStatus, .declaredTextLike)
        XCTAssertEqual(itemsByExtension["png"]?.resolutionStatus, .declaredNonText)
        XCTAssertEqual(itemsByExtension["foo/bar"]?.resolutionStatus, .unresolved)
    }

    private func makeUserDefaults(testName: String) -> UserDefaults {
        let suiteName = "GlobalTextTypesStoreTests.\(testName)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
