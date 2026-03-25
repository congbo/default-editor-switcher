import Combine
import Foundation

struct RecommendedMenuAppsConfiguration: Equatable {
    let orderedBundleIDs: [String]
    let enabledBundleIDs: Set<String>

    func isEnabled(bundleID: String) -> Bool {
        enabledBundleIDs.contains(bundleID)
    }
}

@MainActor
protocol RecommendedMenuAppsStoring: AnyObject {
    var objectWillChangePublisher: AnyPublisher<Void, Never> { get }
    func resolvedRecommendedBundleIDs(availableBundleIDs: [String]) -> [String]
}

@MainActor
final class RecommendedMenuAppsStore: ObservableObject, RecommendedMenuAppsStoring {
    private enum Keys {
        static let orderedBundleIDs = "menu.recommendedApps.orderedBundleIDs"
        static let enabledBundleIDs = "menu.recommendedApps.enabledBundleIDs"
    }

    @Published private var configuration: RecommendedMenuAppsConfiguration

    private let userDefaults: UserDefaults
    private let didChangeSubject = PassthroughSubject<Void, Never>()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let configuration = Self.loadConfiguration(from: userDefaults)
        self.configuration = configuration
    }

    var objectWillChangePublisher: AnyPublisher<Void, Never> {
        didChangeSubject.eraseToAnyPublisher()
    }

    func loadConfiguration() -> RecommendedMenuAppsConfiguration {
        configuration
    }

    func setEnabled(bundleID: String, isEnabled: Bool) {
        var enabledBundleIDs = configuration.enabledBundleIDs
        if isEnabled {
            enabledBundleIDs.insert(bundleID)
        } else {
            guard !(enabledBundleIDs.count == 1 && enabledBundleIDs.contains(bundleID)) else {
                return
            }
            enabledBundleIDs.remove(bundleID)
        }

        persist(
            configuration: RecommendedMenuAppsConfiguration(
                orderedBundleIDs: configuration.orderedBundleIDs,
                enabledBundleIDs: enabledBundleIDs
            )
        )
    }

    func move(bundleID: String, beforeBundleID: String?) {
        var orderedBundleIDs = configuration.orderedBundleIDs
        guard let sourceIndex = orderedBundleIDs.firstIndex(of: bundleID) else {
            return
        }

        let sourceBundleID = orderedBundleIDs.remove(at: sourceIndex)
        if let beforeBundleID,
           let destinationIndex = orderedBundleIDs.firstIndex(of: beforeBundleID) {
            orderedBundleIDs.insert(sourceBundleID, at: destinationIndex)
        } else {
            orderedBundleIDs.append(sourceBundleID)
        }

        persist(
            configuration: RecommendedMenuAppsConfiguration(
                orderedBundleIDs: orderedBundleIDs,
                enabledBundleIDs: configuration.enabledBundleIDs
            )
        )
    }

    func move(fromOffsets: IndexSet, toOffset: Int, visibleBundleIDs: [String]) {
        guard !fromOffsets.isEmpty, !visibleBundleIDs.isEmpty else {
            return
        }

        var reorderedBundleIDs = visibleBundleIDs
        let movingBundleIDs = fromOffsets.sorted().map { reorderedBundleIDs[$0] }

        for index in fromOffsets.sorted(by: >) {
            reorderedBundleIDs.remove(at: index)
        }

        let removedBeforeDestination = fromOffsets.filter { $0 < toOffset }.count
        let destinationIndex = max(0, min(toOffset - removedBeforeDestination, reorderedBundleIDs.count))
        reorderedBundleIDs.insert(contentsOf: movingBundleIDs, at: destinationIndex)
        let remainingBundleIDs = configuration.orderedBundleIDs.filter { !reorderedBundleIDs.contains($0) }

        persist(
            configuration: RecommendedMenuAppsConfiguration(
                orderedBundleIDs: reorderedBundleIDs + remainingBundleIDs,
                enabledBundleIDs: configuration.enabledBundleIDs
            )
        )
    }

    func moveUp(bundleID: String) {
        guard let index = configuration.orderedBundleIDs.firstIndex(of: bundleID), index > 0 else {
            return
        }

        move(bundleID: bundleID, beforeBundleID: configuration.orderedBundleIDs[index - 1])
    }

    func moveDown(bundleID: String) {
        guard let index = configuration.orderedBundleIDs.firstIndex(of: bundleID) else {
            return
        }

        let nextIndex = index + 2
        let beforeBundleID = nextIndex <= configuration.orderedBundleIDs.count - 1
            ? configuration.orderedBundleIDs[nextIndex]
            : nil
        move(bundleID: bundleID, beforeBundleID: beforeBundleID)
    }

    func resolvedRecommendedBundleIDs(availableBundleIDs: [String]) -> [String] {
        let availableBundleIDSet = Set(availableBundleIDs)
        return configuration.orderedBundleIDs.filter { bundleID in
            configuration.enabledBundleIDs.contains(bundleID) && availableBundleIDSet.contains(bundleID)
        }
    }

    private func persist(configuration: RecommendedMenuAppsConfiguration) {
        guard self.configuration != configuration else {
            return
        }

        self.configuration = configuration
        userDefaults.set(configuration.orderedBundleIDs, forKey: Keys.orderedBundleIDs)
        userDefaults.set(Array(configuration.enabledBundleIDs), forKey: Keys.enabledBundleIDs)
        didChangeSubject.send(())
    }

    private static func loadConfiguration(from userDefaults: UserDefaults) -> RecommendedMenuAppsConfiguration {
        let defaultOrderedBundleIDs = KnownEditors.defaultRecommendedBundleIDs
        let defaultEnabledBundleIDs = KnownEditors.defaultEnabledRecommendedBundleIDs
        let storedOrderedBundleIDs = userDefaults.stringArray(forKey: Keys.orderedBundleIDs) ?? []
        let storedEnabledBundleIDs = Set(userDefaults.stringArray(forKey: Keys.enabledBundleIDs) ?? [])

        let orderedBundleIDs = normalizedOrderedBundleIDs(
            storedOrderedBundleIDs: storedOrderedBundleIDs,
            defaultOrderedBundleIDs: defaultOrderedBundleIDs
        )
        let enabledBundleIDs = normalizedEnabledBundleIDs(
            storedEnabledBundleIDs: storedEnabledBundleIDs,
            orderedBundleIDs: orderedBundleIDs,
            defaultEnabledBundleIDs: defaultEnabledBundleIDs
        )

        return RecommendedMenuAppsConfiguration(
            orderedBundleIDs: orderedBundleIDs,
            enabledBundleIDs: enabledBundleIDs
        )
    }

    private static func normalizedOrderedBundleIDs(
        storedOrderedBundleIDs: [String],
        defaultOrderedBundleIDs: [String]
    ) -> [String] {
        var seen = Set<String>()
        let combinedOrderedBundleIDs = storedOrderedBundleIDs + defaultOrderedBundleIDs
        return combinedOrderedBundleIDs.filter { seen.insert($0).inserted }
    }

    private static func normalizedEnabledBundleIDs(
        storedEnabledBundleIDs: Set<String>,
        orderedBundleIDs: [String],
        defaultEnabledBundleIDs: [String]
    ) -> Set<String> {
        let fallbackEnabledBundleIDs = Set(defaultEnabledBundleIDs)
        guard !storedEnabledBundleIDs.isEmpty else {
            return fallbackEnabledBundleIDs
        }

        let normalizedEnabledBundleIDs = Set(
            orderedBundleIDs.filter { storedEnabledBundleIDs.contains($0) }
        )

        return normalizedEnabledBundleIDs.isEmpty ? fallbackEnabledBundleIDs : normalizedEnabledBundleIDs
    }
}

@MainActor
final class TransientRecommendedMenuAppsStore: RecommendedMenuAppsStoring {
    var objectWillChangePublisher: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    func resolvedRecommendedBundleIDs(availableBundleIDs: [String]) -> [String] {
        let availableBundleIDSet = Set(availableBundleIDs)
        return KnownEditors.defaultEnabledRecommendedBundleIDs.filter { availableBundleIDSet.contains($0) }
    }
}
