import SwiftUI

struct PopoverRootView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            SearchBar()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            Divider()
            contentArea
            Divider()
            footerBar
        }
        .frame(width: 380, height: 520)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Image(systemName: "clipboard.fill")
                .foregroundColor(.pasteEchoBlue)
                .font(.system(size: 16))
            Text("PasteEcho")
                .font(.system(size: 16, weight: .semibold))
            Spacer()
            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 36)
    }

    // MARK: - Content

    private var contentArea: some View {
        Group {
            if viewModel.displayItems.isEmpty {
                EmptyStateView()
            } else {
                ClipboardListView()
            }
        }
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack {
            Text("\(viewModel.displayItems.count) items")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(viewModel.retentionSummary)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
