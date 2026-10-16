import SwiftUI

public struct MessageInputBarView: View {
    @Binding public var text: String
    public let isGenerating: Bool
    public let onSend: () -> Void
    public let onStop: () -> Void
    
    @ObservedObject private var speechManager = AudioSpeechManager.shared
    @FocusState private var isFocused: Bool
    
    public init(
        text: Binding<String>,
        isGenerating: Bool,
        onSend: @escaping () -> Void,
        onStop: @escaping () -> Void
    ) {
        self._text = text
        self.isGenerating = isGenerating
        self.onSend = onSend
        self.onStop = onStop
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(alignment: .bottom, spacing: 10) {
                // Voice Dictation Button
                Button(action: toggleVoiceInput) {
                    Image(systemName: speechManager.isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(speechManager.isRecording ? .red : .secondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(speechManager.isRecording ? Color.red.opacity(0.15) : Color(UIColor.tertiarySystemBackground))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Text Field with Multi-line Support
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text("Nhập câu hỏi hoặc yêu cầu...")
                            .font(.system(size: 15))
                            .foregroundColor(Color.secondary.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    
                    TextEditor(text: $text)
                        .font(.system(size: 15))
                        .frame(minHeight: 36, maxHeight: 110)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .focused($isFocused)
                        .scrollContentBackground(.hidden)
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                
                // Send or Stop Generation Button
                if isGenerating {
                    Button(action: {
                        #if canImport(UIKit)
                        HapticsManager.shared.impact(.medium)
                        #endif
                        onStop()
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    Button(action: {
                        if hasText {
                            onSend()
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(hasText ? Color.accentColor : Color.secondary.opacity(0.35))
                    }
                    .disabled(!hasText)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemBackground))
        }
    }
    
    private func toggleVoiceInput() {
        #if canImport(UIKit)
        HapticsManager.shared.impact(.light)
        #endif
        if speechManager.isRecording {
            speechManager.stopRecording()
        } else {
            speechManager.requestSpeechAuthorization { authorized in
                if authorized {
                    speechManager.startRecording { transcription in
                        self.text = transcription
                    }
                }
            }
        }
    }
}
