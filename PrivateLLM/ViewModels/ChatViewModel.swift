import Foundation
import SwiftUI
import Combine

@MainActor
public final class ChatViewModel: ObservableObject {
    
    @Published public var currentSession: ChatSession
    @Published public var inputText: String = ""
    @Published public var isGenerating: Bool = false
    @Published public var errorMessage: String?
    
    // Dependencies
    public let storageRepo = ChatStorageRepository.shared
    public let modelDownloadManager = ModelDownloadManager.shared
    public let hardwareMonitor = HardwareMemoryMonitor.shared
    public let speechManager = AudioSpeechManager.shared
    public let settingsViewModel = SettingsViewModel.shared
    
    private let metalEngine = MetalLLMEngine()
    private var generationTask: Task<Void, Never>?
    
    public init(session: ChatSession? = nil) {
        if let s = session {
            self.currentSession = s
        } else if let first = ChatStorageRepository.shared.sessions.first {
            self.currentSession = first
        } else {
            self.currentSession = ChatStorageRepository.shared.createSession()
        }
        
        syncModelWithSession()
    }
    
    public func selectSession(_ session: ChatSession) {
        cancelGeneration()
        self.currentSession = session
        syncModelWithSession()
    }
    
    private func syncModelWithSession() {
        // Automatic model association per conversation
        if modelDownloadManager.models.contains(where: { $0.id == currentSession.modelId }) {
            modelDownloadManager.setActiveModel(id: currentSession.modelId)
        }
    }
    
