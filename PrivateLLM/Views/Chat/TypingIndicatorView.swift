import SwiftUI

public struct TypingIndicatorView: View {
    
    @State private var phase: Double = 0
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.accentColor.opacity(0.85))
                    .frame(width: 7, height: 7)
                    .offset(y: yOffset(for: index))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
    
    private func yOffset(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.2
        return phase == 1 ? -4 : 4
    }
}
