import SwiftUI

struct GeneralSettingsSection: View {
    @ObservedObject var viewModel: GeneralSettingsViewModel
    let currentDefaultEditor: CurrentDefaultEditorSnapshot
    @ObservedObject var localizer: AppLocalizer

    var body: some View {
        Section("General") {
            VStack(alignment: .leading, spacing: 6) {
                LabeledContent("Current Default Editor") {
                    HStack(spacing: 10) {
                        if let iconLookupPath = currentDefaultEditor.iconLookupPath {
                            AppIconView(iconLookupPath: iconLookupPath, size: 28, cornerRadius: 6)
                        } else {
                            Image(systemName: "square.and.pencil")
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 28)
                        }

                        Text(currentDefaultEditor.title)
                            .fontWeight(.medium)
                    }
                }

                Text(currentDefaultEditor.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !currentDefaultEditor.groups.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(currentDefaultEditor.groups) { group in
                            HStack(alignment: .top, spacing: 10) {
                                if let iconLookupPath = group.iconLookupPath {
                                    AppIconView(iconLookupPath: iconLookupPath, size: 20, cornerRadius: 4)
                                } else {
                                    Image(systemName: "square.and.pencil")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20, height: 20)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(group.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    extensionLinesView(group.extensionLines)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                LabeledContent("Launch at login") {
                    Toggle("", isOn: launchAtLoginBinding)
                        .labelsHidden()
                        .disabled(viewModel.isBusy)
                }

                Text(launchAtLoginDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isEnabled },
            set: { viewModel.setLaunchAtLoginEnabled($0) }
        )
    }

    private var launchAtLoginDetail: String {
        SettingsCopyFormatter(localizer: localizer)
            .launchAtLoginDetail(status: viewModel.status, errorMessage: viewModel.errorMessage)
    }

    @ViewBuilder
    private func extensionLinesView(_ lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(lines.indices, id: \.self) { index in
                Text(lines[index])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }
}
