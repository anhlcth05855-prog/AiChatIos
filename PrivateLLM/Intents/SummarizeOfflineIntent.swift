import Foundation
import AppIntents

public struct SummarizeOfflineIntent: AppIntent {
    public static var title: LocalizedStringResource = "Tóm Tắt Văn Bản với Private LLM"
    public static var description = IntentDescription("Tóm tắt nhanh đoạn văn bản hoặc bài báo offline bảo mật tuyệt đối.")
    
    @Parameter(title: "Nội dung văn bản", requestValueDialog: "Dán văn bản bạn muốn tóm tắt vào đây:")
    public var inputText: String
    
    public init() {}
    
    public init(inputText: String) {
        self.inputText = inputText
    }
    
    public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let clean = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary: String
        
        if clean.isEmpty {
            summary = "Văn bản rỗng, vui lòng cung cấp nội dung cần tóm tắt."
        } else {
            let prompt = "Hãy tóm tắt ngắn gọn các ý chính của đoạn văn bản sau bằng các gạch đầu dòng:\n\n\(clean)"
            summary = OfflineKnowledgeEngine.shared.generateKnowledgeResponse(for: prompt)
        }
        
        return .result(
            value: summary,
            dialog: IntentDialog(stringLiteral: summary)
        )
    }
}
