import SwiftUI

struct GeneralSettingsSection: View {
    @ObservedObject var viewModel: GeneralSettingsViewModel
    let statusSnapshot: SettingsStatusSnapshot
    @ObservedObject var localizer: AppLocalizer

    var body: some View {
        Section("General") {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 14) {
                        if let iconLookupPath = statusSnapshot.iconLookupPath {
                            AppIconView(iconLookupPath: iconLookupPath, size: 42, cornerRadius: 10)
                        } else {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 42, height: 42)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.primary.opacity(0.05))
                                )
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(localizer.string("Current Default Editor"))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(statusSnapshot.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }

                    Text(statusSnapshot.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !statusSnapshot.distributionGroups.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            sectionTitle(localizer.string("Current Distribution"))

                            ForEach(statusSnapshot.distributionGroups) { group in
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
                    }

                    if !statusSnapshot.pendingGroups.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            sectionTitle(localizer.string("Pending Assignment"))

                            ForEach(statusSnapshot.pendingGroups) { group in
                                statusGroupView(group)
                            }
                        }
                    }

                    if let recentSwitch = statusSnapshot.recentSwitch {
                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .center, spacing: 10) {
                                sectionTitle(localizer.string("Recent Switch"))

                                Spacer()

                                statusBadge(recentSwitch.statusTitle)
                            }

                            Text(recentSwitch.headline)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)

                            ForEach(recentSwitch.groups) { group in
                                statusGroupView(group)
                            }
                        }
                    }
                }
                .padding(18)
                .background(cardBackground)

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

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.primary.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    @ViewBuilder
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.semibold)
    }

    @ViewBuilder
    private func statusBadge(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.primary.opacity(0.08))
            )
    }

    @ViewBuilder
    private func statusGroupView(_ group: SettingsStatusGroup) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(group.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            extensionLinesView(group.extensionLines)
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
