import SwiftUI

public struct SessionListView: View {
    @ObservedObject public var chatViewModel: ChatViewModel
    @StateObject private var listViewModel = SessionsListViewModel()
    @Binding public var showSettings: Bool
    public var onNavigateToChat: (() -> Void)?
    
    public init(
        chatViewModel: ChatViewModel,
        showSettings: Binding<Bool>,
        onNavigateToChat: (() -> Void)? = nil
    ) {
        self.chatViewModel = chatViewModel
        self._showSettings = showSettings
        self.onNavigateToChat = onNavigateToChat
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBarView(text: $listViewModel.searchQuery)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 6)
            
            // List of Sessions
            List {
                let pinned = listViewModel.filteredSessions.filter { $0.isPinned }
                let recent = listViewModel.filteredSessions.filter { !$0.isPinned }
                
                if !pinned.isEmpty {
                    Section("ĐÃ GHIM") {
                        ForEach(pinned) { session in
                            SessionRowView(
                                session: session,
                                isSelected: session.id == chatViewModel.currentSession.id,
                                onSelect: {
                                    chatViewModel.selectSession(session)
                                    onNavigateToChat?()
                                },
                                onPin: { listViewModel.togglePin(session: session) },
                                onRename: { listViewModel.promptRename(session: session) },
                                onDuplicate: { listViewModel.duplicate(session: session) },
                                onDelete: { listViewModel.promptDelete(session: session) }
                            )
                        }
                    }
                }
                
                Section("GẦN ĐÂY") {
                    if recent.isEmpty && pinned.isEmpty {
                        Text("Không tìm thấy cuộc trò chuyện nào")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(recent) { session in
                            SessionRowView(
                                session: session,
                                isSelected: session.id == chatViewModel.currentSession.id,
                                onSelect: {
                                    chatViewModel.selectSession(session)
                                    onNavigateToChat?()
                                },
                                onPin: { listViewModel.togglePin(session: session) },
                                onRename: { listViewModel.promptRename(session: session) },
                                onDuplicate: { listViewModel.duplicate(session: session) },
                                onDelete: { listViewModel.promptDelete(session: session) }
                            )
                        }
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            
            Divider()
            
            // Bottom Action Bar
            HStack {
                Button(action: {
                    #if canImport(UIKit)
                    HapticsManager.shared.impact(.light)
                    #endif
                    showSettings = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
                        Text("Cài đặt")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color.primary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: {
                    chatViewModel.startNewChat()
                    onNavigateToChat?()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Đoạn chat mới")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appSecondaryBackground)
        }
        .navigationTitle("Đoạn Chat")
        .alert("Đổi tên cuộc trò chuyện", isPresented: $listViewModel.showRenameDialog) {
            TextField("Tên mới", text: $listViewModel.newTitleInput)
            Button("Hủy", role: .cancel) {}
            Button("Lưu") { listViewModel.confirmRename() }
        }
        .alert("Xác nhận xóa đoạn chat", isPresented: $listViewModel.showDeleteConfirmation) {
            Button("Hủy", role: .cancel) {}
            Button("Xóa", role: .destructive) { listViewModel.confirmDelete() }
        } message: {
            Text("Bạn có chắc chắn muốn xóa vĩnh viễn cuộc trò chuyện này không? Dữ liệu không thể khôi phục sau khi xóa.")
        }
    }
}
