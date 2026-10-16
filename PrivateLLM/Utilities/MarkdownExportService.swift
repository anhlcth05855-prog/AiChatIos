import Foundation

public final class MarkdownExportService {
    
    public static func generateMarkdown(from session: ChatSession) -> URL? {
        let modelName = ModelCatalog.model(for: session.modelId)?.name ?? session.modelId
        
        var md = """
        # \(session.title)
        
        > **Ứng dụng**: Private LLM - Local AI Chat (Apple Silicon)
        > **Mô hình**: \(modelName)
        > **Ngày tạo**: \(session.createdAt.description)
        > **Trạng thái**: 100% On-Device & Offline Private Export
        
        ---
        
        """
        
        for msg in session.messages where msg.sender != .status {
            let role = msg.isUser ? "### 👤 Bạn" : "### 🤖 Private LLM (\(msg.modelName ?? modelName))"
            md += "\n\(role) *[\(msg.formattedTime)]*\n\n\(msg.content)\n\n"
        }
        
        let fileName = "PrivateLLM_\(session.title.replacingOccurrences(of: " ", with: "_")).md"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try md.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("[MarkdownExportService] Markdown export error: \(error)")
            return nil
        }
    }
}
