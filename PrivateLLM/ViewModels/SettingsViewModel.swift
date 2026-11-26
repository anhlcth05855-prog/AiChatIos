import Foundation
import SwiftUI

@MainActor
public final class SettingsViewModel: ObservableObject {
    
    public static let shared = SettingsViewModel()
    
    @Published public var config: AppConfiguration
    @Published public var selectedPersona: SystemPersona?
    @Published public var showResetMemoryAlert: Bool = false
    @Published public var showClearAllAlert: Bool = false
    
    public let storeKitManager = StoreKitManager.shared
    public let knowledgeEngine = OfflineKnowledgeEngine.shared
    
    private let configKey = "PrivateLLM_AppConfig_v1"
    
    public init() {
        if let data = UserDefaults.standard.data(forKey: configKey),
           let saved = try? JSONDecoder().decode(AppConfiguration.self, from: data) {
            self.config = saved
        } else {
            self.config = .default
        }
    }
    
    public func saveConfiguration() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: configKey)
        }
        #if canImport(UIKit)
        HapticsManager.shared.notify(.success)
        #endif
    }
    
    public func applyPersona(_ persona: SystemPersona) {
        self.selectedPersona = persona
        self.config.systemPrompt = persona.prompt
        saveConfiguration()
    }
    
    public func resetUserMemory() {
        knowledgeEngine.clearMemory()
        #if canImport(UIKit)
        HapticsManager.shared.notify(.success)
        #endif
    }
    
    public func clearAllConversations() {
        ChatStorageRepository.shared.clearAllHistory()
        #if canImport(UIKit)
        HapticsManager.shared.notify(.success)
        #endif
    }
}
