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
        let activeModel = modelDownloadManager.getActiveModel()
        
        var assistantMsg = ChatMessage(
            content: "",
            sender: .assistant,
            timestamp: Date(),
            modelName: activeModel.name,
            isStreaming: true
        )
        currentSession.messages.append(assistantMsg)
        
        let assistantIndex = currentSession.messages.count - 1
        let startTime = Date()
        
        generationTask = Task {
            do {
                let stream = metalEngine.generateStream(
                    prompt: textToSend,
                    history: currentSession.messages,
                    parameters: InferenceParameters(
                        temperature: currentSession.temperature,
                        systemPrompt: currentSession.systemPrompt ?? ""
                    )
                )
                
                for try await partial in stream {
                    if Task.isCancelled { break }
                    currentSession.messages[assistantIndex].content = partial
                }
                
                let duration = Date().timeIntervalSince(startTime)
                currentSession.messages[assistantIndex].isStreaming.value = false
                currentSession.messages[assistantIndex].generationDuration = duration
                currentSession.messages[assistantIndex].tokenCount = currentSession.messages[assistantIndex].content.components(separatedBy: " ").count
                
                storageRepo.updateSession(currentSession)
                isGenerating = false
                
                #if canImport(UIKit)
                HapticsManager.shared.notify(.success)
                #endif
                
            } catch {
                currentSession.messages[assistantIndex].content += "\n\n⚠️ Đã dừng: \(error.localizedDescription)"
                currentSession.messages[assistantIndex].isStreaming.value = false
                storageRepo.updateSession(currentSession)
                isGenerating = false
            }
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
            speechManager.speak(text: message.content)
        }
    }
}
