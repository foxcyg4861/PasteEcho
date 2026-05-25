import Foundation
import Combine

@MainActor
final class DataStore: ObservableObject {
    static let shared = DataStore()

    @Published var items: [ClipboardItem] = []
    @Published var settings = Settings()
    var onItemsChanged: (@MainActor () -> Void)?
    var onWindowModeChanged: (@MainActor () -> Void)?

    let baseDir: URL
    private let itemsFileURL: URL
    private let settingsFileURL: URL
    private let imagesDir: URL
    private var saveCancellable: AnyCancellable?

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        baseDir = appSupport.appendingPathComponent("PasteEcho")
        itemsFileURL = baseDir.appendingPathComponent("items.json")
        settingsFileURL = baseDir.appendingPathComponent("settings.json")
        imagesDir = baseDir.appendingPathComponent("Images")

        try? FileManager.default.createDirectory(
            at: imagesDir, withIntermediateDirectories: true
        )

        loadItems()
        loadSettings()
        cleanupExpired()
        enforceMaxCount()

        saveCancellable = $items
            .dropFirst()
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveItems()
            }
    }

    // MARK: - Item Management

    func add(_ item: ClipboardItem) {
        if let hash = item.contentHash,
           let existingIdx = items.firstIndex(where: { $0.contentHash == hash }) {
            items.remove(at: existingIdx)
        }
        items.insert(item, at: 0)
        cleanupExpired()
        enforceMaxCount()
        onItemsChanged?()
    }

    func remove(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let item = items[idx]

        if item.contentType == .image, let fileName = item.imageFileName {
            let fileURL = imagesDir.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }

        items.remove(at: idx)
        onItemsChanged?()
    }

    // MARK: - Cleanup

    func cleanupExpired() {
        let cutoff = settings.retentionPeriod.cutoffDate
        let expired = items.filter { !$0.isPinned && $0.timestamp < cutoff }
        for item in expired {
            remove(id: item.id)
        }
    }

    func enforceMaxCount() {
        let unpinned = items.filter { !$0.isPinned }
        let excess = unpinned.count - settings.maxItemCount
        guard excess > 0 else { return }

        let toRemove = unpinned
            .sorted(by: { $0.timestamp < $1.timestamp })
            .prefix(excess)
        for item in toRemove {
            remove(id: item.id)
        }
    }

    // MARK: - Persistence

    func saveImageData(_ data: Data, fileName: String) {
        let fileURL = imagesDir.appendingPathComponent(fileName)
        try? data.write(to: fileURL)
    }

    private func loadItems() {
        guard FileManager.default.fileExists(atPath: itemsFileURL.path),
              let data = try? Data(contentsOf: itemsFileURL) else { return }

        let decoder = JSONDecoder()
        if let loaded = try? decoder.decode([ClipboardItem].self, from: data) {
            items = loaded
        } else {
            let backupURL = itemsFileURL.appendingPathExtension("bak")
            try? FileManager.default.moveItem(at: itemsFileURL, to: backupURL)
            print("PasteEcho: Corrupted items.json backed up to \(backupURL.path)")
        }
    }

    private func saveItems() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(items) else { return }

        let tempURL = baseDir.appendingPathComponent("items_temp.json")
        try? data.write(to: tempURL)

        if FileManager.default.fileExists(atPath: itemsFileURL.path) {
            var resultingURL: NSURL?
            try? FileManager.default.replaceItem(
                at: itemsFileURL,
                withItemAt: tempURL,
                backupItemName: nil,
                options: [],
                resultingItemURL: &resultingURL
            )
        } else {
            try? FileManager.default.moveItem(at: tempURL, to: itemsFileURL)
        }
    }

    func loadSettings() {
        guard let data = try? Data(contentsOf: settingsFileURL),
              let loaded = try? JSONDecoder().decode(Settings.self, from: data) else { return }
        settings = loaded
    }

    func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        try? data.write(to: settingsFileURL)
    }
}
