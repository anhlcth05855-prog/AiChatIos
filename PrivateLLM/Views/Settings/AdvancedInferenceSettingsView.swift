import SwiftUI

public struct AdvancedInferenceSettingsView: View {
    @Binding public var config: AppConfiguration
    
    public init(config: Binding<AppConfiguration>) {
        self._config = config
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Provider Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("NGUỒN TRÍ TUỆ NHÂN TẠO (AI ENGINE)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                
                Picker("Engine", selection: $config.selectedProvider) {
                    ForEach(AIProviderType.allCases) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }
            
            // Cloud API settings if enabled
            if config.selectedProvider == .googleGemini {
                VStack(alignment: .leading, spacing: 6) {
                    Text("GEMINI API KEY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    SecureField("Dán Gemini API Key vào đây", text: $config.geminiApiKey)
                        .font(.system(size: 13.5))
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    TextField("Tên mô hình (vd: gemini-1.5-flash)", text: $config.geminiModel)
                        .font(.system(size: 13.5))
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                }
            } else if config.selectedProvider == .openAI {
                VStack(alignment: .leading, spacing: 6) {
                    Text("OPENAI API KEY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    SecureField("sk-...", text: $config.openAiApiKey)
                        .font(.system(size: 13.5))
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    
                    TextField("Tên mô hình (vd: gpt-4o-mini)", text: $config.openAiModel)
                        .font(.system(size: 13.5))
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                }
            }
            
            // Language Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("NGÔN NGỮ PHẢN HỒI ƯU TIÊN")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                
                Picker("Ngôn ngữ", selection: $config.appLanguage) {
                    Text("Tiếng Việt (vi)").tag("vi")
                    Text("English (en)").tag("en")
                    Text("Simplified Chinese (zh)").tag("zh")
                    Text("Japanese (ja)").tag("ja")
                    Text("Korean (ko)").tag("ko")
                    Text("Français (fr)").tag("fr")
                }
                .pickerStyle(MenuPickerStyle())
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }
            
            // Hyperparameters
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Độ ngẫu nhiên (Temperature)")
                        .font(.system(size: 12.5, weight: .medium))
                    Spacer()
                    Text(String(format: "%.2f", config.temperature))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                Slider(value: $config.temperature, in: 0.1...1.5, step: 0.05)
                
                HStack {
                    Text("Top-P Sampling")
                        .font(.system(size: 12.5, weight: .medium))
                    Spacer()
                    Text(String(format: "%.2f", config.topP))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                Slider(value: $config.topP, in: 0.1...1.0, step: 0.05)
            }
            
            // Toggles
            Toggle("Rung phản hồi xúc giác (Haptics)", isOn: $config.hapticsEnabled)
                .font(.system(size: 13.5, weight: .medium))
            
            Toggle("Tự động đọc phản hồi (Text-to-Speech)", isOn: $config.ttsAutoSpeak)
                .font(.system(size: 13.5, weight: .medium))
        }
    }
}
