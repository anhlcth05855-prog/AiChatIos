import Foundation

public final class ModelDownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    
    public static let shared = ModelDownloadManager()
    
    @Published public var models: [LocalModelItem] = []
    @Published public var activeModelId: String = "qwen3-1.7b"
    @Published public var isDownloadingAny: Bool = false
    
    private let fileManager = FileManager.default
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var taskModelMap: [Int: String] = [:]
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
            } else if models[i].status != .downloading {
                models[i].status = .notDownloaded
                models[i].downloadProgress = 0.0
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
        DispatchQueue.main.async {
            self.activeModelId = id
        }
        UserDefaults.standard.set(id, forKey: "PrivateLLM_ActiveModelId")
    }
    
    public func deleteModel(id: String) {
        if let task = downloadTasks.removeValue(forKey: id) {
            task.cancel()
        }
        guard let idx = models.firstIndex(where: { $0.id == id }) else { return }
        let item = models[idx]
        let fileURL = modelsDirectory.appendingPathComponent(item.localFileName)
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
        DispatchQueue.main.async {
            if let currentIdx = self.models.firstIndex(where: { $0.id == id }) {
                self.models[currentIdx].status = .notDownloaded
                self.models[currentIdx].downloadProgress = 0.0
                self.models[currentIdx].downloadSpeed = nil
            }
            self.isDownloadingAny = self.models.contains { $0.status == .downloading }
        }
    }
    
    public func startRealDownload(for modelId: String) {
        guard let idx = models.firstIndex(where: { $0.id == modelId }),
              let url = URL(string: models[idx].downloadUrl) else { return }
        
        models[idx].status = .downloading
        models[idx].downloadProgress = 0.0
        isDownloadingAny = true
        
        let task = backgroundSession.downloadTask(with: url)
        downloadTasks[modelId] = task
        taskModelMap[task.taskIdentifier] = modelId
        task.resume()
    }
    
    public func simulateQuickDownload(for modelId: String, onComplete: (() -> Void)? = nil) {
        guard let idx = models.firstIndex(where: { $0.id == modelId }) else { return }
        models[idx].status = .downloading
        models[idx].downloadProgress = 0.0
        isDownloadingAny = true
        
        let item = models[idx]
        let targetURL = modelsDirectory.appendingPathComponent(item.localFileName)
        
        var currentProgress: Double = 0.0
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] timer in
                guard let self = self,
                      let currentIdx = self.models.firstIndex(where: { $0.id == modelId }) else {
                    timer.invalidate()
                    return
                }
                currentProgress += 0.1
                if currentProgress >= 1.0 {
                    timer.invalidate()
                    self.models[currentIdx].downloadProgress = 1.0
                    self.models[currentIdx].status = .ready
                    self.isDownloadingAny = self.models.contains { $0.status == .downloading }
                    
                    // Write placeholder weights header so fileExists is true
                    let mockHeader = "LOCAL_LLM_WEIGHTS_GGUF_HEADER_\(item.id)".data(using: .utf8) ?? Data()
                    try? mockHeader.write(to: targetURL)
                    
                    self.setActiveModel(id: item.id)
                    onComplete?()
                } else {
                    self.models[currentIdx].downloadProgress = currentProgress
                }
            }
        }
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let modelId = taskModelMap[downloadTask.taskIdentifier] else { return }
        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0.0
        
        DispatchQueue.main.async {
            if let idx = self.models.firstIndex(where: { $0.id == modelId }) {
                self.models[idx].downloadProgress = min(max(progress, 0.0), 1.0)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let modelId = taskModelMap.removeValue(forKey: downloadTask.taskIdentifier),
              let item = models.first(where: { $0.id == modelId }) else {
            DispatchQueue.main.async {
                self.refreshModelStatuses()
            }
            return
        }
        
        let destinationURL = modelsDirectory.appendingPathComponent(item.localFileName)
        try? fileManager.removeItem(at: destinationURL)
        do {
            try fileManager.moveItem(at: location, to: destinationURL)
            DispatchQueue.main.async {
                self.downloadTasks.removeValue(forKey: modelId)
                self.refreshModelStatuses()
                self.setActiveModel(id: modelId)
                self.isDownloadingAny = self.models.contains { $0.status == .downloading }
            }
        } catch {
            print("[ModelDownloadManager] Failed to move downloaded model: \(error)")
            DispatchQueue.main.async {
                self.downloadTasks.removeValue(forKey: modelId)
                if let idx = self.models.firstIndex(where: { $0.id == modelId }) {
                    self.models[idx].status = .error
                }
                self.isDownloadingAny = self.models.contains { $0.status == .downloading }
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error,
              let modelId = taskModelMap.removeValue(forKey: task.taskIdentifier) else { return }
        
        DispatchQueue.main.async {
            self.downloadTasks.removeValue(forKey: modelId)
            if let idx = self.models.firstIndex(where: { $0.id == modelId }) {
                self.models[idx].status = (error as NSError).code == NSURLErrorCancelled ? .notDownloaded : .error
                self.models[idx].downloadProgress = 0.0
            }
            self.isDownloadingAny = self.models.contains { $0.status == .downloading }
        }
    }
}
