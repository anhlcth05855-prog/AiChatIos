import Foundation
import AppIntents

public struct PrivateLLMShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskPrivateLLMIntent(),
            phrases: [
                "Hỏi \(.applicationName)",
                "Trò chuyện với \(.applicationName)",
                "Ask \(.applicationName) \(\.$prompt)",
                "Hỏi AI Offline \(\.$prompt)"
            ],
            shortTitle: "Hỏi AI Offline",
            systemImageName: "lock.shield.fill"
        )
    }
}
