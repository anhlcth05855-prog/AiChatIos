import Foundation

public final class CloudGeminiEngine {
    
    public static let shared = CloudGeminiEngine()
    
    private let session = URLSession(configuration: .default)
    
    public func generateContent(
        apiKey: String,
        model: String,
        prompt: String,
        systemInstruction: String?,
        history: [ChatMessage]
    ) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw NSError(domain: "GeminiError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Chưa cấu hình Gemini API Key"])
        }
        
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "GeminiError", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL API không hợp lệ"])
        }
        
        var contents: [[String: Any]] = []
        
        // Add conversation history for multi-turn context
        for msg in history.suffix(10) {
            let role = msg.isUser ? "user" : "model"
            contents.append([
                "role": role,
                "parts": [["text": msg.content]]
            ])
        }
        
        // Add current prompt
        contents.append([
            "role": "user",
            "parts": [["text": prompt]]
        ])
        
        var requestBody: [String: Any] = ["contents": contents]
        if let sys = systemInstruction, !sys.isEmpty {
            requestBody["systemInstruction"] = [
                "parts": [["text": sys]]
            ]
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GeminiError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Phản hồi không hợp lệ từ máy chủ"])
        }
        
        if httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Mã lỗi: \(httpResponse.statusCode)"
            throw NSError(domain: "GeminiError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw NSError(domain: "GeminiError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Không thể phân tích phản hồi JSON"])
        }
        
        return text
    }
}
