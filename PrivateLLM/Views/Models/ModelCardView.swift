import SwiftUI

public struct ModelCardView: View {
    public let model: LocalModelItem
    public let isActive: Bool
    public let onSelect: () -> Void
    public let onDownload: () -> Void
    public let onDelete: () -> Void
    
    public init(
        model: LocalModelItem,
        isActive: Bool,
        onSelect: @escaping () -> Void,
        onDownload: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.model = model
        self.isActive = isActive
        self.onSelect = onSelect
        self.onDownload = onDownload
        self.onDelete = onDelete
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row
            HStack(alignment: .top) {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: model.family.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.accentColor)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(model.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if isActive {
                            Text("ĐANG DÙNG")
                                .font(.system(size: 9.5, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .cornerRadius(6)
                        }
                    }
                    
                    Text("\(model.family.rawValue) • \(model.parameterSize) • \(model.quantization)")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(model.description)
                .font(.system(size: 12.5))
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Specs Badges
            HStack(spacing: 12) {
                Label(model.formattedSize, systemImage: "arrow.down.circle")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.secondary)
                
                Label("Cần \(model.formattedRequiredRam) RAM", systemImage: "memorychip")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Progress Bar if Downloading
            if model.status == .downloading {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: model.downloadProgress, total: 1.0)
                        .tint(Color.accentColor)
                    
                    HStack {
                        Text("Đang tải dữ liệu...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(model.downloadProgress * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 10) {
                if model.isDownloaded {
                    if !isActive {
                        Button(action: onSelect) {
                            Text("Kích hoạt sử dụng")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color.accentColor)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            Text("Đang kích hoạt")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(7)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                } else if model.status != .downloading {
                    Button(action: onDownload) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.to.line")
                                .font(.system(size: 12, weight: .bold))
                            Text("Tải mô hình")
                                .font(.system(size: 12.5, weight: .semibold))
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.accentColor.opacity(0.12))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isActive ? Color.accentColor : Color.primary.opacity(0.04), lineWidth: isActive ? 1.5 : 1)
        )
    }
}
