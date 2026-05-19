import AppKit
import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var pastedItemId: UUID?

    private let dataStore: DataStore

    var displayItems: [ClipboardItem] {
        let sorted = dataStore.items.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            return a.timestamp > b.timestamp
        }

        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return sorted }

        return sorted.filter { item in
            guard item.contentType == .text,
                  let text = item.textContent else { return false }
            return text.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var retentionSummary: String {
        dataStore.settings.retentionPeriod.displayName
    }

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    func pasteItem(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()

        switch item.contentType {
        case .text:
            guard let text = item.textContent else { return }
            pb.setString(text, forType: .string)
        case .image:
            guard let data = item.loadImageData(from: dataStore.baseDir) else { return }
            pb.setData(data, forType: .png)
        }

        pastedItemId = item.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            if self?.pastedItemId == item.id {
                self?.pastedItemId = nil
            }
        }
    }

    func togglePin(_ item: ClipboardItem) {
        guard let idx = dataStore.items.firstIndex(where: { $0.id == item.id }) else { return }
        dataStore.items[idx].isPinned.toggle()
    }

    func deleteItem(_ item: ClipboardItem) {
        dataStore.remove(id: item.id)
    }
}
