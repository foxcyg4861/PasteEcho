import SwiftUI

struct ClipboardCard: View {
    let item: ClipboardItem
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showActionPopover = false

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
        .onTapGesture {
            showActionPopover = true
        }
        .popover(isPresented: $showActionPopover, arrowEdge: .trailing) {
            ClipboardActionPopover(item: item)
        }
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
