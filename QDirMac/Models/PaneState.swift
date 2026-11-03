import Foundation
import Observation
#if canImport(AppKit)
import AppKit
#endif

@Observable
final class PaneState: Identifiable {
    let id = UUID()
    var currentURL: URL
    var items: [FileItem] = []
    var selectedItems: Set<String> = []
    var sortColumn: SortColumn = .name
    var sortOrder: SortOrder = .ascending
    var filterText: String = ""
    var history: [URL] = []
    var historyIndex: Int = -1
    var isLoading: Bool = false

    init(url: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.currentURL = url
        loadDirectory()
    }

    var canGoBack: Bool { historyIndex > 0 }
    var canGoForward: Bool { historyIndex < history.count - 1 }

    var filteredItems: [FileItem] {
        let filtered = filterText.isEmpty
            ? items
            : items.filter { $0.name.localizedCaseInsensitiveContains(filterText) }
        return sort(items: filtered)
    }

    func loadDirectory() {
        isLoading = true
        let url = currentURL
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let fileManager = FileManager.default
            guard let urls = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .creationDateKey],
                options: [.skipsHiddenFiles]
            ) else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            var fileItems: [FileItem] = []
            for fileURL in urls {
                if let item = try? FileItem(url: fileURL) {
                    fileItems.append(item)
                }
            }

            DispatchQueue.main.async {
                self.items = fileItems
                self.isLoading = false
            }
        }
    }

    func navigate(to url: URL) {
        if historyIndex < history.count - 1 {
            history.removeSubrange((historyIndex + 1)...)
        }
        history.append(url)
        historyIndex = history.count - 1
        currentURL = url
        selectedItems.removeAll()
        loadDirectory()
    }

    func goBack() {
        guard canGoBack else { return }
        historyIndex -= 1
        currentURL = history[historyIndex]
        selectedItems.removeAll()
        loadDirectory()
    }

    func goForward() {
        guard canGoForward else { return }
        historyIndex += 1
        currentURL = history[historyIndex]
        selectedItems.removeAll()
        loadDirectory()
    }

    func goUp() {
        let parent = currentURL.deletingLastPathComponent()
        if parent.path != currentURL.path {
            navigate(to: parent)
        }
    }

    func openSelected() {
        guard let selectedId = selectedItems.first,
              let item = items.first(where: { $0.id == selectedId }) else { return }
        if item.isDirectory {
            navigate(to: item.url)
        } else {
            NSWorkspace.shared.open(item.url)
        }
    }

    func selectAll() {
        selectedItems = Set(filteredItems.map { $0.id })
    }

    func deselectAll() {
        selectedItems.removeAll()
    }

    func toggleSelection(for id: String) {
        if selectedItems.contains(id) {
            selectedItems.remove(id)
        } else {
            selectedItems.insert(id)
        }
    }

    private func sort(items: [FileItem]) -> [FileItem] {
        let sorted = items.sorted { a, b in
            if a.isDirectory != b.isDirectory {
                return a.isDirectory
            }
            switch sortColumn {
            case .name:
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            case .size:
                return a.size < b.size
            case .date:
                return a.modificationDate < b.modificationDate
            case .kind:
                return a.kind < b.kind
            }
        }
        return sortOrder == .ascending ? sorted : sorted.reversed()
    }
}
