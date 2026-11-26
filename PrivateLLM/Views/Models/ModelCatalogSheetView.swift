import SwiftUI

public struct ModelCatalogSheetView: View {
    @StateObject private var viewModel = ModelManagerViewModel()
    @ObservedObject private var downloadManager = ModelDownloadManager.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Hardware info banner
                    HardwareBadgeView()
                        .padding(.horizontal, 16)
                    
                    // Offline Guide Banner
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "airplane.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                        Text("Tải mô hình 1 lần qua Wi-Fi, sau đó tắt Wi-Fi vẫn chat thông minh 100% On-Device trên chip Apple Silicon (Metal). Gợi ý: Qwen 2.5 Mini (0.5B) hoặc Qwen 3 (1.7B).")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color.accentColor.opacity(0.08))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    
                    if let err = downloadManager.lastErrorMessage {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal, 16)
                    }
                    
                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterChip(title: "Tất cả", family: nil)
                            ForEach(ModelFamily.allCases, id: \.self) { fam in
                                filterChip(title: fam.rawValue, family: fam)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Models List
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredModels) { model in
                            ModelCardView(
                                model: model,
                                isActive: model.id == downloadManager.activeModelId,
                                onSelect: { viewModel.selectActiveModel(model) },
                                onDownload: { viewModel.downloadModel(model) },
                                onCancelDownload: { viewModel.cancelDownload(model) },
                                onDelete: { viewModel.deleteModel(model) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .padding(.top, 12)
            }
            .navigationTitle("Mô Hình On-Device")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Lưu ý phần cứng"),
                    message: Text(viewModel.alertMessage ?? ""),
                    dismissButton: .default(Text("Đã hiểu"))
                )
            }
        }
    }
    
    private func filterChip(title: String, family: ModelFamily?) -> some View {
        let isSelected = viewModel.selectedFamily == family
        return Button(action: {
            #if canImport(UIKit)
            HapticsManager.shared.impact(.light)
            #endif
            viewModel.selectedFamily = family
        }) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.accentColor : Color.appSecondaryBackground)
                .cornerRadius(18)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
