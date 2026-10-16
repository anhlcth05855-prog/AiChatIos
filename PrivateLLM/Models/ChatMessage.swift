import Foundation

public enum MessageSender: String, Codable, CaseIterable {
    case user
    case assistant
    case system
    case status
}

public struct ChatMessage: Identifiable, Codable, Equatable {
    public let id: UUID
    public var content: String
    public let sender: MessageSender
    public let timestamp: Date
    public var modelName: String?
    public var isStreaming: BooleanWrapper
    public var tokenCount: Int?
    public var generationDuration: Double?
    
    public init(
        id: UUID = UUID(),
        content: String,
        sender: MessageSender,
        timestamp: Date = Date(),
        modelName: String? = nil,
        isStreaming: Bool = false,
        tokenCount: Int? = nil,
        generationDuration: Double? = nil
    ) {
        self.id = id
        self.content = content
        self.sender = sender
        self.timestamp = timestamp
        self.modelName = modelName
        self.isStreaming = BooleanWrapper(isStreaming)
        self.tokenCount = tokenCount
        self.generationDuration = generationDuration
    }
    
    public var isUser: Bool {
        sender == .user
    }
    
    public var isAssistant: Bool {
        sender == .assistant
    }
    
    public var isStatus: Bool {
        sender == .status
    }
    
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

/// Helper wrapper for mutable boolean in Codable / SwiftUI
public struct BooleanWrapper: Codable, Equatable {
    public var value: Bool
    
    public init(_ value: Bool) {
        self.value = value
    }
}
