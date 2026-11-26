import Foundation

public struct InferenceParameters {
    public var temperature: Double
    public var topP: Double
    public var maxTokens: Int
    public var systemPrompt: String
    public var language: String
    public var stopSequences: [String]
    
    public init(
        temperature: Double = 0.7,
        topP: Double = 0.9,
        maxTokens: Int = 2048,
        systemPrompt: String = "",
        language: String = "vi",
        stopSequences: [String] = ["<|im_end|>", "<|endoftext|>", "</s>"]
    ) {
        self.temperature = temperature
        self.topP = topP
        self.maxTokens = maxTokens
        self.systemPrompt = systemPrompt
        self.language = language
        self.stopSequences = stopSequences
    }
}

public protocol LLMInferenceEngine: AnyObject {
    var isLoaded: Bool { get }
    var currentModelName: String { get }
    
    func initialize(modelPath: String) async throws
    func generateStream(
        prompt: String,
        history: [ChatMessage],
        parameters: InferenceParameters
    ) -> AsyncThrowingStream<String, Error>
    
    func unload()
}
