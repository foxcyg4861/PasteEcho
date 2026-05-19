import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let contentType: ContentType

    var textContent: String?
    var imageFileName: String?
    var thumbnailData: Data?

    let timestamp: Date
    var isPinned: Bool
    var contentHash: String?

    init(
        id: UUID = UUID(),
        contentType: ContentType,
        textContent: String? = nil,
        imageFileName: String? = nil,
        thumbnailData: Data? = nil,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        contentHash: String? = nil
    ) {
        self.id = id
        self.contentType = contentType
        self.textContent = textContent
        self.imageFileName = imageFileName
        self.thumbnailData = thumbnailData
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.contentHash = contentHash
    }

    func imageFileURL(baseDir: URL) -> URL? {
        guard let fileName = imageFileName else { return nil }
        return baseDir.appendingPathComponent("Images").appendingPathComponent(fileName)
    }

    func loadImageData(from baseDir: URL) -> Data? {
        guard let url = imageFileURL(baseDir: baseDir) else { return nil }
        return try? Data(contentsOf: url)
    }
}
