import SwiftUI

struct ClipboardCard: View {
    let item: ClipboardItem
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            ThumbnailImageView(item: item)

            VStack(alignment: .leading, spacing: 2) {
                Text(previewText)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .foregroundColor(.primary)

                Text(item.timestamp.relativeDisplay)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)

            if isHovered || item.isPinned {
                HStack(spacing: 4) {
                    Button {
                        viewModel.togglePin(item)
                    } label: {
                        Image(systemName: item.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 14))
                            .foregroundColor(item.isPinned ? .pasteEchoBlue : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(item.isPinned ? "Unpin" : "Pin")

                    Button {
                        viewModel.deleteItem(item)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.pasteEchoDestructive)
                    }
                    .buttonStyle(.plain)
                    .help("Delete")
                }
            }

            if viewModel.pastedItemId == item.id {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(item.isPinned ? Color.pasteEchoPinnedTint : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            viewModel.pasteItem(item)
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: viewModel.pastedItemId)
    }

    private var previewText: String {
        switch item.contentType {
        case .text:
            return item.textContent ?? ""
        case .image:
            return "Image"
        }
    }
}
