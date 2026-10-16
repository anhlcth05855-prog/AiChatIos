import Foundation

public final class ChatStorageRepository: ObservableObject {
    
    public static let shared = ChatStorageRepository()
    
    @Published public var sessions: [ChatSession] = []
    
    private let fileManager = FileManager.default
    private let storageFileName = "private_llm_sessions.json"
    
    private var storageFileURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(storageFileName)
    }
    
    private init() {
        loadSessions()
    }
    
    public func loadSessions() {
        guard fileManager.fileExists(atPath: storageFileURL.path) else {
            createInitialSession()
            return
        }
        
        do {
            let data = try Data(contentsOf: storageFileURL)
            let decoded = try JSONDecoder().decode([ChatSession].self, from: data)
            if decoded.isEmpty {
                createInitialSession()
            } else {
                self.sessions = decoded.sorted {
                    if $0.isPinned != $1.isPinned {
                        return $0.isPinned && !$1.isPinned
                    }
                    return $0.updatedAt > $1.updatedAt
                }
            }
        } catch {
            print("[ChatStorageRepository] Load error: \(error)")
            createInitialSession()
        }
    }
    
    public func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: storageFileURL, options: .atomic)
        } catch {
            print("[ChatStorageRepository] Save error: \(error)")
        }
    }
    
    @discardableResult
    public func createSession(
        title: String = "Cuộc trò chuyện mới",
        modelId: String = "qwen3-1.7b",
        systemPrompt: String? = nil
    ) -> ChatSession {
        let newSession = ChatSession(
            title: title,
            modelId: modelId,
            systemPrompt: systemPrompt,
            messages: []
        )
        sessions.insert(newSession, at: 0)
        saveSessions()
        return newSession
    }
    
    public func updateSession(_ session: ChatSession) {
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            var updated = session
            updated.updatedAt = Date()
            sessions[idx] = updated
            sortSessions()
            saveSessions()
        }
    }
    
    public func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        if sessions.isEmpty {
            createInitialSession()
        } else {
            saveSessions()
        }
    }
    
    public func togglePin(for id: UUID) {
        if let idx = sessions.firstIndex(where: { $0.id == id }) {
            sessions[idx].isPinned.toggle()
            sortSessions()
            saveSessions()
        }
    }
    
    public func duplicateSession(id: UUID) {
        guard let original = sessions.first(where: { $0.id == id }) else { return }
        let copy = ChatSession(
            title: "\(original.title) (Bản sao)",
            modelId: original.modelId,
            systemPrompt: original.systemPrompt,
            temperature: original.temperature,
            isPinned: false,
            messages: original.messages
        )
        sessions.insert(copy, at: 0)
        saveSessions()
    }
    
    public func clearAllHistory() {
        sessions.removeAll()
        createInitialSession()
    }
    
    public func searchSessions(query: String) -> [ChatSession] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return sessions }
        return sessions.filter { $0.matches(query: q) }
    }
    
    private func sortSessions() {
        sessions.sort {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            return $0.updatedAt > $1.updatedAt
        }
    }
    
    private func createInitialSession() {
        let welcome = ChatMessage(
            content: """
            Xin chào! Tôi là **Private LLM** - Trợ lý AI chạy **100% On-Device & Offline** trên chip Apple Silicon của bạn 🔒
            
            • **100% Cục bộ & Bảo mật**: Không có bất kỳ dữ liệu, câu hỏi hay lịch sử trò chuyện nào bị gửi lên đám mây.
            • **Không phụ thuộc Internet**: Hoạt động mượt mà ở bất cứ đâu (trên máy bay, vùng không có sóng).
            • **Đa dạng mô hình**: Tự động nhận diện mô hình AI riêng biệt cho từng cuộc trò chuyện.
            
            Hãy gõ câu hỏi hoặc chạm vào các gợi ý bên dưới để bắt đầu!
            """,
            sender: .assistant,
            modelName: "Qwen 3 (1.7B) Instruct"
        )
        
        let initial = ChatSession(
            title: "Trò chuyện đầu tiên",
            modelId: "qwen3-1.7b",
            messages: [welcome]
        )
        self.sessions = [initial]
        saveSessions()
    }
}
