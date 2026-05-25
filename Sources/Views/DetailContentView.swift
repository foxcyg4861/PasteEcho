import SwiftUI

struct DetailContentView: View {
    let item: ClipboardItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if item.contentType == .text, let text = item.textContent {
                ScrollView(.vertical) {
                    Text(text)
                        .font(.system(size: 13, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                }
            } else if item.contentType == .image {
                if let thumbnail = item.thumbnailData,
                   let nsImage = NSImage(data: thumbnail) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 400)
                }
                Text("Image")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Divider()

            HStack {
                Text("Copied at")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
