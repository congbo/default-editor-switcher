import SwiftUI

struct RecommendedAppsSettingsSection: View {
    @ObservedObject var recommendedAppsStore: RecommendedMenuAppsStore
    let availableEditors: [EditorCandidate]
    @ObservedObject var localizer: AppLocalizer

    @State private var isExpanded = true

    var body: some View {
        Section {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(entries) { entry in
                    HStack(spacing: 12) {
                        Toggle("", isOn: isEnabledBinding(for: entry.bundleID))
                            .toggleStyle(.checkbox)
                            .labelsHidden()
                            .disabled(isLastEnabledEntry(entry))

                        if let iconLookupPath = entry.iconLookupPath {
                            AppIconView(iconLookupPath: iconLookupPath, size: 28, cornerRadius: 8)
                        } else {
                            Image(systemName: "square.and.pencil")
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 28)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.displayName)
                                .fontWeight(.medium)

                            Text(entry.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "line.3.horizontal")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                    .opacity(entry.isAvailable ? 1 : 0.55)
                }
                .onMove(perform: moveEntries)
            } label: {
                LabeledContent("Recommended Editors") {
                    Text(summaryLabel)
                        .foregroundStyle(.secondary)
                }
            }
        } footer: {
            Text(localizer.string("Checked editors appear in the first-level menu. Unchecked editors move to More. Drag the handle on any row to change the order."))
        }
    }

    private var entries: [RecommendedAppsEntry] {
        SettingsCopyFormatter(localizer: localizer)
            .recommendedEntries(
                availableEditors: availableEditors,
                configuration: recommendedAppsStore.loadConfiguration()
            )
    }

    private var summaryLabel: String {
        let enabledCount = entries.filter { $0.isEnabled && $0.isAvailable }.count
        return SettingsCopyFormatter(localizer: localizer).recommendedEditorsSummary(enabledCount: enabledCount)
    }

    private func isEnabledBinding(for bundleID: String) -> Binding<Bool> {
        Binding(
            get: { recommendedAppsStore.loadConfiguration().isEnabled(bundleID: bundleID) },
            set: { recommendedAppsStore.setEnabled(bundleID: bundleID, isEnabled: $0) }
        )
    }

    private func isLastEnabledEntry(_ entry: RecommendedAppsEntry) -> Bool {
        let configuration = recommendedAppsStore.loadConfiguration()
        return entry.isEnabled && configuration.enabledBundleIDs.count == 1
    }

    private func moveEntries(from offsets: IndexSet, to destination: Int) {
        recommendedAppsStore.move(
            fromOffsets: offsets,
            toOffset: destination,
            visibleBundleIDs: entries.map(\.bundleID)
        )
    }
}
