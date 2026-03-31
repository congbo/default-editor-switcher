import SwiftUI

struct GlobalTextTypesSettingsSection: View {
    @ObservedObject var globalTextTypesStore: GlobalTextTypesStore
    @ObservedObject var localizer: AppLocalizer

    @State private var customExtensionDraft = ""
    @State private var customExtensionMessageKey: String?
    @State private var customExtensionMessageArguments: [String] = []
    @State private var customExtensionMessageIsError = false

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

                customSection
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

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localizer.string("Custom"))
                .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                TextField(localizer.string("Add Extension"), text: $customExtensionDraft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addCustomExtension)

                Button(localizer.string("Add"), action: addCustomExtension)
                    .buttonStyle(.borderedProminent)
                    .disabled(normalizedCustomExtensionDraft.isEmpty)
            }

            Text(localizer.string("Add any file extension here to include it in the global switch."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let customExtensionMessageKey {
                Text(customExtensionMessage(customExtensionMessageKey))
                    .font(.subheadline)
                    .foregroundStyle(customExtensionMessageIsError ? .red : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if customItems.isEmpty {
                Text(localizer.string("No custom extensions yet."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(customItems) { item in
                    customItemRow(item)
                }
            }
        }
    }

    @ViewBuilder
    private func customItemRow(_ item: GlobalTextTypeItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 10) {
                Toggle(".\(item.normalizedExtension)", isOn: enabledBinding(for: item.normalizedExtension))
                    .toggleStyle(.checkbox)
                    .fontWeight(.medium)

                Spacer(minLength: 8)

                Button(role: .destructive) {
                    removeCustomExtension(item.normalizedExtension)
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderless)
                .help(localizer.string("Remove"))
            }

            if let warningText = warningText(for: item) {
                Text(warningText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var visibleCategories: [Category] {
        let availableExtensions = Set(globalTextTypesStore.items().map(\.normalizedExtension))
        return categories.compactMap { category in
            let filtered = category.extensions.filter { availableExtensions.contains($0) }
            guard !filtered.isEmpty else {
                return nil
            }

            return Category(titleKey: category.titleKey, extensions: filtered)
        }
    }

    private var customItems: [GlobalTextTypeItem] {
        globalTextTypesStore.items()
            .filter { $0.source == .custom }
    }

    private var normalizedCustomExtensionDraft: String {
        ContentTypeResolver.normalizeExtension(customExtensionDraft)
    }

    private func addCustomExtension() {
        let result = globalTextTypesStore.addCustomExtension(customExtensionDraft)
        switch result {
        case .added:
            customExtensionDraft = ""
            setMessage(nil)
        case .emptyInput:
            setMessage(nil)
        case .duplicateBuiltIn(let normalizedExtension):
            setMessage(
                "That extension is already included in the built-in list: .%@.",
                arguments: [normalizedExtension],
                isError: true
            )
        case .duplicateCustom(let normalizedExtension):
            setMessage(
                "That custom extension already exists: .%@.",
                arguments: [normalizedExtension],
                isError: true
            )
        }
    }

    private func removeCustomExtension(_ normalizedExtension: String) {
        globalTextTypesStore.removeCustomExtension(normalizedExtension)
        setMessage(nil)
    }

    private func warningText(for item: GlobalTextTypeItem) -> String? {
        switch item.resolutionStatus {
        case .declaredTextLike:
            return nil
        case .declaredNonText:
            return localizer.formattedString(
                ".%@ is not a text type, but it will still be included in the global switch.",
                item.normalizedExtension
            )
        case .unresolved:
            return localizer.formattedString(
                ".%@ is saved, but macOS cannot resolve it yet, so the global switch will skip it.",
                item.normalizedExtension
            )
        }
    }

    private func setMessage(
        _ key: String?,
        arguments: [String] = [],
        isError: Bool = false
    ) {
        customExtensionMessageKey = key
        customExtensionMessageArguments = arguments
        customExtensionMessageIsError = isError
    }

    private func customExtensionMessage(_ key: String) -> String {
        switch customExtensionMessageArguments.count {
        case 0:
            return localizer.string(key)
        case 1:
            return localizer.formattedString(
                key,
                customExtensionMessageArguments[0]
            )
        default:
            return String(
                format: localizer.string(key),
                locale: Locale(identifier: "en_US_POSIX"),
                arguments: customExtensionMessageArguments.map { $0 as CVarArg }
            )
        }
    }
}
