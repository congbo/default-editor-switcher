import AppKit
import SwiftUI

struct MenuBarContentView: View {
    private enum Layout {
        static let menuIconSize: CGFloat = 32
        static let menuIconCornerRadius: CGFloat = 7
    }

    @Environment(\.openWindow) private var openWindow
    @StateObject private var viewModel: MenuBarViewModel
    @ObservedObject private var localizer: AppLocalizer

    init(
        viewModel: MenuBarViewModel = MenuBarViewModel(),
        localizer: AppLocalizer
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.localizer = localizer
    }

    var body: some View {
        if viewModel.primaryRows.isEmpty {
            Text(localizer.string("No Eligible Editors Found"))
                .disabled(true)
        } else {
            ForEach(viewModel.primaryRows) { row in
                Toggle(isOn: selectionBinding(for: row)) {
                    menuRowLabel(for: row)
                }
                .disabled(viewModel.applyingBundleID != nil)
            }
        }

        Menu {
            if !viewModel.overflowRows.isEmpty {
                ForEach(viewModel.overflowRows) { row in
                    Toggle(isOn: selectionBinding(for: row)) {
                        menuRowLabel(for: row)
                    }
                    .disabled(viewModel.applyingBundleID != nil)
                }

                Divider()
            }

            Button(viewModel.settingsWindowAction.title) {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: viewModel.settingsWindowAction.windowID)
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button(localizer.string("Quit Default Editor Switcher")) {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        } label: {
            Label(localizer.string("More"), systemImage: "ellipsis")
        }
    }

    private func selectionBinding(for row: MenuBarEditorRow) -> Binding<Bool> {
        Binding(
            get: { row.isCurrent },
            set: { isSelected in
                guard isSelected else {
                    return
                }

                viewModel.applyEditor(bundleID: row.bundleID)
            }
        )
    }

    @ViewBuilder
    private func menuRowLabel(for row: MenuBarEditorRow) -> some View {
        Label {
            HStack(spacing: 6) {
                Text(row.displayName)

                if row.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        } icon: {
            AppIconView(
                iconLookupPath: row.iconLookupPath,
                size: Layout.menuIconSize,
                cornerRadius: Layout.menuIconCornerRadius
            )
        }
    }
}

struct MenuBarStatusItemView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        Group {
            if let iconLookupPath = viewModel.statusItemIconLookupPath {
                AppIconView(iconLookupPath: iconLookupPath, size: 18, cornerRadius: 4)
            } else {
                Image(systemName: "square.and.pencil")
                    .imageScale(.large)
            }
        }
        .accessibilityLabel(viewModel.summary.title)
    }
}

struct AppIconView: View {
    let iconLookupPath: String
    let size: CGFloat
    let cornerRadius: CGFloat

    init(iconLookupPath: String, size: CGFloat, cornerRadius: CGFloat = 4) {
        self.iconLookupPath = iconLookupPath
        self.size = size
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        if let image = appIcon {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            Image(systemName: "square.and.pencil")
                .frame(width: size, height: size)
        }
    }

    private var appIcon: NSImage? {
        guard FileManager.default.fileExists(atPath: iconLookupPath) else {
            return nil
        }

        let image = NSWorkspace.shared.icon(forFile: iconLookupPath)
        image.size = NSSize(width: size, height: size)
        return image
    }
}
