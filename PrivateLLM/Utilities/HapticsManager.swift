import Foundation
#if canImport(UIKit)
import UIKit

@MainActor
public final class HapticsManager {
    
    public static let shared = HapticsManager()
    
    private init() {}
    
    private var isEnabled: Bool {
        SettingsViewModel.shared.config.hapticsEnabled
    }
    
    public func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    public func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    public func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
#endif
