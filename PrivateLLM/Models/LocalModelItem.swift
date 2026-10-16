import Foundation

public enum ModelFamily: String, Codable, CaseIterable {
    case qwen = "Qwen"
    case llama = "Llama"
    case gemma = "Gemma"
    case deepseek = "DeepSeek"
    case phi = "Phi"
    case mistral = "Mistral"
    
    public var iconName: String {
        switch self {
        case .qwen: return "sparkles"
        case .llama: return "flame.fill"
        case .gemma: return "diamond.fill"
        case .deepseek: return "brain.head.profile"
        case .phi: return "atom"
        case .mistral: return "wind"
        }
    }
}

public enum ModelStatus: String, Codable {
    case notDownloaded
    case downloading
    case ready
    case loading
    case error
}

public struct LocalModelItem: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let family: ModelFamily
    public let parameterSize: String
    public let quantization: String
    public let description: String
    public let downloadUrl: String
    public let sizeBytes: Int64
    public let requiredRamBytes: Int64
    public let localFileName: String
    public let contextWindow: Int
    public let recommendedHardware: String
    
    public var status: ModelStatus
    public var downloadProgress: Double // 0.0 to 1.0
    public var downloadSpeed: String?
    
    public init(
        id: String,
        name: String,
        family: ModelFamily,
        parameterSize: String,
        quantization: String,
        description: String,
        downloadUrl: String,
        sizeBytes: Int64,
        requiredRamBytes: Int64,
        localFileName: String,
        contextWindow: Int = 8192,
        recommendedHardware: String = "iPhone 15 Pro trở lên hoặc Mac M1+",
        status: ModelStatus = .notDownloaded,
        downloadProgress: Double = 0.0,
        downloadSpeed: String? = nil
    ) {
        self.id = id
        self.name = name
        self.family = family
        self.parameterSize = parameterSize
        self.quantization = quantization
        self.description = description
        self.downloadUrl = downloadUrl
        self.sizeBytes = sizeBytes
        self.requiredRamBytes = requiredRamBytes
        self.localFileName = localFileName
        self.contextWindow = contextWindow
        self.recommendedHardware = recommendedHardware
        self.status = status
        self.downloadProgress = downloadProgress
        self.downloadSpeed = downloadSpeed
    }
    
    public var isDownloaded: Bool {
        status == .ready
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
    
    public var formattedRequiredRam: String {
        ByteCountFormatter.string(fromByteCount: requiredRamBytes, countStyle: .memory)
    }
}
