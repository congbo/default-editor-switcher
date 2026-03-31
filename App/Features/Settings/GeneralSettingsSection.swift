import SwiftUI

struct GeneralSettingsSection: View {
    @ObservedObject var viewModel: GeneralSettingsViewModel
    let statusSnapshot: SettingsStatusSnapshot
    let onRefresh: () -> Void
    @ObservedObject var localizer: AppLocalizer

    var body: some View {
        Section("General") {
            VStack(alignment: .leading, spacing: 14) {
                LabeledContent(localizer.string("Current Default Editor")) {
                    HStack(spacing: 10) {
                        currentEditorIcon(size: 28, cornerRadius: 7)

                        Text(statusSnapshot.title)
                            .fontWeight(.medium)
                    }
                }

                Text(statusSnapshot.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Spacer()

                    Button(localizer.string("Refresh"), action: onRefresh)
                        .buttonStyle(.bordered)
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
                .padding(.top, 2)
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
            .launchAtLoginDetail(detailKind: viewModel.detailKind, errorMessage: viewModel.errorMessage)
    }

    @ViewBuilder
    private func currentEditorIcon(
        iconLookupPath: String? = nil,
        size: CGFloat,
        cornerRadius: CGFloat
    ) -> some View {
        let resolvedPath = iconLookupPath ?? statusSnapshot.iconLookupPath

        if let resolvedPath {
            AppIconView(iconLookupPath: resolvedPath, size: size, cornerRadius: cornerRadius)
        } else {
            Image(systemName: "square.and.pencil")
                .foregroundStyle(.secondary)
                .frame(width: size, height: size)
        }
    }
}
