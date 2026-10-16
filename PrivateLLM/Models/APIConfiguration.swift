import Foundation

public enum AIProviderType: String, Codable, CaseIterable, Identifiable {
    case privateLLM = "private_llm"
    case mockOffline = "mock_offline"
    case googleGemini = "gemini"
    case openAI = "openai"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .privateLLM:
            return "Private LLM (100% On-Device)"
        case .mockOffline:
            return "Mock AI Engine (Offline tích hợp)"
        case .googleGemini:
            return "Google Gemini Cloud API"
        case .openAI:
            return "OpenAI Cloud API"
        }
    }
    
    public var badgeIcon: String {
        switch self {
        case .privateLLM: return "lock.shield.fill"
        case .mockOffline: return "bolt.fill"
        case .googleGemini: return "cloud.fill"
        case .openAI: return "network"
        }
    }
    
    public var isCloud: Bool {
        self == .googleGemini || self == .openAI
    }
}

public struct AppConfiguration: Codable {
    public var selectedProvider: AIProviderType
    public var activeModelId: String
    public var systemPrompt: String
    public var appLanguage: String // "vi", "en", "zh", "ja", "ko", "fr"
    public var temperature: Double
    public var topP: Double
    public var maxTokens: Int
    public var hapticsEnabled: Bool
    public var ttsAutoSpeak: Bool
    public var geminiApiKey: String
    public var geminiModel: String
    public var openAiApiKey: String
    public var openAiModel: String
    public var isLifetimeUnlocked: Bool
    
    public static var `default`: AppConfiguration {
        AppConfiguration(
            selectedProvider: .privateLLM,
            activeModelId: "qwen3-1.7b",
            systemPrompt: "Bạn là Private LLM - trợ lý AI thông minh, thân thiện, bảo mật chạy 100% Offline trên iPhone/iPad.",
            appLanguage: "vi",
            temperature: 0.7,
            topP: 0.9,
            maxTokens: 2048,
            hapticsEnabled: true,
            ttsAutoSpeak: false,
            geminiApiKey: "",
            geminiModel: "gemini-1.5-flash",
            openAiApiKey: "",
            openAiModel: "gpt-4o-mini",
            isLifetimeUnlocked: true
        )
    }
}
