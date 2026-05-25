import AppKit
import CryptoKit

struct ClipboardCapture: Sendable {
    let item: ClipboardItem
    let imageData: Data?
}

@MainActor
final class ClipboardMonitor {
    var onCapture: (@MainActor (ClipboardCapture) -> Void)?

    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount

    func start() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.poll()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        if let text = pb.string(forType: .string),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let item = ClipboardItem(
                contentType: .text,
                textContent: text,
                contentHash: SHA256.hash(data: Data(text.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
            )
            onCapture?(ClipboardCapture(item: item, imageData: nil))
            return
        }

        if let imageData = pb.data(forType: .tiff) ?? pb.data(forType: .png) {
            let hash = SHA256.hash(data: imageData).prefix(8).map { String(format: "%02x", $0) }.joined()
            let fileName = "\(UUID().uuidString).png"
            let thumbnail = ThumbnailGenerator.generate(from: imageData)
            let item = ClipboardItem(
                contentType: .image,
                imageFileName: fileName,
                thumbnailData: thumbnail,
                contentHash: hash
            )
            onCapture?(ClipboardCapture(item: item, imageData: imageData))
        }
    }
}
