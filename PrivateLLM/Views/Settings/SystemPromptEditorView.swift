import SwiftUI

public struct SystemPromptEditorView: View {
    @Binding public var systemPrompt: String
    public let onSelectPersona: (SystemPersona) -> Void
    
    public init(systemPrompt: Binding<String>, onSelectPersona: @escaping (SystemPersona) -> Void) {
        self._systemPrompt = systemPrompt
        self.onSelectPersona = onSelectPersona
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HÌNH TƯỢNG TRỢ LÝ (PERSONA PRESETS)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SystemPersona.defaults) { persona in
                        Button(action: {
                            #if canImport(UIKit)
                            HapticsManager.shared.impact(.light)
                            #endif
                            onSelectPersona(persona)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: persona.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(.accentColor)
                                Text(persona.title)
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.appSecondaryBackground)
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Text("TÙY CHỈNH LỜI NHẮC HỆ THỐNG (SYSTEM PROMPT)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.top, 6)
            
            TextEditor(text: $systemPrompt)
                .font(.system(size: 13.5))
                .frame(minHeight: 90)
                .padding(8)
                .background(Color.appSecondaryBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        }
    }
}
