import SwiftUI

public struct MessageBubbleView: View {
    public let message: ChatMessage
    public let onRegenerate: (() -> Void)?
    public let onSpeak: (() -> Void)?
    
    @State private var isCopied: Bool = false
    
    public init(
        message: ChatMessage,
        onRegenerate: (() -> Void)? = nil,
        onSpeak: (() -> Void)? = nil
    ) {
        self.message = message
        self.onRegenerate = onRegenerate
        self.onSpeak = onSpeak
    }
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 44)
                userBubble
            } else {
                assistantBubble
                Spacer(minLength: 32)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(.system(size: 15.5, weight: .regular))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color(red: 0.15, green: 0.45, blue: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(BubbleShape(isUser: true))
                .shadow(color: Color.blue.opacity(0.18), radius: 6, x: 0, y: 3)
            
            Text(message.formattedTime)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.secondary)
                .padding(.trailing, 4)
        }
    }
    
    private var assistantBubble: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Model Header Badge
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.accentColor)
                
                Text(message.modelName ?? "Private LLM")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(Color.secondary)
                
                if let tokens = message.tokenCount, let duration = message.generationDuration {
                    let speed = duration > 0 ? String(format: "%.1f", Double(tokens) / duration) : "30"
                    Text("• \(speed) t/s")
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.secondary.opacity(0.7))
                }
                
                Spacer()
                
                Text(message.formattedTime)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color.secondary.opacity(0.8))
            }
            .padding(.horizontal, 4)
            
            // Content
            if message.content.isEmpty && message.isStreaming.value {
                TypingIndicatorView()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    let segments = MarkdownFormatter.parseSegments(message.content)
                    ForEach(segments) { segment in
                        switch segment.type {
                        case .text:
                            Text(.init(segment.content))
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color.primary)
                                .lineSpacing(3.5)
                                .textSelection(.enabled)
                        case .code(let lang):
                            CodeBlockView(language: lang, code: segment.content)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(BubbleShape(isUser: false))
            }
            
            // Action Bar (Copy, Speak, Regenerate)
            if !message.isStreaming.value && !message.content.isEmpty {
                HStack(spacing: 16) {
                    Button(action: copyContent) {
                        HStack(spacing: 4) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11))
                            Text(isCopied ? "Đã chép" : "Sao chép")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(isCopied ? .green : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { onSpeak?() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 11))
                            Text("Đọc")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if let regen = onRegenerate {
                        Button(action: regen) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11))
                                Text("Tạo lại")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                }
                .padding(.leading, 8)
                .padding(.top, 2)
            }
        }
    }
    
    private func copyContent() {
        #if canImport(UIKit)
        UIPasteboard.general.string = message.content
        HapticsManager.shared.notify(.success)
        #endif
        withAnimation {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopied = false
            }
        }
    }
}

/// Custom iOS Chat Bubble Shape with rounded corners
public struct BubbleShape: Shape {
    public let isUser: Bool
    
    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                isUser ? .bottomLeft : .bottomRight
            ],
            cornerRadii: CGSize(width: 18, height: 18)
        )
        return Path(path.cgPath)
    }
}
