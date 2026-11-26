import Foundation

public final class ModelDownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    
    public static let shared = ModelDownloadManager()
    
    @Published public var models: [LocalModelItem] = []
    @Published public var activeModelId: String = "qwen3-1.7b"
    @Published public var isDownloadingAny: Bool = false
    @Published public var lastErrorMessage: String?
    
    private let fileManager = FileManager.default
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var taskModelMap: [Int: String] = [:]
    private var lastSampleTime: [String: Date] = [:]
    private var lastSampleBytes: [String: Int64] = [:]
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
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
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
                   let size = attrs[.size] as? Int64,
                   size >= 1_000_000,
                   MetalLLMEngine.isValidGGUFFile(atPath: fileURL.path) {
                    models[i].status = .ready
                    models[i].downloadProgress = 1.0
                } else {
                    // Clean up legacy mock placeholder or corrupted partial file
                    try? fileManager.removeItem(at: fileURL)
                    if models[i].status != .downloading {
                        models[i].status = .notDownloaded
                        models[i].downloadProgress = 0.0
                    }
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
        if fileManager.fileExists(atPath: fileURL.path),
           MetalLLMEngine.isValidGGUFFile(atPath: fileURL.path) {
            return fileURL.path
        }
        return nil
    }
    
    public func firstReadyModel() -> LocalModelItem? {
        models.first { getModelFilePath(for: $0.id) != nil }
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
    
    public func cancelDownload(for modelId: String) {
        if let task = downloadTasks.removeValue(forKey: modelId) {
            task.cancel()
        }
        DispatchQueue.main.async {
            if let idx = self.models.firstIndex(where: { $0.id == modelId }) {
                self.models[idx].status = .notDownloaded
                self.models[idx].downloadProgress = 0.0
                self.models[idx].downloadSpeed = nil
            }
            self.isDownloadingAny = self.models.contains { $0.status == .downloading }
        }
    }
    
    public func startRealDownload(for modelId: String) {
        guard downloadTasks[modelId] == nil,
              let idx = models.firstIndex(where: { $0.id == modelId }),
              let url = URL(string: models[idx].downloadUrl) else { return }
        
        DispatchQueue.main.async {
            if let currentIdx = self.models.firstIndex(where: { $0.id == modelId }) {
                self.models[currentIdx].status = .downloading
                self.models[currentIdx].downloadProgress = 0.0
                self.models[currentIdx].downloadSpeed = "Đang kết nối..."
            }
            self.lastErrorMessage = nil
            self.isDownloadingAny = true
        }
        
        lastSampleTime[modelId] = Date()
        lastSampleBytes[modelId] = 0
        
        let task = backgroundSession.downloadTask(with: url)
        downloadTasks[modelId] = task
        taskModelMap[task.taskIdentifier] = modelId
        task.resume()
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
        let expected = totalBytesExpectedToWrite > 0
            ? totalBytesExpectedToWrite
            : (models.first(where: { $0.id == modelId })?.sizeBytes ?? 0)
        let progress = expected > 0 ? Double(totalBytesWritten) / Double(expected) : 0.0
        
        let now = Date()
        var speedLabel: String? = nil
        if let prevTime = lastSampleTime[modelId],
           let prevBytes = lastSampleBytes[modelId] {
            let elapsed = now.timeIntervalSince(prevTime)
            if elapsed >= 0.8 {
                let bytesPerSec = Double(totalBytesWritten - prevBytes) / elapsed
                let mbPerSec = max(0, bytesPerSec / (1024 * 1024))
                let writtenMB = Double(totalBytesWritten) / (1024 * 1024)
                let totalMB = Double(expected) / (1024 * 1024)
                speedLabel = String(format: "%.0f / %.0f MB (%.1f MB/s)", writtenMB, totalMB, mbPerSec)
                lastSampleTime[modelId] = now
                lastSampleBytes[modelId] = totalBytesWritten
            }
        }
        
        DispatchQueue.main.async {
            if let idx = self.models.firstIndex(where: { $0.id == modelId }) {
                self.models[idx].downloadProgress = min(max(progress, 0.0), 1.0)
                if let label = speedLabel {
                    self.models[idx].downloadSpeed = label
                }
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
        
        if let httpResponse = downloadTask.response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            DispatchQueue.main.async {
                self.downloadTasks.removeValue(forKey: modelId)
                if let idx = self.models.firstIndex(where: { $0.id == modelId }) {
                    self.models[idx].status = .error
                    self.models[idx].downloadProgress = 0.0
                    self.models[idx].downloadSpeed = nil
                }
                self.lastErrorMessage = "Tải \(item.name) thất bại (HTTP \(httpResponse.statusCode))."
                self.isDownloadingAny = self.models.contains { $0.status == .downloading }
            }
            return
        }
        
        let destinationURL = modelsDirectory.appendingPathComponent(item.localFileName)
        try? fileManager.removeItem(at: destinationURL)
        do {
            try fileManager.moveItem(at: location, to: destinationURL)
            guard MetalLLMEngine.isValidGGUFFile(atPath: destinationURL.path) else {
                try? fileManager.removeItem(at: destinationURL)
                throw MetalLLMEngineError.invalidGGUFFile(item.name)
            }
            DispatchQueue.main.async {
                self.downloadTasks.removeValue(forKey: modelId)
                if let idx = self.models.firstIndex(where: { $0.id == modelId }) {
                    self.models[idx].downloadSpeed = nil
                }
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
                    self.models[idx].downloadProgress = 0.0
                    self.models[idx].downloadSpeed = nil
                }
                self.lastErrorMessage = error.localizedDescription
                self.isDownloadingAny = self.models.contains { $0.status == .downloading }
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error,
              let modelId = taskModelMap.removeValue(forKey: task.taskIdentifier) else { return }
        
        let isCancelled = (error as NSError).code == NSURLErrorCancelled
        DispatchQueue.main.async {
            self.downloadTasks.removeValue(forKey: modelId)
            if let idx = self.models.firstIndex(where: { $0.id == modelId }) {
                self.models[idx].status = isCancelled ? .notDownloaded : .error
                self.models[idx].downloadProgress = 0.0
                self.models[idx].downloadSpeed = nil
            }
            if !isCancelled {
                self.lastErrorMessage = "Lỗi tải mô hình: \(error.localizedDescription)"
            }
            self.isDownloadingAny = self.models.contains { $0.status == .downloading }
        }
    }
}
