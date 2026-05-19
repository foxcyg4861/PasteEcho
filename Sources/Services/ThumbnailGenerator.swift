import AppKit

enum ThumbnailGenerator {
    static let size = NSSize(width: 48, height: 48)

    static func generate(from imageData: Data) -> Data? {
        guard let sourceImage = NSImage(data: imageData) else { return nil }

        let thumbnail = NSImage(size: size, flipped: false) { _ in
            let sourceSize = sourceImage.size
            let scale = max(size.width / sourceSize.width, size.height / sourceSize.height)
            let drawRect = NSRect(
                x: (size.width - sourceSize.width * scale) / 2,
                y: (size.height - sourceSize.height * scale) / 2,
                width: sourceSize.width * scale,
                height: sourceSize.height * scale
            )
            sourceImage.draw(in: drawRect, from: .zero, operation: .copy, fraction: 1.0)
            return true
        }

        guard let tiff = thumbnail.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }

        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.5])
    }
}
