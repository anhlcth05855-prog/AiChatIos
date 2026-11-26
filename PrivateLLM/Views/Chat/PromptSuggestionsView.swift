import SwiftUI

public struct PromptSuggestionItem: Identifiable {
    public let id = UUID()
    public let icon: String
    public let title: String
    public let prompt: String
    public let color: Color
}

public struct PromptSuggestionsView: View {
    public let onSelectPrompt: (String) -> Void
    
    public let suggestions: [PromptSuggestionItem] = [
        PromptSuggestionItem(
            icon: "fork.knife",
            title: "Hôm nay nên ăn món gì ngon?",
            prompt: "Hôm nay nên ăn món gì ngon? Hãy gợi ý cho tôi vài món nước và món cơm thơm ngon, dễ chọn nhé!",
            color: .orange
        ),
        PromptSuggestionItem(
            icon: "car.fill",
            title: "Mẹo thi bằng lái xe máy A1",
            prompt: "Thủ tục và kinh nghiệm thi bằng lái xe máy A1 trọn bộ lý thuyết và thực hành vòng số 8",
            color: .blue
        ),
        PromptSuggestionItem(
            icon: "moon.stars.fill",
            title: "Bí quyết giấc ngủ ngon & sâu",
            prompt: "Bí quyết để có giấc ngủ ngon và sâu, hãy hướng dẫn quy tắc 10-3-2-1 và bài tập thở 4-7-8",
            color: .indigo
        ),
        PromptSuggestionItem(
            icon: "face.smiling.fill",
            title: "Kể chuyện cười xả stress",
            prompt: "Kể cho tôi một câu chuyện cười vui vẻ đời thường và một câu đố hại não để giải tỏa căng thẳng",
            color: .green
        )
    ]
    
    public init(onSelectPrompt: @escaping (String) -> Void) {
        self.onSelectPrompt = onSelectPrompt
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GỢI Ý CÂU HỎI NHANH")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(suggestions) { item in
                    Button(action: {
                        #if canImport(UIKit)
                        HapticsManager.shared.impact(.light)
                        #endif
                        onSelectPrompt(item.prompt)
                    }) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(item.color.opacity(0.15))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: item.icon)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(item.color)
                                )
                            
                            Text(item.title)
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(Color.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(Color.appSecondaryBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
