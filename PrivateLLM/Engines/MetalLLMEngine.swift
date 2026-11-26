import Foundation
#if canImport(Metal)
import Metal
#endif
#if canImport(LlamaSwift)
import LlamaSwift
#endif

public enum MetalLLMEngineError: LocalizedError {
    case modelFileNotFound(String)
    case invalidGGUFFile(String)
    case runtimeUnavailable
    case failedToLoadModel(String)
    case failedToCreateContext
    case tokenizationFailed
    case decodeFailed(Int32)

    public var errorDescription: String? {
        switch self {
        case .modelFileNotFound(let path):
            return "Không tìm thấy tệp mô hình tại: \(path)"
        case .invalidGGUFFile(let name):
            return "Tệp \(name) không phải định dạng GGUF hợp lệ hoặc chưa tải xong. Vui lòng xóa và tải lại mô hình."
        case .runtimeUnavailable:
            return "Thư viện suy luận LlamaSwift chưa được liên kết trong bản dựng này."
        case .failedToLoadModel(let name):
            return "Không thể nạp mô hình \(name) vào bộ nhớ. Hãy thử mô hình nhỏ hơn (ví dụ Qwen 2.5 0.5B)."
        case .failedToCreateContext:
            return "Không đủ RAM để khởi tạo ngữ cảnh suy luận trên thiết bị."
        case .tokenizationFailed:
            return "Không thể mã hóa văn bản đầu vào cho mô hình."
        case .decodeFailed(let code):
            return "Lỗi suy luận llama_decode (mã \(code))."
        }
    }
}

