import Foundation

public struct ChatSession: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date
    public var modelId: String
    public var systemPrompt: String?
    public var temperature: Double
    public var isPinned: Bool
    public var messages: [ChatMessage]
    
    public init(
        id: UUID = UUID(),
        title: String = "Cuộc trò chuyện mới",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        modelId: String = "qwen3-1.7b",
        systemPrompt: String? = nil,
        temperature: Double = 0.7,
        isPinned: Bool = false,
        messages: [ChatMessage] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.modelId = modelId
        self.systemPrompt = systemPrompt
        self.temperature = temperature
        self.isPinned = isPinned
        self.messages = messages
    }
    
    public var lastMessagePreview: String {
        guard let last = messages.last(where: { !$0.content.isEmpty }) else {
            return "Chưa có tin nhắn nào"
        }
        let clean = last.content.replacingOccurrences(of: "\n", with: " ")
        if clean.count > 60 {
            return String(clean.prefix(60)) + "..."
        }
        return clean
    }
    
    public var messageCount: Int {
        messages.filter { $0.sender != .status }.count
    }
    
    public var formattedUpdatedAt: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(updatedAt) {
            let df = DateFormatter()
            df.dateFormat = "HH:mm"
            return df.string(from: updatedAt)
        } else if calendar.isDateInYesterday(updatedAt) {
            return "Hôm qua"
        } else {
            let df = DateFormatter()
            df.dateFormat = "dd/MM"
            return df.string(from: updatedAt)
        }
    }
    
    public func matches(query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return true }
        if title.lowercased().contains(q) { return true }
        return messages.contains { $0.content.lowercased().contains(q) }
    }
}
