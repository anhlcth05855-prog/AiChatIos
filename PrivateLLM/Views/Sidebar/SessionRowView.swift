import SwiftUI

public struct SessionRowView: View {
    public let session: ChatSession
    public let isSelected: Bool
    public let onSelect: () -> Void
    public let onPin: () -> Void
    public let onRename: () -> Void
    public let onDuplicate: () -> Void
    public let onDelete: () -> Void
    
    public init(
        session: ChatSession,
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        onPin: @escaping () -> Void,
        onRename: @escaping () -> Void,
        onDuplicate: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.session = session
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onPin = onPin
        self.onRename = onRename
        self.onDuplicate = onDuplicate
        self.onDelete = onDelete
    }
    
    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Pin Indicator / Leading Icon
                Image(systemName: session.isPinned ? "pin.fill" : "bubble.left.and.bubble.right")
                    .font(.system(size: 14, weight: session.isPinned ? .bold : .regular))
                    .foregroundColor(session.isPinned ? .orange : (isSelected ? .accentColor : .secondary))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(session.title)
                            .font(.system(size: 14.5, weight: isSelected ? .semibold : .medium))
                            .foregroundColor(isSelected ? .accentColor : .primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(session.formattedUpdatedAt)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(session.lastMessagePreview)
                        .font(.system(size: 12.5))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: onPin) {
                Label(session.isPinned ? "Bỏ ghim" : "Ghim lên đầu", systemImage: session.isPinned ? "pin.slash" : "pin")
            }
            Button(action: onRename) {
                Label("Đổi tên", systemImage: "pencil")
            }
            Button(action: onDuplicate) {
                Label("Tạo bản sao", systemImage: "doc.on.doc")
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Xóa đoạn chat", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button(action: onPin) {
                Label(session.isPinned ? "Bỏ ghim" : "Ghim", systemImage: session.isPinned ? "pin.slash" : "pin")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Xóa", systemImage: "trash")
            }
            Button(action: onRename) {
                Label("Đổi tên", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}
