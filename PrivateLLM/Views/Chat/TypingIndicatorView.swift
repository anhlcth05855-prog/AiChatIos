import SwiftUI

public struct TypingIndicatorView: View {
    
    @State private var animating: Bool = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.accentColor.opacity(0.85))
                    .frame(width: 7, height: 7)
                    .offset(y: animating ? -4 : 4)
                    .animation(
                        .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.appSecondaryBackground)
        )
        .onAppear {
            animating = true
        }
    }
}
