import SwiftUI

public struct ModelCatalogSheetView: View {
    @StateObject private var viewModel = ModelManagerViewModel()
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Hardware info banner
                    HardwareBadgeView()
                        .padding(.horizontal, 16)
                    
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
                                isActive: model.id == viewModel.downloadManager.activeModelId,
                                onSelect: { viewModel.selectActiveModel(model) },
                                onDownload: { viewModel.downloadModel(model) },
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
