import SwiftUI

struct FavoriteFolder: Identifiable, Codable {
    let id: UUID
    let name: String
    let path: String

    init(name: String, path: String) {
        self.id = UUID()
        self.name = name
        self.path = path
    }

    var url: URL { URL(fileURLWithPath: path) }
}

struct FavoritesBar: View {
    @Binding var panes: [PaneState]
    @AppStorage("favoriteFolders") private var favoritesData: Data = Data()
    @State private var favorites: [FavoriteFolder] = []
    @State private var showingAddDialog = false
    @State private var newFavoriteName = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                standardFavorites
                ForEach(favorites) { fav in
                    FavoriteButton(
                        name: fav.name,
                        icon: "star.fill",
                        action: { navigateToFavorite(fav) }
                    )
                    .contextMenu {
                        Button("Entfernen", role: .destructive) {
                            removeFavorite(fav)
                        }
                    }
                }
                Button(action: { showingAddDialog = true }) {
                    Label("Hinzufügen", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { loadFavorites() }
        .alert("Favorit hinzufügen", isPresented: $showingAddDialog) {
            TextField("Name", text: $newFavoriteName)
            Button("Aktuellen Ordner") {
                if let firstPane = panes.first {
                    addFavorite(name: newFavoriteName.isEmpty ? firstPane.currentURL.lastPathComponent : newFavoriteName,
                               path: firstPane.currentURL.path)
                    newFavoriteName = ""
                }
            }
            Button("Abbrechen", role: .cancel) {
                newFavoriteName = ""
            }
        } message: {
            Text("Name für den Favoriten eingeben")
        }
    }

    private var standardFavorites: some View {
        Group {
            FavoriteButton(name: "Home", icon: "house.fill") {
                navigate(to: FileManager.default.homeDirectoryForCurrentUser)
            }
            FavoriteButton(name: "Desktop", icon: "display") {
                navigate(to: FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!)
            }
            FavoriteButton(name: "Dokumente", icon: "doc.text.fill") {
                navigate(to: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!)
            }
            FavoriteButton(name: "Downloads", icon: "arrow.down.circle.fill") {
                navigate(to: FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!)
            }
            FavoriteButton(name: "Bilder", icon: "photo.fill") {
                navigate(to: FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!)
            }
            FavoriteButton(name: "Musik", icon: "music.note") {
                navigate(to: FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first!)
            }
            FavoriteButton(name: "Programme", icon: "app.fill") {
                navigate(to: URL(fileURLWithPath: "/Applications"))
            }
        }
    }

    private func navigate(to url: URL) {
        guard let firstPane = panes.first else { return }
        firstPane.navigate(to: url)
    }

    private func navigateToFavorite(_ fav: FavoriteFolder) {
        navigate(to: fav.url)
    }

    private func addFavorite(name: String, path: String) {
        let fav = FavoriteFolder(name: name, path: path)
        favorites.append(fav)
        saveFavorites()
    }

    private func removeFavorite(_ fav: FavoriteFolder) {
        favorites.removeAll { $0.id == fav.id }
        saveFavorites()
    }

    private func loadFavorites() {
        if let decoded = try? JSONDecoder().decode([FavoriteFolder].self, from: favoritesData) {
            favorites = decoded
        }
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            favoritesData = encoded
        }
    }
}

struct FavoriteButton: View {
    let name: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.borderless)
    }
}
