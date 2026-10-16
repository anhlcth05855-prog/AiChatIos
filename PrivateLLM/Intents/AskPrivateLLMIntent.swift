import Foundation
import AppIntents

public struct AskPrivateLLMIntent: AppIntent {
    public static var title: LocalizedStringResource = "Hỏi Private LLM (Offline)"
    public static var description = IntentDescription("Trò chuyện trực tiếp với AI chạy hoàn toàn offline trên thiết bị không cần mạng.")
    
    @Parameter(title: "Câu hỏi hoặc Lời nhắc", requestValueDialog: "Bạn muốn hỏi Private LLM điều gì?")
    public var prompt: String
    
    public init() {}
    
    public init(prompt: String) {
        self.prompt = prompt
    }
    
    public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let answer = OfflineKnowledgeEngine.shared.generateKnowledgeResponse(for: prompt)
        return .result(
            value: answer,
            dialog: IntentDialog(stringLiteral: answer)
        )
    }
}
