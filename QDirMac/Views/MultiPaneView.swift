import SwiftUI

final class KeyboardCoordinator {
    var panes: [PaneState] = []
    var activePaneIndex: Int = 0
}

struct MultiPaneView: View {
    @State private var panes: [PaneState] = [PaneState()]
    @State private var activePaneIndex: Int = 0
    @State private var showingFavorites = true
    @State private var keyMonitor: Any? = nil
    private let coordinator = KeyboardCoordinator()

    let maxPanes = 4

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            if showingFavorites {
                FavoritesBar(panes: $panes)
                Divider()
            }
            Divider()
            panesView
        }
        .onAppear { installKeyMonitor() }
        .onChange(of: panes) { _, newPanes in coordinator.panes = newPanes }
        .onChange(of: activePaneIndex) { _, newIndex in coordinator.activePaneIndex = newIndex }
        .onDisappear {
            if let monitor = keyMonitor {
                NSEvent.removeMonitor(monitor)
                keyMonitor = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .setPaneCount)) { notification in
            if let count = notification.object as? Int {
                setPaneCount(count)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectAll)) { _ in
            panes.first?.selectAll()
        }
        .onReceive(NotificationCenter.default.publisher(for: .deselectAll)) { _ in
            panes.first?.deselectAll()
        }
        .onReceive(NotificationCenter.default.publisher(for: .goBack)) { _ in
            panes.first?.goBack()
        }
        .onReceive(NotificationCenter.default.publisher(for: .goForward)) { _ in
            panes.first?.goForward()
        }
        .onReceive(NotificationCenter.default.publisher(for: .goUp)) { _ in
            panes.first?.goUp()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSelected)) { _ in
            panes.first?.openSelected()
        }
        .onReceive(NotificationCenter.default.publisher(for: .deleteSelected)) { _ in
            if let pane = panes.first {
                let items = pane.items.filter { pane.selectedItems.contains($0.id) }
                for item in items {
                    try? FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
                }
                pane.loadDirectory()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .revealInFinder)) { _ in
            if let pane = panes.first,
               let selectedId = pane.selectedItems.first,
               let item = pane.items.first(where: { $0.id == selectedId }) {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Text("QDirMac")
                .font(.headline)
                .foregroundStyle(.primary)

            Divider()
                .frame(height: 20)

            HStack(spacing: 4) {
                ForEach(1...maxPanes, id: \.self) { count in
                    Button(action: { setPaneCount(count) }) {
                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(panes.count == count ? .bold : .regular)
                            .foregroundStyle(panes.count == count ? .white : .primary)
                            .frame(width: 28, height: 22)
                            .background(panes.count == count ? Color.accentColor : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                    .help("\(count) Spalte\(count > 1 ? "n" : "") anzeigen")
                }
            }

            Spacer()

            Button(action: { showingFavorites.toggle() }) {
                Image(systemName: showingFavorites ? "star.fill" : "star")
            }
            .buttonStyle(.borderless)
            .help("Favoriten ein-/ausblenden")

            Button(action: { addPane() }) {
                Image(systemName: "plus.rectangle.on.rectangle")
            }
            .buttonStyle(.borderless)
            .disabled(panes.count >= maxPanes)
            .help("Neue Spalte hinzufügen")

            if panes.count > 1 {
                Button(action: { removePane() }) {
                    Image(systemName: "minus.rectangle")
                }
                .buttonStyle(.borderless)
                .help("Spalte entfernen")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var panesView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 0) {
                ForEach(Array(panes.enumerated()), id: \.element.id) { index, pane in
                    FilePaneView(
                        pane: pane,
                        paneIndex: index,
                        totalPanes: panes.count,
                        isActive: index == activePaneIndex,
                        onActivate: { activePaneIndex = index },
                        onDrop: { items, targetPane in
                            drop(items: items, into: targetPane)
                        }
                    )
                    .frame(minWidth: 320)
                    if index < panes.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        coordinator.panes = panes
        coordinator.activePaneIndex = activePaneIndex
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [coordinator] event in
            guard coordinator.activePaneIndex < coordinator.panes.count else { return event }
            let pane = coordinator.panes[coordinator.activePaneIndex]
            let items = pane.filteredItems
            switch event.keyCode {
            case 126 where !items.isEmpty: // up arrow
                let current = items.firstIndex { pane.selectedItems.contains($0.id) } ?? items.count
                let newIndex = min(max(current - 1, 0), items.count - 1)
                pane.selectedItems = [items[newIndex].id]
                return nil
            case 125 where !items.isEmpty: // down arrow
                let current = items.firstIndex { pane.selectedItems.contains($0.id) } ?? -1
                let newIndex = min(max(current + 1, 0), items.count - 1)
                pane.selectedItems = [items[newIndex].id]
                return nil
            case 36, 76: // return / enter
                pane.openSelected()
                return nil
            default:
                return event
            }
        }
    }

    private func setPaneCount(_ count: Int) {
        if count > panes.count {
            while panes.count < count {
                let newPane = PaneState(url: panes.last?.currentURL ?? FileManager.default.homeDirectoryForCurrentUser)
                panes.append(newPane)
            }
        } else if count < panes.count {
            panes.removeLast(panes.count - count)
        }
        if activePaneIndex >= panes.count {
            activePaneIndex = panes.count - 1
        }
    }

    private func addPane() {
        guard panes.count < maxPanes else { return }
        let url = panes.last?.currentURL ?? FileManager.default.homeDirectoryForCurrentUser
        panes.append(PaneState(url: url))
    }

    private func removePane() {
        guard panes.count > 1 else { return }
        panes.removeLast()
        if activePaneIndex >= panes.count {
            activePaneIndex = panes.count - 1
        }
    }

    private func drop(items: [FileItem], into targetPane: PaneState) {
        let destination = targetPane.currentURL
        for item in items {
            guard item.url.deletingLastPathComponent() != destination else { continue }
            let dest = destination.appendingPathComponent(item.name)
            if FileManager.default.fileExists(atPath: dest.path) {
                let alert = NSAlert()
                alert.messageText = "Datei existiert bereits"
                alert.informativeText = "\(item.name) existiert bereits in \(destination.lastPathComponent). Ersetzen?"
                alert.addButton(withTitle: "Ersetzen")
                alert.addButton(withTitle: "Überspringen")
                if alert.runModal() == .alertFirstButtonReturn {
                    try? FileManager.default.removeItem(at: dest)
                    try? FileManager.default.copyItem(at: item.url, to: dest)
                }
            } else {
                try? FileManager.default.copyItem(at: item.url, to: dest)
            }
        }
        targetPane.loadDirectory()
        for pane in panes where pane.currentURL == items.first?.url.deletingLastPathComponent() {
            pane.loadDirectory()
        }
    }
}
