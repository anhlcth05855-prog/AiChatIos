import SwiftUI

public struct MainSplitNavigationView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var showSettings: Bool = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .detail
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredCompactColumn
        ) {
            // Sidebar: Conversations List
            SessionListView(
                chatViewModel: chatViewModel,
                showSettings: $showSettings,
                onNavigateToChat: {
                    preferredCompactColumn = .detail
                }
            )
            .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 360)
        } detail: {
            // Main Canvas: Active Chat Session
            ChatView(viewModel: chatViewModel)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
