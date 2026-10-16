import Foundation
import SwiftUI

@MainActor
public final class ModelManagerViewModel: ObservableObject {
    
    @Published public var selectedFamily: ModelFamily? = nil
    @Published public var alertMessage: String?
    @Published public var showAlert: Bool = false
    
    public let downloadManager = ModelDownloadManager.shared
    public let hardwareMonitor = HardwareMemoryMonitor.shared
    
    public var filteredModels: [LocalModelItem] {
        if let fam = selectedFamily {
            return downloadManager.models.filter { $0.family == fam }
        }
        return downloadManager.models
    }
    
    public func selectActiveModel(_ model: LocalModelItem) {
        // Verify hardware safety before selecting
        if !hardwareMonitor.canSafelyRun(requiredRamBytes: model.requiredRamBytes) {
            alertMessage = "⚠️ Cảnh báo RAM khả dụng (\(hardwareMonitor.currentSpecs.formattedAvailableRam)) có thể thấp hơn mức khuyến nghị (\(model.formattedRequiredRam)) của mô hình \(model.name). Ứng dụng vẫn có thể chạy nhưng có thể bị iOS giải phóng bộ nhớ khi chạy ứng dụng khác."
            showAlert = true
        }
        
        downloadManager.setActiveModel(id: model.id)
        #if canImport(UIKit)
        HapticsManager.shared.impact(.light)
        #endif
    }
    
    public func downloadModel(_ model: LocalModelItem) {
        #if canImport(UIKit)
        HapticsManager.shared.impact(.medium)
        #endif
        downloadManager.simulateQuickDownload(for: model.id) {
            #if canImport(UIKit)
            HapticsManager.shared.notify(.success)
            #endif
        }
    }
    
    public func deleteModel(_ model: LocalModelItem) {
        #if canImport(UIKit)
        HapticsManager.shared.impact(.rigid)
        #endif
        downloadManager.deleteModel(id: model.id)
    }
}
