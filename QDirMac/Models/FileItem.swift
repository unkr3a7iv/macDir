import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct FileItem: Identifiable, Hashable {
    let id: String
    let name: String
    let url: URL
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date
    let creationDate: Date
    let fileExtension: String
    let kind: String

    init(url: URL) {
        self.id = url.path
        self.url = url
        self.name = url.lastPathComponent

        let resourceValues = try? url.resourceValues(forKeys: [
            .isDirectoryKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .creationDateKey,
            .typeIdentifierKey
        ])

        self.isDirectory = resourceValues?.isDirectory ?? false
        self.size = Int64(resourceValues?.fileSize ?? 0)
        self.modificationDate = resourceValues?.contentModificationDate ?? Date()
        self.creationDate = resourceValues?.creationDate ?? Date()
        self.fileExtension = url.pathExtension
        self.kind = Self.kind(for: url, isDirectory: self.isDirectory)
    }

    var icon: String {
        if isDirectory {
            return "folder.fill"
        }
        return Self.systemIcon(for: fileExtension)
    }

    var iconColor: Color {
        if isDirectory {
            return .blue
        }
        switch fileExtension.lowercased() {
        case "jpg", "jpeg", "png", "gif", "heic", "tiff", "bmp", "svg":
            return .green
        case "mp4", "mov", "avi", "mkv":
            return .purple
        case "mp3", "wav", "aac", "flac", "m4a":
            return .pink
        case "pdf":
            return .red
        case "zip", "tar", "gz", "rar", "7z":
            return .orange
        case "swift", "py", "js", "ts", "html", "css", "json", "xml", "md":
            return .cyan
        case "doc", "docx", "txt", "rtf":
            return .gray
        case "xls", "xlsx", "csv", "numbers":
            return .green
        default:
            return .secondary
        }
    }

    var formattedSize: String {
        if isDirectory { return "--" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: modificationDate)
    }

    static func kind(for url: URL, isDirectory: Bool) -> String {
        if isDirectory { return "Ordner" }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "gif", "heic", "tiff", "bmp", "svg", "webp":
            return "Bild"
        case "mp4", "mov", "avi", "mkv", "m4v":
            return "Video"
        case "mp3", "wav", "aac", "flac", "m4a", "ogg":
            return "Audio"
        case "pdf":
            return "PDF-Dokument"
        case "zip", "tar", "gz", "rar", "7z", "dmg":
            return "Archiv"
        case "swift", "py", "js", "ts", "html", "css", "json", "xml", "c", "cpp", "h", "java", "rs", "go":
            return "Quellcode"
        case "doc", "docx", "pages", "txt", "rtf", "odt":
            return "Dokument"
        case "xls", "xlsx", "numbers", "csv":
            return "Tabelle"
        case "ppt", "pptx", "key":
            return "Präsentation"
        case "app":
            return "Programm"
        default:
            return ext.isEmpty ? "Datei" : ext.uppercased() + "-Datei"
        }
    }

    static func systemIcon(for ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg", "png", "gif", "heic", "tiff", "bmp", "svg", "webp":
            return "photo.fill"
        case "mp4", "mov", "avi", "mkv":
            return "film.fill"
        case "mp3", "wav", "aac", "flac", "m4a":
            return "music.note"
        case "pdf":
            return "doc.fill"
        case "zip", "tar", "gz", "rar", "7z":
            return "doc.zipper"
        case "swift", "py", "js", "ts", "html", "css", "json":
            return "chevron.left.forwardslash.chevron.right"
        case "doc", "docx", "txt", "rtf":
            return "doc.text.fill"
        case "xls", "xlsx", "csv":
            return "tablecells.fill"
        case "app":
            return "app.fill"
        default:
            return "doc.fill"
        }
    }
}

enum SortColumn: String, CaseIterable {
    case name = "Name"
    case size = "Größe"
    case date = "Datum"
    case kind = "Art"

    var icon: String {
        switch self {
        case .name: return "textformat"
        case .size: return "arrow.up.arrow.down"
        case .date: return "calendar"
        case .kind: return "tag"
        }
    }
}

enum SortOrder {
    case ascending, descending
}
