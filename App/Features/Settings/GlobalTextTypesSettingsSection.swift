import SwiftUI

struct GlobalTextTypesSettingsSection: View {
    @ObservedObject var globalTextTypesStore: GlobalTextTypesStore
    @ObservedObject var localizer: AppLocalizer

    private struct Category: Identifiable {
        let titleKey: String
        let extensions: [String]

        var id: String {
            titleKey
        }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 160), alignment: .topLeading)
    ]

    private let categories: [Category] = [
        Category(titleKey: "Documents", extensions: ["txt", "md", "mdx"]),
        Category(titleKey: "Config & Data", extensions: ["json", "yaml", "yml", "toml", "xml", "csv", "log", "ini", "conf", "cfg", "env"]),
        Category(titleKey: "Shell Scripts", extensions: ["sh", "zsh", "bash", "fish"]),
        Category(titleKey: "Web", extensions: ["css", "html", "js", "jsx", "ts", "tsx", "vue", "svelte"]),
        Category(titleKey: "Languages", extensions: ["py", "go", "java", "rs"]),
    ]

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                Text(localizer.string("Choose which file types are affected by the menu bar's one-click global switch. HTML stays available here, but is off by default."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(visibleCategories) { category in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(localizer.string(category.titleKey))
                            .font(.headline)

                        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                            ForEach(category.extensions, id: \.self) { normalizedExtension in
                                Toggle(".\(normalizedExtension)", isOn: enabledBinding(for: normalizedExtension))
                                    .toggleStyle(.checkbox)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
        } header: {
            Text(localizer.string("Global Text Types"))
        } footer: {
            Text(localizer.string("Checked types will be overwritten together when you choose \"Use … for All Text Files\" from the menu bar."))
        }
    }

    private func enabledBinding(for normalizedExtension: String) -> Binding<Bool> {
        Binding(
            get: { globalTextTypesStore.loadConfiguration().isEnabled(extension: normalizedExtension) },
            set: { globalTextTypesStore.setEnabled(extension: normalizedExtension, isEnabled: $0) }
        )
    }

    private var visibleCategories: [Category] {
        let availableExtensions = Set(globalTextTypesStore.loadConfiguration().availableExtensions)
        return categories.compactMap { category in
            let filtered = category.extensions.filter { availableExtensions.contains($0) }
            guard !filtered.isEmpty else {
                return nil
            }

            return Category(titleKey: category.titleKey, extensions: filtered)
        }
    }
}
