import SwiftUI

public struct ChatHeaderView: View {
    @ObservedObject public var viewModel: ChatViewModel
    @Binding public var showModelSheet: Bool
    @Binding public var exportURL: URL?
    @Binding public var showShareSheet: Bool
    
    public init(
        viewModel: ChatViewModel,
        showModelSheet: Binding<Bool>,
        exportURL: Binding<URL?>,
        showShareSheet: Binding<Bool>
    ) {
        self.viewModel = viewModel
        self._showModelSheet = showModelSheet
        self._exportURL = exportURL
        self._showShareSheet = showShareSheet
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // Model Selector Capsule
            Button(action: {
                #if canImport(UIKit)
                HapticsManager.shared.impact(.light)
                #endif
                showModelSheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.accentColor)
                    
                    let activeModel = viewModel.modelDownloadManager.getActiveModel()
                    VStack(alignment: .leading, spacing: 0) {
                        Text(activeModel.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.primary)
                            .lineLimit(1)
                        Text("100% On-Device & Offline")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(Color.secondary)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Export Menu (PDF / Markdown)
            Menu {
                Section("Xuất Dữ Liệu Hội Thoại") {
                    Button(action: exportAsPDF) {
                        Label("Xuất ra PDF", systemImage: "doc.richtext")
                    }
                    Button(action: exportAsMarkdown) {
                        Label("Xuất ra Markdown (.md)", systemImage: "arrow.down.doc")
                    }
                }
                
                Section {
                    Button(action: { viewModel.startNewChat() }) {
                        Label("Đoạn chat mới", systemImage: "square.and.pencil")
                    }
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.accentColor)
                    .frame(width: 34, height: 34)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
    
    private func exportAsPDF() {
        #if canImport(UIKit)
        if let url = PDFExportService.generatePDF(from: viewModel.currentSession) {
            exportURL = url
            showShareSheet = true
            HapticsManager.shared.notify(.success)
        }
        #endif
    }
    
    private func exportAsMarkdown() {
        if let url = MarkdownExportService.generateMarkdown(from: viewModel.currentSession) {
            exportURL = url
            showShareSheet = true
            #if canImport(UIKit)
            HapticsManager.shared.notify(.success)
            #endif
        }
    }
}
