import SwiftUI

public struct HardwareBadgeView: View {
    @ObservedObject private var monitor = HardwareMemoryMonitor.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cpu")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.accentColor)
                
                Text(monitor.currentSpecs.chipFamily)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(monitor.currentSpecs.thermalStatusText)
                    .font(.system(size: 11, weight: .medium))
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("RAM KHẢ DỤNG")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(monitor.currentSpecs.formattedAvailableRam)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("TỔNG BỘ NHỚ")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(monitor.currentSpecs.formattedTotalRam)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}
