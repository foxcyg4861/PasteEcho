import SwiftUI

struct ThumbnailImageView: View {
    let item: ClipboardItem

    var body: some View {
        Group {
            if item.contentType == .image, let thumbnailData = item.thumbnailData,
               let nsImage = NSImage(data: thumbnailData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "doc.text")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    )
            }
        }
    }
}
