import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var viewModel = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section {
                    StoreKitPaywallView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                
                Section("ĐỊNH HÌNH PHONG CÁCH TRỢ LÝ") {
                    SystemPromptEditorView(
                        systemPrompt: $viewModel.config.systemPrompt,
                        onSelectPersona: { persona in
                            viewModel.applyPersona(persona)
                        }
                    )
                }
                
                Section("CẤU HÌNH & HIỆU NĂNG NÂNG CAO") {
                    AdvancedInferenceSettingsView(config: $viewModel.config)
                }
                
                Section("QUYỀN RIÊNG TƯ & DỮ LIỆU CỤC BỘ") {
                    Button(action: { viewModel.showResetMemoryAlert = true }) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.orange)
                            Text("Xóa bộ nhớ học tập về người dùng")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(role: .destructive, action: { viewModel.showClearAllAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Xóa sạch toàn bộ lịch sử trò chuyện")
                        }
                    }
                }
                
                Section("THÔNG TIN ỨNG DỤNG") {
                    HStack {
                        Text("Phiên bản")
                        Spacer()
                        Text("2.5.0 (Build 100% Offline)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Bảo mật dữ liệu")
                        Spacer()
                        Text("Zero Cloud Tracking 🔒")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Cài Đặt")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        viewModel.saveConfiguration()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
            .alert("Xóa bộ nhớ người dùng?", isPresented: $viewModel.showResetMemoryAlert) {
                Button("Hủy", role: .cancel) {}
                Button("Xóa", role: .destructive) { viewModel.resetUserMemory() }
            } message: {
                Text("AI sẽ quên các thông tin cá nhân như tên, tuổi, quê quán đã học trong quá trình trò chuyện.")
            }
            .alert("Xóa sạch lịch sử?", isPresented: $viewModel.showClearAllAlert) {
                Button("Hủy", role: .cancel) {}
                Button("Xóa tất cả", role: .destructive) { viewModel.clearAllConversations() }
            } message: {
                Text("Toàn bộ các cuộc trò chuyện đã lưu trên thiết bị sẽ bị xóa vĩnh viễn.")
            }
        }
    }
}
