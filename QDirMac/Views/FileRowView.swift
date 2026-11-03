import SwiftUI

struct FileRowView: View {
    let item: FileItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: item.icon)
                    .foregroundStyle(item.iconColor)
                    .frame(width: 18)
                Text(item.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)

            Text(item.formattedSize)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)

            Text(item.formattedDate)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)
                .padding(.leading, 8)

            Text(item.kind)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
                .lineLimit(1)
        }
        .font(.system(size: 12))
        .padding(.vertical, 3)
        .background(isSelected ? Color.accentColor.opacity(0.25) : Color.clear)
    }
}
