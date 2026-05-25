import SwiftUI

struct ClipboardActionPopover: View {
    let item: ClipboardItem
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Button {
                dismiss()
                (NSApp.delegate as? AppDelegate)?.showDetailWindow(for: item)
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                        .frame(width: 20)
                    Text("Detail")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 40)

            Button {
                viewModel.pasteItem(item)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                        .frame(width: 20)
                    Text("Copy")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 40)

            Button {
                viewModel.togglePin(item)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: item.isPinned ? "pin.slash" : "pin")
                        .frame(width: 20)
                    Text(item.isPinned ? "Unpin" : "Pin")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 40)

            Button(role: .destructive) {
                viewModel.deleteItem(item)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .frame(width: 20)
                    Text("Delete")
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 200)
    }
}
