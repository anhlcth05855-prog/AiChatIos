import SwiftUI

public struct ChatView: View {
    @ObservedObject public var viewModel: ChatViewModel
    
    @State private var showModelSheet: Bool = false
    @State private var exportURL: URL? = nil
    @State private var showShareSheet: Bool = false
    
    public init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            ChatHeaderView(
                viewModel: viewModel,
                showModelSheet: $showModelSheet,
                exportURL: $exportURL,
                showShareSheet: $showShareSheet
            )
            
            Divider()
            
            // Conversation Body
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.currentSession.messages.count <= 1 {
                            // Empty state with quick suggestions
                            PromptSuggestionsView { selectedPrompt in
                                viewModel.sendMessage(overrideText: selectedPrompt)
                            }
                            .padding(.top, 8)
                        }
                        
                        ForEach(viewModel.currentSession.messages) { msg in
                            MessageBubbleView(
                                message: msg,
                                onRegenerate: msg.isAssistant ? { viewModel.regenerateLastResponse() } : nil,
                                onSpeak: { viewModel.speakMessage(msg) }
                            )
                            .id(msg.id)
                        }
                        
                        Color.clear
                            .frame(height: 12)
                            .id("BottomAnchor")
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: viewModel.currentSession.messages.last?.content) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("BottomAnchor", anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.currentSession.messages.count) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("BottomAnchor", anchor: .bottom)
                    }
                }
            }
            
            // Floating Input Bar
            MessageInputBarView(
                text: $viewModel.inputText,
                isGenerating: viewModel.isGenerating,
                onSend: { viewModel.sendMessage() },
                onStop: { viewModel.cancelGeneration() }
            )
        }
        .background(Color.appGroupedBackground.ignoresSafeArea())
        .sheet(isPresented: $showModelSheet) {
            ModelCatalogSheetView()
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheetView(activityItems: [url])
            }
        }
        #endif
    }
}
