# QDirMac

Ein qDir-ähnlicher Dateibrowser für macOS mit bis zu 4 nebeneinander angeordneten Ordneransichten.

## Funktionen

- **1-4 Spalten**: Bis zu 4 Ordneransichten gleichzeitig nebeneinander (wie qDir)
- **Drag & Drop**: Dateien zwischen den Spalten kopieren
- **Favoriten-Leiste**: Schnellzugriff auf Home, Desktop, Dokumente, Downloads, Bilder, Musik, Programme + eigene Favoriten
- **Spalten-Sortierung**: Nach Name, Größe, Datum oder Art sortierbar
- **Filter**: Schneller Dateifilter pro Spalte
- **Navigation**: Vor/Zurück/Übergeordnet mit Verlauf
- **Kontextmenü**: Öffnen, Umbenennen, Kopieren, Verschieben, Löschen
- **Tastenkürzel**: Cmd+1-4 für Spaltenzahl, Cmd+A für Auswahl, Cmd+←/→ für Navigation

## Voraussetzungen

- macOS 14.0 (Sonoma) oder neuer
- Xcode 15+ oder Swift Toolchain

## Installation & Start

### Option 1: Mit Swift Package Manager (Terminal)

```bash
cd QDirMac
swift run QDirMac
```

### Option 2: In Xcode öffnen

1. Xcode öffnen
2. "Open a project or file..." wählen
3. Den Ordner `QDirMac` auswählen (die Package.swift wird erkannt)
4. Run drücken (Cmd+R)

### Option 3: Als .app exportieren

```bash
cd QDirMac
swift build -c release
# Die App liegt dann in .build/release/QDirMac
```

## Bedienung

| Aktion | Tastenkürzel |
|--------|-------------|
| 1-4 Spalten anzeigen | Cmd + 1/2/3/4 |
| Alle auswählen | Cmd + A |
| Auswahl aufheben | Cmd + Shift + A |
| Zurück | Cmd + ← |
| Vorwärts | Cmd + → |
| Übergeordneter Ordner | Cmd + ↑ |
| Öffnen | Enter |
| Löschen | Entf |

### Drag & Drop
Dateien aus einer Spalte in eine andere ziehen, um sie zu kopieren.

### Mehrfachauswahl
Cmd+klick auf Dateien für Mehrfachauswahl.

## Projektstruktur

```
QDirMac/
├── Package.swift
├── README.md
└── QDirMac/
    ├── QDirMacApp.swift          # App-Einstiegspunkt & Menüs
    ├── Models/
    │   ├── FileItem.swift        # Datei-/Ordner-Modell
    │   └── PaneState.swift       # Zustand einer Spalte
    ├── Views/
    │   ├── ContentView.swift     # Haupt-View
    │   ├── MultiPaneView.swift   # 1-4 Spalten Layout
    │   ├── FilePaneView.swift    # Einzelne Spalte
    │   ├── FileRowView.swift     # Dateizeile
    │   └── FavoritesBar.swift    # Favoriten-Leiste
    └── Resources/
        └── Info.plist
```
