import Foundation

public final class CloudOpenAIEngine {
    
    public static let shared = CloudOpenAIEngine()
    
    private let session = URLSession(configuration: .default)
    
    public func createChatCompletion(
        apiKey: String,
        model: String,
        prompt: String,
        systemInstruction: String?,
        history: [ChatMessage]
    ) async throws -> String {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespaces)
        guard !cleanKey.isEmpty else {
            throw NSError(domain: "OpenAIError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Chưa cấu hình OpenAI API Key"])
        }
        
        let endpoint = "https://api.openai.com/v1/chat/completions"
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "OpenAIError", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL API không hợp lệ"])
        }
        
        var messages: [[String: String]] = []
        
        if let sys = systemInstruction, !sys.isEmpty {
            messages.append(["role": "system", "content": sys])
        }
        
        for msg in history.suffix(10) {
            let role = msg.isUser ? "user" : "assistant"
            messages.append(["role": role, "content": msg.content])
        }
        
        messages.append(["role": "user", "content": prompt])
        
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let authHeader = cleanKey.hasPrefix("Bearer ") ? cleanKey : "Bearer \(cleanKey)"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OpenAIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Phản hồi không hợp lệ từ máy chủ"])
        }
        
        if httpResponse.statusCode != 200 {
            let errString = String(data: data, encoding: .utf8) ?? "Mã lỗi: \(httpResponse.statusCode)"
            throw NSError(domain: "OpenAIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errString])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "OpenAIError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Không thể phân tích phản hồi JSON"])
        }
        
        return content
    }
}
