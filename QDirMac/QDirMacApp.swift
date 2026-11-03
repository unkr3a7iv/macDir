import SwiftUI

@main
struct QDirMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 480, minHeight: 320)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Neues Fenster") {
                    openNewWindow()
                }
                .keyboardShortcut("n")
            }
            CommandMenu("Ansicht") {
                Button("1 Spalte") { NotificationCenter.default.post(name: .setPaneCount, object: 1) }
                    .keyboardShortcut("1", modifiers: [.command])
                Button("2 Spalten") { NotificationCenter.default.post(name: .setPaneCount, object: 2) }
                    .keyboardShortcut("2", modifiers: [.command])
                Button("3 Spalten") { NotificationCenter.default.post(name: .setPaneCount, object: 3) }
                    .keyboardShortcut("3", modifiers: [.command])
                Button("4 Spalten") { NotificationCenter.default.post(name: .setPaneCount, object: 4) }
                    .keyboardShortcut("4", modifiers: [.command])
                Divider()
                Button("Alle auswählen") { NotificationCenter.default.post(name: .selectAll, object: nil) }
                    .keyboardShortcut("a", modifiers: [.command])
                Button("Auswahl aufheben") { NotificationCenter.default.post(name: .deselectAll, object: nil) }
                    .keyboardShortcut("a", modifiers: [.command, .shift])
                Divider()
                Button("Zurück") { NotificationCenter.default.post(name: .goBack, object: nil) }
                    .keyboardShortcut(.leftArrow, modifiers: [.command])
                Button("Vorwärts") { NotificationCenter.default.post(name: .goForward, object: nil) }
                    .keyboardShortcut(.rightArrow, modifiers: [.command])
                Button("Übergeordneter Ordner") { NotificationCenter.default.post(name: .goUp, object: nil) }
                    .keyboardShortcut(.upArrow, modifiers: [.command])
            }
            CommandMenu("Datei") {
                Button("Öffnen") { NotificationCenter.default.post(name: .openSelected, object: nil) }
                    .keyboardShortcut(.return)
                Divider()
                Button("Im Finder zeigen") { NotificationCenter.default.post(name: .revealInFinder, object: nil) }
                Button("In den Papierkorb") { NotificationCenter.default.post(name: .deleteSelected, object: nil) }
                    .keyboardShortcut(.delete)
            }
        }
    }

    private func openNewWindow() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "") {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

extension Notification.Name {
    static let setPaneCount = Notification.Name("setPaneCount")
    static let selectAll = Notification.Name("selectAll")
    static let deselectAll = Notification.Name("deselectAll")
    static let goBack = Notification.Name("goBack")
    static let goForward = Notification.Name("goForward")
    static let goUp = Notification.Name("goUp")
    static let openSelected = Notification.Name("openSelected")
    static let revealInFinder = Notification.Name("revealInFinder")
    static let deleteSelected = Notification.Name("deleteSelected")
}
