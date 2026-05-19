import AppKit
import Combine
import CryptoKit

struct ClipboardCapture {
    let item: ClipboardItem
    let imageData: Data?
}

@MainActor
final class ClipboardMonitor {
    let newCapturePublisher = PassthroughSubject<ClipboardCapture, Never>()

    private var timer: AnyCancellable?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var lastTextContent: String?

    func start() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.poll()
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        lastTextContent = nil

        if let text = pb.string(forType: .string),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lastTextContent = text
            let item = ClipboardItem(
                contentType: .text,
                textContent: text,
                contentHash: SHA256.hash(data: Data(text.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
            )
            newCapturePublisher.send(ClipboardCapture(item: item, imageData: nil))
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
            newCapturePublisher.send(ClipboardCapture(item: item, imageData: imageData))
        }
    }
}
