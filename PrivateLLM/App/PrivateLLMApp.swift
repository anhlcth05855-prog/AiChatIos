import SwiftUI

@main
struct PrivateLLMApp: App {
    
    var body: some Scene {
        WindowGroup {
            MainSplitNavigationView()
                .tint(Color.blue)
        }
    }
}