#if canImport(LlamaSwift)
private actor LlamaRuntimeActor {
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var loadedPath: String?
    private var loadedContextSize: Int32 = 2048
    private var isBackendInitialized: Bool = false

    private func ensureBackend() {
        if !isBackendInitialized {
            llama_backend_init()
            isBackendInitialized = true
        }
    }

    func isModelLoaded(at path: String) -> Bool {
        loadedPath == path && model != nil && context != nil
    }

    func loadModel(path: String, contextWindow: Int) throws {
        if loadedPath == path && model != nil && context != nil {
            return
        }

        unload()
        ensureBackend()

        var modelParams = llama_model_default_params()
        #if targetEnvironment(simulator)
        modelParams.n_gpu_layers = 0
        #else
        modelParams.n_gpu_layers = 99
        #endif

        guard let loadedModel = llama_model_load_from_file(path, modelParams) else {
            let fileName = (path as NSString).lastPathComponent
            throw MetalLLMEngineError.failedToLoadModel(fileName)
        }

        let targetCtx = Int32(max(2048, min(contextWindow, 4096)))
        var ctxParams = llama_context_default_params()
        ctxParams.n_ctx = UInt32(targetCtx)
        ctxParams.n_batch = 512
        let cpuCount = ProcessInfo.processInfo.activeProcessorCount
        let threads = Int32(max(1, min(cpuCount - 2, 6)))
        ctxParams.n_threads = threads
        ctxParams.n_threads_batch = threads

        guard let loadedCtx = llama_init_from_model(loadedModel, ctxParams) else {
            llama_model_free(loadedModel)
            throw MetalLLMEngineError.failedToCreateContext
        }

        self.model = loadedModel
        self.context = loadedCtx
        self.loadedPath = path
        self.loadedContextSize = targetCtx
    }

    func unload() {
        if let ctx = context {
            llama_free(ctx)
            context = nil
        }
        if let mdl = model {
            llama_model_free(mdl)
            model = nil
        }
        loadedPath = nil
    }

    func generate(
        prompt: String,
        history: [ChatMessage],
        parameters: InferenceParameters,
        onToken: @Sendable (String) -> Void
    ) async throws {
        guard let model = model, let context = context else {
            throw MetalLLMEngineError.failedToLoadModel("chưa được nạp")
        }

        guard let vocab = llama_model_get_vocab(model) else {
            throw MetalLLMEngineError.tokenizationFailed
        }

        // Clear KV cache for clean multi-turn evaluation
        llama_memory_clear(llama_get_memory(context), true)

        let maxPromptTokens = max(512, Int(loadedContextSize) - 256)
        let recentHistory = history
            .filter { ($0.isUser || $0.isAssistant) && !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .suffix(10)

        var selectedHistory = Array(recentHistory)
        var promptTokens: [llama_token] = []

        // Trim oldest turns if formatted prompt exceeds context budget
        while true {
            let formatted = buildFormattedPrompt(
                model: model,
                systemPrompt: parameters.systemPrompt,
                history: selectedHistory,
                userPrompt: prompt
            )
            promptTokens = tokenize(text: formatted, vocab: vocab)
            if promptTokens.count <= maxPromptTokens || selectedHistory.isEmpty {
                break
            }
            selectedHistory.removeFirst()
        }

        if promptTokens.count > maxPromptTokens {
            promptTokens = Array(promptTokens.suffix(maxPromptTokens))
        }

        guard !promptTokens.isEmpty else {
            throw MetalLLMEngineError.tokenizationFailed
        }

        // Evaluate prompt in batches of n_batch (512)
        let batchSize = 512
        var batch = llama_batch_init(Int32(batchSize), 0, 1)
        defer { llama_batch_free(batch) }

        var offset = 0
        while offset < promptTokens.count {
            try Task.checkCancellation()
            let count = min(batchSize, promptTokens.count - offset)
            batch.n_tokens = Int32(count)

            for i in 0..<count {
                let tokenPos = offset + i
                batch.token[i] = promptTokens[tokenPos]
                batch.pos[i] = Int32(tokenPos)
                batch.n_seq_id[i] = 1
                if let seqIds = batch.seq_id, let seqId = seqIds[i] {
                    seqId[0] = 0
                }
                let isLastTokenOfPrompt = (tokenPos == promptTokens.count - 1)
                batch.logits[i] = isLastTokenOfPrompt ? 1 : 0
            }

            let decodeStatus = llama_decode(context, batch)
            if decodeStatus != 0 {
                throw MetalLLMEngineError.decodeFailed(decodeStatus)
            }
            offset += count
        }

        // Configure sampler chain
        let sparams = llama_sampler_chain_default_params()
        guard let sampler = llama_sampler_chain_init(sparams) else {
            throw MetalLLMEngineError.failedToCreateContext
        }
        defer { llama_sampler_free(sampler) }

        let vocabSize = llama_vocab_n_tokens(vocab)
        llama_sampler_chain_add(sampler, llama_sampler_init_penalties(vocabSize, 64, 1.1, 0.0, 0.0))
        llama_sampler_chain_add(sampler, llama_sampler_init_top_k(40))
        llama_sampler_chain_add(sampler, llama_sampler_init_top_p(Float(min(max(parameters.topP, 0.05), 1.0)), 1))
        llama_sampler_chain_add(sampler, llama_sampler_init_min_p(0.05, 1))
        llama_sampler_chain_add(sampler, llama_sampler_init_temp(Float(max(parameters.temperature, 0.0))))
        llama_sampler_chain_add(sampler, llama_sampler_init_dist(UInt32.random(in: 0...UInt32.max)))

        var nCur = Int32(promptTokens.count)
        let maxNewTokens = min(parameters.maxTokens, Int(loadedContextSize) - promptTokens.count - 4)
        var pendingUTF8Bytes: [UInt8] = []
        var accumulated = ""
        let stopStrings = parameters.stopSequences + ["<|eot_id|>", "<end_of_turn>", "<|end|>"]

        for step in 0..<max(1, maxNewTokens) {
            try Task.checkCancellation()

            let nextToken = llama_sampler_sample(sampler, context, -1)
            if llama_vocab_is_eog(vocab, nextToken) {
                break
            }

            let pieceBytes = tokenToBytes(token: nextToken, vocab: vocab)
            if !pieceBytes.isEmpty {
                pendingUTF8Bytes.append(contentsOf: pieceBytes)
                if let validString = String(bytes: pendingUTF8Bytes, encoding: .utf8) {
                    accumulated += validString
                    pendingUTF8Bytes.removeAll(keepingCapacity: true)

                    if let stopMatch = stopStrings.first(where: { accumulated.contains($0) }) {
                        if let range = accumulated.range(of: stopMatch) {
                            accumulated = String(accumulated[..<range.lowerBound])
                        }
                        onToken(accumulated)
                        break
                    }
                    onToken(accumulated)
                }
            }

            if step % 4 == 0 {
                await Task.yield()
            }

            batch.n_tokens = 1
            batch.token[0] = nextToken
            batch.pos[0] = nCur
            batch.n_seq_id[0] = 1
            if let seqIds = batch.seq_id, let seqId = seqIds[0] {
                seqId[0] = 0
            }
            batch.logits[0] = 1
            nCur += 1

            let status = llama_decode(context, batch)
            if status != 0 {
                throw MetalLLMEngineError.decodeFailed(status)
            }
        }

        if !pendingUTF8Bytes.isEmpty {
            accumulated += String(decoding: pendingUTF8Bytes, as: UTF8.self)
            onToken(accumulated)
        }
    }

    private func buildFormattedPrompt(
        model: OpaquePointer,
        systemPrompt: String,
        history: [ChatMessage],
        userPrompt: String
    ) -> String {
        var turns: [(role: String, content: String)] = []
        let cleanSys = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanSys.isEmpty {
            turns.append(("system", cleanSys))
        }
        for msg in history {
            let role = msg.isUser ? "user" : "assistant"
            turns.append((role, msg.content))
        }
        turns.append(("user", userPrompt))

        if let tmpl = llama_model_chat_template(model, nil) {
            var allocatedPtrs: [UnsafeMutablePointer<CChar>] = []
            defer {
                allocatedPtrs.forEach { free($0) }
            }

            var cMessages: [llama_chat_message] = []
            var totalChars = 0
            for turn in turns {
                if let rolePtr = strdup(turn.role), let contentPtr = strdup(turn.content) {
                    allocatedPtrs.append(rolePtr)
                    allocatedPtrs.append(contentPtr)
                    cMessages.append(llama_chat_message(role: rolePtr, content: contentPtr))
                    totalChars += turn.content.utf8.count
                }
            }

            if !cMessages.isEmpty {
                var bufSize = max(1024, totalChars * 2 + 512)
                var buffer = [CChar](repeating: 0, count: bufSize)
                var written = llama_chat_apply_template(
                    tmpl,
                    &cMessages,
                    cMessages.count,
                    true,
                    &buffer,
                    Int32(buffer.count)
                )
                if written > Int32(buffer.count) {
                    bufSize = Int(written) + 16
                    buffer = [CChar](repeating: 0, count: bufSize)
                    written = llama_chat_apply_template(
                        tmpl,
                        &cMessages,
                        cMessages.count,
                        true,
                        &buffer,
                        Int32(buffer.count)
                    )
                }
                if written > 0 {
                    return String(cString: buffer)
                }
            }
        }

        // Fallback ChatML format (Qwen, DeepSeek, general instruct GGUFs)
        var chatML = ""
        for turn in turns {
            chatML += "<|im_start|>\(turn.role)\n\(turn.content)<|im_end|>\n"
        }
        chatML += "<|im_start|>assistant\n"
        return chatML
    }

    private func tokenize(text: String, vocab: OpaquePointer) -> [llama_token] {
        let utf8Count = Int32(text.utf8.count)
        var tokens = [llama_token](repeating: 0, count: Int(utf8Count) + 16)
        var count: Int32 = 0
        for _ in 0..<2 {
            count = llama_tokenize(
                vocab,
                text,
                utf8Count,
                &tokens,
                Int32(tokens.count),
                true,
                true
            )
            if count >= 0 || count == Int32.min {
                break
            }
            tokens = [llama_token](repeating: 0, count: Int(-count) + 4)
        }
        guard count > 0 else { return [] }
        return Array(tokens.prefix(Int(count)))
    }

    private func tokenToBytes(token: llama_token, vocab: OpaquePointer) -> [UInt8] {
        var buffer = [CChar](repeating: 0, count: 64)
        var length = llama_token_to_piece(vocab, token, &buffer, Int32(buffer.count), 0, false)
        if length < 0 {
            buffer = [CChar](repeating: 0, count: Int(-length) + 4)
            length = llama_token_to_piece(vocab, token, &buffer, Int32(buffer.count), 0, false)
        }
        guard length > 0 else { return [] }
        return buffer.prefix(Int(length)).map { UInt8(bitPattern: $0) }
    }
}
#endif

public final class MetalLLMEngine: LLMInferenceEngine {
    
    public private(set) var isLoaded: Bool = false
    public private(set) var currentModelName: String = "Qwen 3 (1.7B) Instruct"
    
    private var modelFilePath: String?
    private var isMetalSupported: Bool = false
    #if canImport(LlamaSwift)
    private let runtime = LlamaRuntimeActor()
    #endif
    
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
        try await initialize(modelPath: modelPath, contextWindow: 4096)
    }
    
    public func initialize(modelPath: String, contextWindow: Int) async throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: modelPath) else {
            throw MetalLLMEngineError.modelFileNotFound(modelPath)
        }
        
        let fileName = (modelPath as NSString).lastPathComponent
        guard Self.isValidGGUFFile(atPath: modelPath) else {
            throw MetalLLMEngineError.invalidGGUFFile(fileName)
        }
        
        let catalogItem = ModelCatalog.recommendedModels.first(where: { $0.localFileName == fileName })
        let resolvedContext = catalogItem?.contextWindow ?? contextWindow
        
        #if canImport(LlamaSwift)
        try await runtime.loadModel(path: modelPath, contextWindow: resolvedContext)
        self.modelFilePath = modelPath
        self.isLoaded = true
        if let item = catalogItem {
            self.currentModelName = item.name
        }
        #else
        throw MetalLLMEngineError.runtimeUnavailable
        #endif
    }
    
    public func generateStream(
        prompt: String,
        history: [ChatMessage],
        parameters: InferenceParameters
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    #if canImport(LlamaSwift)
                    guard let path = self.modelFilePath else {
                        throw MetalLLMEngineError.modelFileNotFound("chưa chọn")
                    }
                    
                    let loaded = await self.runtime.isModelLoaded(at: path)
                    if !loaded {
                        try await self.initialize(modelPath: path)
                    }
                    
                    // Learn personal facts locally & enrich system prompt if user memory exists
                    _ = OfflineKnowledgeEngine.shared.analyzeAndLearn(from: prompt, lang: parameters.language)
                    var enrichedParams = parameters
                    if OfflineKnowledgeEngine.shared.hasAnyMemory {
                        var memoryBits: [String] = []
                        if let name = OfflineKnowledgeEngine.shared.userName { memoryBits.append("Tên người dùng: \(name)") }
                        if let age = OfflineKnowledgeEngine.shared.userAge { memoryBits.append("Tuổi: \(age)") }
                        if let loc = OfflineKnowledgeEngine.shared.userLocation { memoryBits.append("Nơi ở: \(loc)") }
                        if let hobby = OfflineKnowledgeEngine.shared.userHobby { memoryBits.append("Sở thích: \(hobby)") }
                        if !memoryBits.isEmpty {
                            enrichedParams.systemPrompt += "\nThông tin người dùng: " + memoryBits.joined(separator: ", ") + "."
                        }
                    }
                    
                    try await self.runtime.generate(
                        prompt: prompt,
                        history: history,
                        parameters: enrichedParams,
                        onToken: { partial in
                            continuation.yield(partial)
                        }
                    )
                    continuation.finish()
                    #else
                    throw MetalLLMEngineError.runtimeUnavailable
                    #endif
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
        #if canImport(LlamaSwift)
        let runtime = self.runtime
        Task {
            await runtime.unload()
        }
        #endif
    }
    
    public static func isValidGGUFFile(atPath path: String) -> Bool {
        guard let handle = FileHandle(forReadingAtPath: path) else { return false }
        defer { try? handle.close() }
        guard let header = try? handle.read(upToCount: 4), header.count == 4 else { return false }
        // GGUF magic header: "GGUF" (0x47, 0x47, 0x55, 0x46)
        return header[0] == 0x47 && header[1] == 0x47 && header[2] == 0x55 && header[3] == 0x46
    }
}