    public func sendMessage(overrideText: String? = nil) {
        let textToSend = (overrideText ?? inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToSend.isEmpty, !isGenerating else { return }
        
        #if canImport(UIKit)
        HapticsManager.shared.impact(.medium)
        #endif
        
        let config = settingsViewModel.config
        var activeModel = modelDownloadManager.getActiveModel()
        
        // If active model isn't downloaded yet, auto-switch to any downloaded offline model if available
        if config.selectedProvider == .privateLLM,
           modelDownloadManager.getModelFilePath(for: activeModel.id) == nil,
           let readyModel = modelDownloadManager.firstReadyModel() {
            activeModel = readyModel
            modelDownloadManager.setActiveModel(id: readyModel.id)
        }
        
        currentSession.modelId = activeModel.id
        
        let userMsg = ChatMessage(
            content: textToSend,
            sender: .user,
            timestamp: Date()
        )
        currentSession.messages.append(userMsg)
        
        // Auto-generate session title from the first prompt
        if currentSession.title == "Cuộc trò chuyện mới" || currentSession.title == "Trò chuyện đầu tiên" {
            let truncatedTitle = textToSend.count > 30 ? String(textToSend.prefix(30)) + "..." : textToSend
            currentSession.title = truncatedTitle
        }
        
        if overrideText == nil {
            inputText = ""
        }
        
        storageRepo.updateSession(currentSession)
        
        // Start Assistant Response
        isGenerating = true
        let displayModelName: String
        switch config.selectedProvider {
        case .privateLLM:
            displayModelName = activeModel.name
        case .mockOffline:
            displayModelName = "Offline Knowledge Engine"
        case .googleGemini:
            displayModelName = "Gemini (\(config.geminiModel))"
        case .openAI:
            displayModelName = "OpenAI (\(config.openAiModel))"
        }
        
        let assistantMsg = ChatMessage(
            content: "",
            sender: .assistant,
            timestamp: Date(),
            modelName: displayModelName,
            isStreaming: true
        )
        currentSession.messages.append(assistantMsg)
        
        let targetSessionId = currentSession.id
        let assistantMsgId = assistantMsg.id
        let historySnapshot = currentSession.messages.filter { $0.id != assistantMsgId && $0.sender != .status }
        let effectiveSystemPrompt = (currentSession.systemPrompt?.isEmpty == false)
            ? (currentSession.systemPrompt ?? config.systemPrompt)
            : config.systemPrompt
        let startTime = Date()
        
        generationTask = Task {
            do {
                let finalText: String
                switch config.selectedProvider {
                case .privateLLM:
                    if let modelPath = modelDownloadManager.getModelFilePath(for: activeModel.id) {
                        if !metalEngine.isLoaded || metalEngine.currentModelName != activeModel.name {
                            self.updateAssistantMessage(id: assistantMsgId, inSession: targetSessionId) { msg in
                                msg.content = "⏳ Đang nạp mô hình **\(activeModel.name)** vào Apple Silicon Metal..."
                            }
                            try await metalEngine.initialize(modelPath: modelPath, contextWindow: activeModel.contextWindow)
                            self.updateAssistantMessage(id: assistantMsgId, inSession: targetSessionId) { msg in
                                msg.content = ""
                            }
                        }
                        
                        let params = InferenceParameters(
                            temperature: config.temperature,
                            topP: config.topP,
                            maxTokens: config.maxTokens,
                            systemPrompt: effectiveSystemPrompt,
                            language: config.appLanguage
                        )
                        let stream = metalEngine.generateStream(
                            prompt: textToSend,
                            history: historySnapshot.dropLast(), // exclude current user message (passed as prompt)
                            parameters: params
                        )
                        var latest = ""
                        for try await partial in stream {
                            if Task.isCancelled { break }
                            latest = partial
                            self.updateAssistantMessage(id: assistantMsgId, inSession: targetSessionId) { msg in
                                msg.content = partial
                            }
                        }
                        finalText = latest
                    } else {
                        let guideText = """
                        ⚠️ **Chưa có mô hình AI Offline (.gguf) được tải về máy.**

                        Để AI trả lời thông minh mọi câu hỏi khi tắt Wi-Fi, bạn hãy bật mạng 1 lần để tải mô hình về thiết bị:
                        1. Nhấn vào tên mô hình **\(activeModel.name)** ở thanh trên cùng.
                        2. Chọn **Tải mô hình** (gợi ý **Qwen 2.5 Mini 0.5B ~491MB** để tải nhanh và chạy mượt trên mọi iPhone, hoặc **Qwen 3 1.7B ~1.1GB** để hiểu tiếng Việt sâu hơn).
                        3. Sau khi tải xong, bạn có thể **tắt Wi-Fi hoàn toàn** và chat tự nhiên 100% On-Device!
                        """
                        self.updateAssistantMessage(id: assistantMsgId, inSession: targetSessionId) { msg in
                            msg.content = guideText
                        }
                        finalText = guideText
                    }
                    
                case .mockOffline:
                    _ = OfflineKnowledgeEngine.shared.analyzeAndLearn(from: textToSend, lang: config.appLanguage)
                    let reply = OfflineKnowledgeEngine.shared.generateKnowledgeResponse(for: textToSend, lang: config.appLanguage)
                    let words = reply.components(separatedBy: " ")
                    var accumulated = ""
                    for (index, word) in words.enumerated() {
                        try Task.checkCancellation()
                        if index > 0 { accumulated += " " }
                        accumulated += word
                        self.updateAssistantMessage(id: assistantMsgId, inSession: targetSessionId) { msg in
                            msg.content = accumulated
                        }
                        try await Task.sleep(nanoseconds: 20_000_000)
                    }
                    finalText = reply
                    
                case .googleGemini:
                    let reply = try await CloudGeminiEngine.shared.generateContent(
                        apiKey: config.geminiApiKey,
                        model: config.geminiModel,
                        prompt: textToSend,
                        systemInstruction: effectiveSystemPrompt,
                        history: Array(historySnapshot.dropLast())
                    )
                    try Task.checkCancellation()
                    self.updateAssistantMessage(id: assistantMsgId, inSession: targetSessionId) { msg in
                        msg.content = reply
                    }
                    finalText = reply
                    
                case .openAI:
                    let reply = try await CloudOpenAIEngine.shared.createChatCompletion(
                        apiKey: config.openAiApiKey,
                        model: config.openAiModel,
                        prompt: textToSend,
                        systemInstruction: effectiveSystemPrompt,
                        history: Array(historySnapshot.dropLast())
                    )
                    try Task.checkCancellation()
                    self.updateAssistantMessage(id: assistantMsgId, inSession: targetSessionId) { msg in
                        msg.content = reply
                    }
                    finalText = reply
                }
                
                guard !Task.isCancelled else { return }
                
                let duration = Date().timeIntervalSince(startTime)
                self.updateAssistantMessage(id: assistantMsgId, inSession: targetSessionId) { msg in
                    msg.isStreaming.value = false
                    msg.generationDuration = duration
                    msg.tokenCount = max(1, msg.content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)
                }
                
                if self.currentSession.id == targetSessionId {
                    self.storageRepo.updateSession(self.currentSession)
                    self.isGenerating = false
                }
                
                if config.ttsAutoSpeak && !finalText.isEmpty {
                    self.speechManager.speak(text: finalText, langCode: config.appLanguage)
                }
                
                #if canImport(UIKit)
                HapticsManager.shared.notify(.success)
                #endif
                
            } catch is CancellationError {
                self.updateAssistantMessage(id: assistantMsgId, inSession: targetSessionId) { msg in
                    msg.isStreaming.value = false
                }
                if self.currentSession.id == targetSessionId {
                    self.storageRepo.updateSession(self.currentSession)
                    self.isGenerating = false
                }
            } catch {
                self.updateAssistantMessage(id: assistantMsgId, inSession: targetSessionId) { msg in
                    if msg.content.isEmpty || msg.content.hasPrefix("⏳") {
                        msg.content = "⚠️ Lỗi: \(error.localizedDescription)"
                    } else {
                        msg.content += "\n\n⚠️ Đã dừng: \(error.localizedDescription)"
                    }
                    msg.isStreaming.value = false
                }
                if self.currentSession.id == targetSessionId {
                    self.storageRepo.updateSession(self.currentSession)
                    self.isGenerating = false
                }
            }
        }
    }
    
    private func updateAssistantMessage(id: UUID, inSession sessionId: UUID, mutate: (inout ChatMessage) -> Void) {
        if currentSession.id == sessionId,
           let idx = currentSession.messages.firstIndex(where: { $0.id == id }) {
            mutate(&currentSession.messages[idx])
        } else if let sIdx = storageRepo.sessions.firstIndex(where: { $0.id == sessionId }),
                  let mIdx = storageRepo.sessions[sIdx].messages.firstIndex(where: { $0.id == id }) {
            mutate(&storageRepo.sessions[sIdx].messages[mIdx])
        }
    }
    
    public func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        isGenerating = false
        if let lastIdx = currentSession.messages.indices.last, currentSession.messages[lastIdx].isAssistant {
            currentSession.messages[lastIdx].isStreaming.value = false
        }
        storageRepo.updateSession(currentSession)
    }
    
    public func regenerateLastResponse() {
        guard !isGenerating else { return }
        guard let lastUserMsg = currentSession.messages.last(where: { $0.isUser }) else { return }
        
        // Remove trailing assistant message if present
        if let last = currentSession.messages.last, last.isAssistant {
            currentSession.messages.removeLast()
        }
        
        sendMessage(overrideText: lastUserMsg.content)
    }
    
    public func startNewChat() {
        cancelGeneration()
        let newSession = storageRepo.createSession(
            title: "Cuộc trò chuyện mới",
            modelId: modelDownloadManager.activeModelId
        )
        self.currentSession = newSession
        #if canImport(UIKit)
        HapticsManager.shared.impact(.light)
        #endif
    }
    
    public func speakMessage(_ message: ChatMessage) {
        if speechManager.isSpeaking {
            speechManager.stopSpeaking()
        } else {
            speechManager.speak(text: message.content, langCode: settingsViewModel.config.appLanguage)
        }
    }
}
