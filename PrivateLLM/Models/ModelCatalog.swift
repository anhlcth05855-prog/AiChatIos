import Foundation

public struct ModelCatalog {
    
    public static let recommendedModels: [LocalModelItem] = [
        // 1. Qwen 3 (1.7B) Instruct - Offline Star
        LocalModelItem(
            id: "qwen3-1.7b",
            name: "Qwen 3 (1.7B) Instruct",
            family: .qwen,
            parameterSize: "1.7B",
            quantization: "4-bit GGUF (Q4_K_M)",
            description: "Mô hình Qwen 3 thế hệ mới tối ưu hoàn hảo cho iPhone/iPad. Phản hồi tức thì, hiểu sâu tiếng Việt, văn phong tự nhiên và tốn rất ít RAM.",
            downloadUrl: "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
            sizeBytes: 1_153_433_600, // ~1.15 GB
            requiredRamBytes: 1_782_579_200, // ~1.7 GB
            localFileName: "qwen3-1.7b-instruct-q4_k_m.gguf",
            contextWindow: 8192,
            recommendedHardware: "Tất cả iPhone A15+ (iPhone 13 trở lên), iPad & Mac M1/M2/M3/M4"
        ),
        
        // 2. Qwen 2.5 Mini (0.5B) - Siêu gọn nhẹ
        LocalModelItem(
            id: "qwen2.5-0.5b",
            name: "Qwen 2.5 Mini (0.5B)",
            family: .qwen,
            parameterSize: "0.5B",
            quantization: "4-bit GGUF (Q4_K_M)",
            description: "Mô hình siêu nhẹ chỉ ~380MB, phản hồi chớp nhoáng ~40 tokens/giây trên Apple Neural Engine. Rất thích hợp cho giải đáp nhanh và thiết bị RAM 4GB.",
            downloadUrl: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
            sizeBytes: 398_458_880, // ~380 MB
            requiredRamBytes: 838_860_800, // ~800 MB
            localFileName: "qwen2.5-0.5b-instruct-q4_k_m.gguf",
            contextWindow: 4096,
            recommendedHardware: "Mọi thiết bị iOS (iPhone 11/12/13/14/15/16)"
        ),
        
        // 3. Llama 3.2 1B Instruct - Meta Official
        LocalModelItem(
            id: "llama3.2-1b",
            name: "Llama 3.2 (1B) Instruct",
            family: .llama,
            parameterSize: "1B",
            quantization: "4-bit GGUF (Q4_K_M)",
            description: "Mô hình thế hệ mới nhất của Meta tối ưu riêng cho thiết bị di động Apple. Giàu ngữ cảnh, tóm tắt tài liệu và xử lý logic cực tốt.",
            downloadUrl: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf",
            sizeBytes: 880_803_840, // ~840 MB
            requiredRamBytes: 1_468_006_400, // ~1.4 GB
            localFileName: "llama-3.2-1b-instruct-q4_k_m.gguf",
            contextWindow: 8192,
            recommendedHardware: "iPhone 12 trở lên, iPad A14+"
        ),
        
        // 4. Llama 3.2 3B Instruct - High Intelligence
        LocalModelItem(
            id: "llama3.2-3b",
            name: "Llama 3.2 (3B) Instruct",
            family: .llama,
            parameterSize: "3B",
            quantization: "4-bit GGUF (Q4_K_M)",
            description: "Phiên bản 3 tỷ tham số cao cấp của Meta. Khả năng viết lách, lý luận phức tạp và tư vấn chuyên sâu vượt trội.",
            downloadUrl: "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf",
            sizeBytes: 2_097_152_000, // ~2.0 GB
            requiredRamBytes: 3_145_728_000, // ~3.0 GB
            localFileName: "llama-3.2-3b-instruct-q4_k_m.gguf",
            contextWindow: 8192,
            recommendedHardware: "iPhone 15 Pro, iPhone 16 series, iPad Pro M-series, Mac"
        ),
        
        // 5. DeepSeek R1 Distill (1.5B) - Reasoning Master
        LocalModelItem(
            id: "deepseek-r1-1.5b",
            name: "DeepSeek R1 Distill (1.5B)",
            family: .deepseek,
            parameterSize: "1.5B",
            quantization: "4-bit GGUF (Q4_K_M)",
            description: "Mô hình suy luận từng bước (Chain of Thought) nổi tiếng của DeepSeek. Xuất sắc trong giải toán, logic, lập trình và suy ngẫm trước khi kết luận.",
            downloadUrl: "https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf",
            sizeBytes: 1_174_405_120, // ~1.12 GB
            requiredRamBytes: 1_887_436_800, // ~1.8 GB
            localFileName: "deepseek-r1-distill-qwen-1.5b-q4_k_m.gguf",
            contextWindow: 16384,
            recommendedHardware: "iPhone 13 trở lên, Mac Apple Silicon"
        ),
        
        // 6. Google Gemma 2 (2B) Instruct
        LocalModelItem(
            id: "gemma2-2b",
            name: "Google Gemma 2 (2B) Instruct",
            family: .gemma,
            parameterSize: "2B",
            quantization: "4-bit GGUF (Q4_K_M)",
            description: "Mô hình mã nguồn mở thế hệ 2 từ Google DeepMind. Tối ưu cấu trúc trượt sliding window attention, kiến thức phong phú và chuẩn xác.",
            downloadUrl: "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf",
            sizeBytes: 1_677_721_600, // ~1.6 GB
            requiredRamBytes: 2_621_440_000, // ~2.5 GB
            localFileName: "gemma-2-2b-it-q4_k_m.gguf",
            contextWindow: 8192,
            recommendedHardware: "iPhone 14 Pro trở lên hoặc iPad M1+"
        ),
        
        // 7. Microsoft Phi-3.5 Mini (3.8B) Instruct
        LocalModelItem(
            id: "phi-3.5-mini",
            name: "Phi-3.5 Mini (3.8B)",
            family: .phi,
            parameterSize: "3.8B",
            quantization: "4-bit GGUF (Q4_K_M)",
            description: "Mô hình nhỏ nhưng mạnh mẽ hàng đầu từ Microsoft Research, hỗ trợ ngữ cảnh lớn lên tới 32k tokens, phân tích văn bản dài xuất sắc.",
            downloadUrl: "https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q4_K_M.gguf",
            sizeBytes: 2_306_867_200, // ~2.2 GB
            requiredRamBytes: 3_670_016_000, // ~3.5 GB
            localFileName: "phi-3.5-mini-instruct-q4_k_m.gguf",
            contextWindow: 32768,
            recommendedHardware: "iPhone 15 Pro, iPhone 16 Pro, iPad Pro M-series, Mac"
        ),
        
        // 8. Mistral 7B Instruct v0.3 - Flagship Power
        LocalModelItem(
            id: "mistral-7b",
            name: "Mistral (7B) Instruct v0.3",
            family: .mistral,
            parameterSize: "7B",
            quantization: "4-bit GGUF (Q4_K_M)",
            description: "Mô hình đỉnh cao 7B từ Mistral AI. Phù hợp cho iPad Pro và Mac Apple Silicon với RAM 8GB/16GB+ cho nhu cầu nghiên cứu sâu.",
            downloadUrl: "https://huggingface.co/bartowski/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf",
            sizeBytes: 4_372_561_920, // ~4.1 GB
            requiredRamBytes: 5_767_168_000, // ~5.5 GB
            localFileName: "mistral-7b-instruct-v0.3-q4_k_m.gguf",
            contextWindow: 32768,
            recommendedHardware: "iPad Pro M1/M2/M4 hoặc Mac Apple Silicon (8GB+ RAM)"
        )
    ]
    
    public static func model(for id: String) -> LocalModelItem? {
        recommendedModels.first { $0.id == id }
    }
    
    public static var defaultModel: LocalModelItem {
        recommendedModels[0] // Qwen 3 (1.7B)
    }
}
