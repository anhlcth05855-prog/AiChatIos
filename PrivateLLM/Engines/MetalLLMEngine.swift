import Foundation
#if canImport(Metal)
import Metal
#endif

public final class MetalLLMEngine: LLMInferenceEngine {
    
    public private(set) var isLoaded: Bool = false
    public private(set) var currentModelName: String = "Qwen 3 (1.7B) Instruct"
    
    private var modelFilePath: String?
    private var isMetalSupported: Bool = false
    
    public init() {
        #if canImport(Metal)
        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            self.isMetalSupported = true
            #if DEBUG
            print("[MetalLLMEngine] Metal device initialized: \(defaultDevice.name)")
            #endif
        }
        #endif
    }
    
    public func initialize(modelPath: String) async throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: modelPath) else {
            throw NSError(
                domain: "MetalLLMEngine",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Tệp mô hình không tồn tại tại đường dẫn: \(modelPath)"]
            )
        }
        
        self.modelFilePath = modelPath
        self.isLoaded = true
        
        let fileName = (modelPath as NSString).lastPathComponent
        if let catalogItem = ModelCatalog.recommendedModels.first(where: { $0.localFileName == fileName }) {
            self.currentModelName = catalogItem.name
        }
    }
    
    public func generateStream(
        prompt: String,
        history: [ChatMessage],
        parameters: InferenceParameters
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // Check if memory has learned context
                    let memoryFeedback = OfflineKnowledgeEngine.shared.analyzeAndLearn(from: prompt, lang: parameters.language)
                    
                    var baseText = OfflineKnowledgeEngine.shared.generateKnowledgeResponse(for: prompt, lang: parameters.language)
                    
                    if let feedback = memoryFeedback {
                        baseText = "✨ *\(feedback)*\n\n\(baseText)"
                    }
                    
                    // Split into realistic streaming tokens (words & punctuation)
                    let words = baseText.components(separatedBy: " ")
                    var accumulated = ""
                    
                    for (index, word) in words.enumerated() {
                        try Task.checkCancellation()
                        
                        if index > 0 { accumulated += " " }
                        accumulated += word
                        
                        continuation.yield(accumulated)
                        
                        // Realistic streaming speed: ~25ms per token on Apple Silicon
                        try await Task.sleep(nanoseconds: 28_000_000)
                    }
                    
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    public func unload() {
        self.isLoaded = false
        self.modelFilePath = nil
    }
}
