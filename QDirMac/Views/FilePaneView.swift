import SwiftUI
import UniformTypeIdentifiers

struct FilePaneView: View {
    @Bindable var pane: PaneState
    let paneIndex: Int
    let totalPanes: Int
    let onDrop: ([FileItem], PaneState) -> Void
    let onOpenPane: (Int) -> Void

    @State private var isTargeted = false
    @State private var keyboardActive = false
    @State private var keyMonitor: Any? = nil

    var body: some View {
        VStack(spacing: 0) {
            paneHeader
            Divider()
            fileList
            Divider()
            paneFooter
        }
        .background(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
        .onTapGesture { activateKeyboard() }
        .onAppear { activateKeyboard() }
        .onDisappear {
            if let monitor = keyMonitor {
                NSEvent.removeMonitor(monitor)
                keyMonitor = nil
            }
        }
        .dropDestination(for: URL.self, action: { urls, _ in
            handleDrop(urls: urls)
            return true
        }, isTargeted: { targeted in
            isTargeted = targeted
        })
    }

    private func activateKeyboard() {
        guard keyMonitor == nil else { return }
        keyboardActive = true
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [pane] event in
            let items = pane.filteredItems
            guard !items.isEmpty else { return event }
            let currentIndex = items.firstIndex { pane.selectedItems.contains($0.id) } ?? (event.keyCode == 125 ? -1 : items.count)
            switch event.keyCode {
            case 126: // up arrow
                let newIndex = min(max(currentIndex - 1, 0), items.count - 1)
                pane.selectedItems = [items[newIndex].id]
                return nil
            case 125: // down arrow
                let newIndex = min(max(currentIndex + 1, 0), items.count - 1)
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

    private func moveSelection(delta: Int) {
        let items = pane.filteredItems
        guard !items.isEmpty else { return }
        let currentIndex = items.firstIndex { pane.selectedItems.contains($0.id) } ?? (delta > 0 ? -1 : items.count)
        let newIndex = min(max(currentIndex + delta, 0), items.count - 1)
        pane.selectedItems = [items[newIndex].id]
    }

    private var paneHeader: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Button(action: { pane.goBack() }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!pane.canGoBack)
                .buttonStyle(.borderless)

                Button(action: { pane.goForward() }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!pane.canGoForward)
                .buttonStyle(.borderless)

                Button(action: { pane.goUp() }) {
                    Image(systemName: "arrow.up")
                }
                .buttonStyle(.borderless)
                .help("Übergeordneter Ordner")

                pathField

                Button(action: { pane.loadDirectory() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Aktualisieren")
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Filter...", text: $pane.filterText)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                if !pane.filterText.isEmpty {
                    Button(action: { pane.filterText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var pathField: some View {
        HStack(spacing: 4) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.blue)
                .font(.caption)
            Text(pane.currentURL.path)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onTapGesture {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(pane.currentURL.path, forType: .string)
        }
        .help("Klicken zum Kopieren des Pfads")
    }

    private var fileList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0) {
                    columnHeader
                    Divider()
                    if pane.isLoading {
                        ProgressView()
                            .padding()
                    } else if pane.filteredItems.isEmpty {
                        emptyState
                    } else {
                        ForEach(pane.filteredItems) { item in
                            FileRowView(
                                item: item,
                                isSelected: pane.selectedItems.contains(item.id)
                            )
                            .id(item.id)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                if item.isDirectory {
                                    pane.navigate(to: item.url)
                                } else {
                                    NSWorkspace.shared.open(item.url)
                                }
                            }
                            .onTapGesture {
                                if NSEvent.modifierFlags.contains(.command) {
                                    pane.toggleSelection(for: item.id)
                                } else {
                                    pane.selectedItems = [item.id]
                                    keyboardActive = true
                                }
                            }
                            .contextMenu {
                                fileContextMenu(for: item)
                            }
                            .draggable(item.url) {
                                HStack(spacing: 4) {
                                    Image(systemName: item.icon)
                                        .foregroundStyle(item.iconColor)
                                    Text(item.name)
                                }
                                .padding(4)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            Divider()
                        }
                    }
                }
            }
            .onChange(of: pane.selectedItems) { _, newSelection in
                if let selectedId = newSelection.first {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(selectedId, anchor: .center)
                    }
                }
            }
        }
    }

    private var columnHeader: some View {
        HStack(spacing: 0) {
            Button(action: { toggleSort(.name) }) {
                headerLabel(.name, flexible: true)
            }
            .buttonStyle(.plain)
            Button(action: { toggleSort(.size) }) {
                headerLabel(.size, width: 80, alignment: .trailing)
            }
            .buttonStyle(.plain)
            Button(action: { toggleSort(.date) }) {
                headerLabel(.date, width: 140)
            }
            .buttonStyle(.plain)
            Button(action: { toggleSort(.kind) }) {
                headerLabel(.kind, width: 90)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func toggleSort(_ column: SortColumn) {
        if pane.sortColumn == column {
            pane.sortOrder = pane.sortOrder == .ascending ? .descending : .ascending
        } else {
            pane.sortColumn = column
            pane.sortOrder = .ascending
        }
    }

    private func headerLabel(_ column: SortColumn, width: CGFloat? = nil, flexible: Bool = false, alignment: Alignment = .leading) -> some View {
        HStack(spacing: 4) {
            Text(column.rawValue)
            if pane.sortColumn == column {
                Image(systemName: pane.sortOrder == .ascending ? "chevron.up" : "chevron.down")
                    .font(.system(size: 8))
            }
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(pane.sortColumn == column ? .primary : .secondary)
        .frame(minWidth: width ?? 120, maxWidth: flexible ? .infinity : width, alignment: alignment)
        .padding(.leading, 8)
        .contentShape(Rectangle())
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: pane.filterText.isEmpty ? "folder" : "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(pane.filterText.isEmpty ? "Ordner ist leer" : "Keine Ergebnisse")
                .foregroundStyle(.secondary)
        }
        .padding(40)
    }

    private var paneFooter: some View {
        HStack {
            Text("\(pane.filteredItems.count) Objekte")
                .font(.caption)
                .foregroundStyle(.secondary)
            if !pane.selectedItems.isEmpty {
                Text("• \(pane.selectedItems.count) ausgewählt")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
            Spacer()
            Text("Spalte \(paneIndex + 1) von \(totalPanes)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func handleDrop(urls: [URL]) {
        let droppedItems = urls.compactMap { FileItem(url: $0) }
        onDrop(droppedItems, pane)
    }

    @ViewBuilder
    private func fileContextMenu(for item: FileItem) -> some View {
        Button("Öffnen") {
            if item.isDirectory {
                pane.navigate(to: item.url)
            } else {
                NSWorkspace.shared.open(item.url)
            }
        }
        Button("Im Finder zeigen") {
            NSWorkspace.shared.activateFileViewerSelecting([item.url])
        }
        Divider()
        Button("Umbenennen...") {
            renameItem(item)
        }
        Button("Kopieren") {
            copyItems([item])
        }
        Button("In anderen Ordner verschieben...") {
            moveItems([item])
        }
        Divider()
        Button("In den Papierkorb legen", role: .destructive) {
            deleteItems([item])
        }
    }

    private func renameItem(_ item: FileItem) {
        let alert = NSAlert()
        alert.messageText = "Umbenennen"
        alert.informativeText = "Neuer Name für \(item.name):"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        field.stringValue = item.name
        alert.accessoryView = field
        alert.addButton(withTitle: "Umbenennen")
        alert.addButton(withTitle: "Abbrechen")
        if alert.runModal() == .alertFirstButtonReturn {
            let newName = field.stringValue.trimmingCharacters(in: .whitespaces)
            guard !newName.isEmpty, newName != item.name else { return }
            let newURL = item.url.deletingLastPathComponent().appendingPathComponent(newName)
            try? FileManager.default.moveItem(at: item.url, to: newURL)
            pane.loadDirectory()
        }
    }

    private func copyItems(_ items: [FileItem]) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects(items.map { $0.url as NSURL })
    }

    private func moveItems(_ items: [FileItem]) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Zielordner wählen"
        if panel.runModal() == .OK, let target = panel.url {
            for item in items {
                let dest = target.appendingPathComponent(item.name)
                try? FileManager.default.moveItem(at: item.url, to: dest)
            }
            pane.loadDirectory()
        }
    }

    private func deleteItems(_ items: [FileItem]) {
        for item in items {
            try? FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
        }
        pane.loadDirectory()
    }
}
