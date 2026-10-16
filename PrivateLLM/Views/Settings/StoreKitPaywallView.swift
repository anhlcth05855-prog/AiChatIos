import SwiftUI

public struct StoreKitPaywallView: View {
    @ObservedObject private var storeKit = StoreKitManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)
                        Text("MUA MỘT LẦN - DÙNG VĨNH VIỄN")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    Text("Không thu phí định kỳ hàng tháng • Chia sẻ gia đình tối đa 6 người")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if storeKit.isProUnlocked {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            HStack(spacing: 16) {
                Label("100% Offline", systemImage: "airplane")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.secondary)
                
                Label("Mở khóa mọi model", systemImage: "sparkles")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.secondary)
                
                Label("Family Sharing", systemImage: "person.3.fill")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            if !storeKit.isProUnlocked {
                Button(action: {
                    Task { await storeKit.purchaseLifetime() }
                }) {
                    Text(storeKit.availableProduct?.displayPrice ?? "Mở khóa Trọn đời")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.12), Color.orange.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}
