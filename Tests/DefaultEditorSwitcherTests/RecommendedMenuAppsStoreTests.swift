import Combine
import XCTest
@testable import DefaultEditorSwitcher

@MainActor
final class RecommendedMenuAppsStoreTests: XCTestCase {
    func testDefaultSeedingUsesKnownEditorsCatalogOrder() {
        let userDefaults = makeUserDefaults(testName: #function)
        let store = RecommendedMenuAppsStore(userDefaults: userDefaults)

        let configuration = store.loadConfiguration()

        XCTAssertEqual(configuration.orderedBundleIDs, KnownEditors.defaultRecommendedBundleIDs)
        XCTAssertEqual(configuration.enabledBundleIDs, Set(KnownEditors.defaultEnabledRecommendedBundleIDs))
        XCTAssertTrue(configuration.enabledBundleIDs.contains("com.apple.TextEdit"))
        XCTAssertTrue(configuration.enabledBundleIDs.contains("com.qoder.ide"))
        XCTAssertFalse(configuration.enabledBundleIDs.contains("abnerworks.Typora"))
        XCTAssertFalse(configuration.enabledBundleIDs.contains("com.macromates.TextMate"))
    }

    func testConfigurationPersistsAcrossStoreInstances() {
        let userDefaults = makeUserDefaults(testName: #function)
        let store = RecommendedMenuAppsStore(userDefaults: userDefaults)

        store.setEnabled(bundleID: "com.google.antigravity", isEnabled: false)
        store.move(bundleID: "com.microsoft.VSCode", beforeBundleID: "com.google.antigravity")

        let reloadedStore = RecommendedMenuAppsStore(userDefaults: userDefaults)
        let configuration = reloadedStore.loadConfiguration()

        XCTAssertFalse(configuration.enabledBundleIDs.contains("com.google.antigravity"))
        XCTAssertEqual(configuration.orderedBundleIDs.first, "com.microsoft.VSCode")
    }

    func testResolvedRecommendedBundleIDsFiltersAgainstAvailableApps() {
        let userDefaults = makeUserDefaults(testName: #function)
        let store = RecommendedMenuAppsStore(userDefaults: userDefaults)

        let resolved = store.resolvedRecommendedBundleIDs(
            availableBundleIDs: ["com.microsoft.VSCode", "dev.kiro.desktop"]
        )

        XCTAssertEqual(resolved, ["dev.kiro.desktop", "com.microsoft.VSCode"])
    }

    func testMoveReordersBundleIDs() {
        let userDefaults = makeUserDefaults(testName: #function)
        let store = RecommendedMenuAppsStore(userDefaults: userDefaults)

        store.move(bundleID: "com.microsoft.VSCode", beforeBundleID: "com.google.antigravity")

        XCTAssertEqual(
            Array(store.loadConfiguration().orderedBundleIDs.prefix(2)),
            ["com.microsoft.VSCode", "com.google.antigravity"]
        )
    }

    func testDisablingLastEnabledEditorIsIgnored() {
        let userDefaults = makeUserDefaults(testName: #function)
        let store = RecommendedMenuAppsStore(userDefaults: userDefaults)

        for bundleID in KnownEditors.defaultEnabledRecommendedBundleIDs where bundleID != "com.apple.TextEdit" {
            store.setEnabled(bundleID: bundleID, isEnabled: false)
        }

        store.setEnabled(bundleID: "com.apple.TextEdit", isEnabled: false)

        XCTAssertEqual(store.loadConfiguration().enabledBundleIDs, Set(["com.apple.TextEdit"]))
    }

    func testPublisherEmitsPersistedConfiguration() {
        let userDefaults = makeUserDefaults(testName: #function)
        let store = RecommendedMenuAppsStore(userDefaults: userDefaults)
        var observedConfigurations: [RecommendedMenuAppsConfiguration] = []
        let cancellable = store.objectWillChangePublisher.sink {
            observedConfigurations.append(store.loadConfiguration())
        }
        defer { cancellable.cancel() }

        store.setEnabled(bundleID: "com.google.antigravity", isEnabled: false)

        XCTAssertFalse(observedConfigurations.isEmpty)
        XCTAssertFalse(observedConfigurations.last?.enabledBundleIDs.contains("com.google.antigravity") == true)
    }

    func testMoveFromOffsetsPersistsVisibleOrderIncludingNewlyDiscoveredEditors() {
        let userDefaults = makeUserDefaults(testName: #function)
        let store = RecommendedMenuAppsStore(userDefaults: userDefaults)
        let visibleBundleIDs = [
            "com.google.antigravity",
            "com.microsoft.VSCode",
            "com.example.custom-editor",
        ]

        store.move(
            fromOffsets: IndexSet(integer: 2),
            toOffset: 0,
            visibleBundleIDs: visibleBundleIDs
        )

        let configuration = store.loadConfiguration()
        XCTAssertEqual(
            Array(configuration.orderedBundleIDs.prefix(3)),
            ["com.example.custom-editor", "com.google.antigravity", "com.microsoft.VSCode"]
        )

        let reloadedStore = RecommendedMenuAppsStore(userDefaults: userDefaults)
        XCTAssertEqual(
            Array(reloadedStore.loadConfiguration().orderedBundleIDs.prefix(3)),
            ["com.example.custom-editor", "com.google.antigravity", "com.microsoft.VSCode"]
        )
    }

    private func makeUserDefaults(testName: String) -> UserDefaults {
        let suiteName = "RecommendedMenuAppsStoreTests.\(testName)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
