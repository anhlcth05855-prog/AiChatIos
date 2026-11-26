import SwiftUI

public struct SearchBarView: View {
    @Binding public var text: String
    
    public init(text: Binding<String>) {
        self._text = text
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            TextField("Tìm kiếm tin nhắn & hội thoại...", text: $text)
                .font(.system(size: 14))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.appSecondaryBackground)
        .cornerRadius(10)
    }
}
