import Foundation

public final class ModelDownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    
    public static let shared = ModelDownloadManager()
    
    @Published public var models: [LocalModelItem] = []
    @Published public var activeModelId: String = "qwen3-1.7b"
    @Published public var isDownloadingAny: Bool = false
    
    private let fileManager = FileManager.default
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var backgroundSession: URLSession!
    
    private var modelsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("Models", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.privatellm.modeldownload")
        self.backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        self.models = ModelCatalog.recommendedModels
        refreshModelStatuses()
        
        let savedActive = UserDefaults.standard.string(forKey: "PrivateLLM_ActiveModelId")
        if let s = savedActive, models.contains(where: { $0.id == s }) {
            self.activeModelId = s
        }
    }
    
    public func refreshModelStatuses() {
        for i in 0..<models.count {
            let fileURL = modelsDirectory.appendingPathComponent(models[i].localFileName)
            if fileManager.fileExists(atPath: fileURL.path) {
                if let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let size = attrs[.size] as? Int64, size > 0 {
                    models[i].status = .ready
                    models[i].downloadProgress = 1.0
                }
            } else {
                if models[i].status != .downloading {
                    models[i].status = .notDownloaded
                    models[i].downloadProgress = 0.0
                }
            }
        }
    }
    
    public func getActiveModel() -> LocalModelItem {
        models.first { $0.id == activeModelId } ?? models[0]
    }
    
    public func getModelFilePath(for modelId: String) -> String? {
        guard let item = models.first(where: { $0.id == modelId }) else { return nil }
        let fileURL = modelsDirectory.appendingPathComponent(item.localFileName)
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL.path
        }
        return nil
    }
    
    public func setActiveModel(id: String) {
        guard models.contains(where: { $0.id == id }) else { return }
        self.activeModelId = id
        UserDefaults.standard.set(id, forKey: "PrivateLLM_ActiveModelId")
    }
    
    public func deleteModel(id: String) {
        guard let idx = models.firstIndex(where: { $0.id == id }) else { return }
        let item = models[idx]
        let fileURL = modelsDirectory.appendingPathComponent(item.localFileName)
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
        models[idx].status = .notDownloaded
        models[idx].downloadProgress = 0.0
    }
    
    public func simulateQuickDownload(for modelId: String, onComplete: (() -> Void)? = nil) {
        guard let idx = models.firstIndex(where: { $0.id == modelId }) else { return }
        models[idx].status = .downloading
        models[idx].downloadProgress = 0.0
        isDownloadingAny = true
        
        let item = models[idx]
        let targetURL = modelsDirectory.appendingPathComponent(item.localFileName)
        
        var currentProgress: Double = 0.0
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            currentProgress += 0.1
            if currentProgress >= 1.0 {
                timer.invalidate()
                self.models[idx].downloadProgress = 1.0
                self.models[idx].status = .ready
                self.isDownloadingAny = false
                
                // Write placeholder weights header so fileExists is true
                let mockHeader = "LOCAL_LLM_WEIGHTS_GGUF_HEADER_\(item.id)".data(using: .utf8) ?? Data()
                try? mockHeader.write(to: targetURL)
                
                self.setActiveModel(id: item.id)
                onComplete?()
            } else {
                self.models[idx].downloadProgress = currentProgress
            }
        }
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Handled when background downloads complete
        DispatchQueue.main.async {
            self.refreshModelStatuses()
        }
    }
}
