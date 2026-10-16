# Private LLM - Local AI Chat (iOS / iPadOS / macOS)

Ứng dụng **Private LLM - Local AI Chat** phiên bản iOS hoàn chỉnh, được phát triển 100% bằng **Swift & SwiftUI** hiện đại (iOS 17+, iPadOS 17+, macOS Sonoma/Sequoia trên chip Apple Silicon M1/M2/M3/M4/A16/A17 Pro/A18). Ứng dụng lấy cảm hứng từ ứng dụng nổi tiếng trên App Store [Private LLM](https://apps.apple.com/us/app/private-llm-local-ai-chat/id6448106860?l=vi) và chuyển thể, nâng cấp toàn diện từ dự án mẫu Android [chatbotAIandroid](https://gitlab.com/Binn208/chatbotaiandroid).

---

## 🌟 5 Trụ Cột Tính Năng Nổi Bật

### 1. 100% On-Device & Offline (Bảo mật tuyệt đối)
- **Zero Cloud Tracking**: Mọi quá trình suy luận và sinh token diễn ra trực tiếp ngay trên thiết bị. Không có bất kỳ dữ liệu, câu hỏi hay ngữ cảnh nào được truyền ra Internet.
- **Hoạt động không cần mạng**: Hoạt động mượt mà khi đi máy bay, vùng không có sóng hoặc khi tắt hoàn toàn Wi-Fi/4G.
- **Giám sát phần cứng thời gian thực**: Đo lường bộ nhớ RAM thực tế (`os_proc_available_memory()`), trạng thái nhiệt độ máy (`thermalState`) và tính toán an toàn trước khi nạp trọng số mô hình lớn.

### 2. Hỗ trợ Đa dạng Mô hình Mã nguồn mở (Open-Source LLMs)
- Hỗ trợ danh mục các mô hình AI tiên tiến nhất hiện nay:
  - **Qwen 3 (1.7B) Instruct**: Cực nhanh, thông minh, hiểu sâu tiếng Việt và đời sống.
  - **Qwen 2.5 Mini (0.5B)**: Siêu nhẹ (~380MB), phản hồi chớp nhoáng trên mọi iPhone.
  - **Llama 3.2 (1B & 3B) Instruct**: Mô hình thế hệ mới chính thức từ Meta, tối ưu tóm tắt và suy luận logic.
  - **DeepSeek R1 Distill (1.5B)**: Mô hình suy luận từng bước (Chain of Thought) xuất sắc trong giải toán và phân tích.
  - **Google Gemma 2 (2B) Instruct**: Mô hình từ Google DeepMind với cấu trúc trượt sliding window attention.
  - **Microsoft Phi-3.5 Mini (3.8B)** & **Mistral 7B Instruct v0.3**: Mô hình ngữ cảnh lớn (32k tokens) cho iPad Pro và Mac Apple Silicon.
- **Tự động lưu và nhận diện mô hình**: Mỗi cuộc trò chuyện tự động ghi nhớ mô hình AI tương ứng khi bạn mở lại.
- **Quản lý tải xuống**: Hỗ trợ tải ngầm qua `URLSession`, thanh tiến trình, hiển thị dung lượng và dọn dẹp bộ nhớ máy.

### 3. Tích hợp sâu vào Hệ sinh thái Apple
- **Siri & Apple Shortcuts (App Intents)**:
  - Câu lệnh Siri: *"Hey Siri, hỏi Private LLM [câu hỏi]"*.
  - Shortcut action: `AskPrivateLLMIntent` và `SummarizeOfflineIntent` cho phép tự động hóa tóm tắt văn bản và phân tích dữ liệu không cần mạng.
- **Tương thích đa nền tảng (Adaptive SwiftUI)**:
  - Thiết kế `NavigationSplitView` co giãn linh hoạt: giao diện gọn gàng trên iPhone, chia 2-3 cột trực quan trên iPad và Mac Apple Silicon.
- **Giọng nói 2 chiều (Bidirectional Audio)**:
  - Nhập liệu bằng giọng nói (`SFSpeechRecognizer`).
  - Đọc phản hồi tự nhiên qua Text-to-Speech (`AVSpeechSynthesizer`) hỗ trợ đa ngôn ngữ (Tiếng Việt, Anh, Trung, Nhật, Hàn, Pháp).

### 4. Quản lý Hội thoại & Xuất Dữ liệu (Chat Management & Export)
- **Quản lý đa phiên (Multi-Thread Sessions)**: Tạo mới, đổi tên, nhân bản, ghim lên đầu (Pin) và xóa với hộp thoại xác nhận an toàn.
- **Tìm kiếm toàn văn (Full-Text Search)**: Thanh tìm kiếm theo thời gian thực tìm nhanh qua tiêu đề và nội dung tin nhắn.
- **Xuất dữ liệu 2 định dạng**:
  - **Xuất ra PDF (`PDFExportService`)**: Kết xuất văn bản và bong bóng chat thành file PDF chuyên nghiệp qua `UIGraphicsPDFRenderer`.
  - **Xuất ra Markdown (`MarkdownExportService`)**: Lưu lại file `.md` chuẩn cú pháp để chia sẻ qua AirDrop, Mail, Ghi chú, Files.
- **Tùy chỉnh Lời nhắc Hệ thống (System Prompt & Personas)**:
  - 5 cấu hình phong cách mẫu: *Trợ lý đời sống*, *Chuyên gia Swift & Apple*, *Gia sư Logic & Toán*, *Cố vấn Thủ tục & Bằng lái*, *Nhà văn sáng tạo*.
  - Cho phép tinh chỉnh `Temperature`, `Top-P` và `Max Tokens`.

### 5. Mô hình Thanh toán & Quyền riêng tư (StoreKit 2)
- **"Mua một lần, dùng vĩnh viễn" (Lifetime Pro Unlock)**: Tích hợp StoreKit 2 hiện đại, không thu phí định kỳ, không bắt buộc đăng ký tài khoản hay API Key.
- **Chia sẻ gia đình (Family Sharing)**: Hỗ trợ tối đa 6 thành viên trong gia đình dùng chung bản quyền theo chính sách của Apple.

---

## 📁 Cấu Trúc Thư Mục Dự Án

```
PrivateLLM/
├── PrivateLLM.xcodeproj/
│   └── project.pbxproj               # File cấu hình dự án Xcode
├── Package.swift                     # Cấu hình Swift Package Manager
├── App/
│   ├── PrivateLLMApp.swift           # Điểm khởi chạy ứng dụng SwiftUI
│   ├── Info.plist                    # Quyền truy cập micrô, giọng nói & cờ bảo mật
│   └── Assets.xcassets/              # Asset Catalogs: Màu nhấn (AccentColor) & AppIcon
├── Models/
│   ├── ChatMessage.swift             # Model tin nhắn (User, Assistant, Status)
│   ├── ChatSession.swift             # Model luồng hội thoại & liên kết mô hình
│   ├── LocalModelItem.swift          # Model thông số kỹ thuật LLM nội bộ
│   ├── ModelCatalog.swift            # Danh mục các mô hình Llama, Qwen, DeepSeek, Gemma, Phi, Mistral
│   ├── SystemPersona.swift           # Các mẫu nhân cách AI định sẵn
│   └── APIConfiguration.swift        # Cấu hình tham số suy luận & API Cloud
├── Engines/
│   ├── LLMInferenceEngine.swift      # Protocol streaming token suy luận
│   ├── MetalLLMEngine.swift          # Bộ máy suy luận tăng tốc Metal / Apple Silicon
│   ├── OfflineKnowledgeEngine.swift  # Bộ não Offline tích hợp sâu (Đời sống, A1, giấc ngủ, văn hóa...)
│   ├── CloudGeminiEngine.swift       # Client Google Gemini API (Tuỳ chọn so sánh)
│   ├── CloudOpenAIEngine.swift       # Client OpenAI API (Tuỳ chọn so sánh)
│   └── AudioSpeechManager.swift      # Quản lý giọng nói 2 chiều (TTS & STT)
├── Repositories/
│   ├── ChatStorageRepository.swift   # Lưu trữ và tìm kiếm hội thoại cục bộ
│   ├── ModelDownloadManager.swift    # Quản lý tải và xóa trọng số mô hình
│   ├── HardwareMemoryMonitor.swift   # Giám sát RAM và trạng thái nhiệt Apple
│   └── StoreKitManager.swift         # Quản lý thanh toán StoreKit 2 trọn đời
├── Intents/
│   ├── AskPrivateLLMIntent.swift     # Lệnh tương tác Siri & Shortcuts
│   ├── SummarizeOfflineIntent.swift  # Tác vụ tóm tắt văn bản Shortcuts
│   └── PrivateLLMShortcutsProvider.swift # Đăng ký câu thoại Siri hệ thống
├── Utilities/
│   ├── MarkdownFormatter.swift       # Phân tích khối code, syntax highlighting
│   ├── PDFExportService.swift        # Kết xuất tài liệu PDF chất lượng cao
│   ├── MarkdownExportService.swift   # Xuất file hội thoại .md
│   └── HapticsManager.swift          # Phản hồi xúc giác chuẩn Apple
├── ViewModels/
│   ├── ChatViewModel.swift           # Điều khiển luồng chat và sinh từ
│   ├── ModelManagerViewModel.swift   # Quản lý bộ lọc mô hình và tải về
│   ├── SessionsListViewModel.swift   # Quản lý danh sách hội thoại và tìm kiếm
│   └── SettingsViewModel.swift       # Quản lý cấu hình và nhân cách
└── Views/
    ├── MainSplitNavigationView.swift # Layout NavigationSplitView tương thích đa thiết bị
    ├── Sidebar/
    │   ├── SessionListView.swift     # Giao diện danh sách phiên chat
    │   ├── SessionRowView.swift      # Hàng hiển thị chi tiết cuộc trò chuyện
    │   └── SearchBarView.swift       # Thanh tìm kiếm thời gian thực
    ├── Chat/
    │   ├── ChatView.swift            # Khung chat chính với ScrollViewReader
    │   ├── MessageBubbleView.swift   # Bong bóng chat hiển thị văn bản & code
    │   ├── TypingIndicatorView.swift # Hiệu ứng ba chấm xoay mượt mà
    │   ├── CodeBlockView.swift       # Khung mã nguồn kèm nút sao chép
    │   ├── PromptSuggestionsView.swift# 4 thẻ câu hỏi gợi ý nhanh
    │   ├── MessageInputBarView.swift # Thanh nhập liệu và micrô giọng nói
    │   └── ChatHeaderView.swift      # Thanh tiêu đề và menu xuất file
    ├── Models/
    │   ├── ModelCatalogSheetView.swift# Modal duyệt mô hình mã nguồn mở
    │   ├── ModelCardView.swift       # Thẻ thông số chi tiết mô hình
    │   └── HardwareBadgeView.swift   # Huy hiệu thông số RAM và chip Apple
    ├── Settings/
    │   ├── SettingsView.swift        # Màn hình cài đặt tổng hợp
    │   ├── StoreKitPaywallView.swift # Banner mua trọn đời & Family Sharing
    │   ├── SystemPromptEditorView.swift # Trình biên soạn System Prompt
    │   └── AdvancedInferenceSettingsView.swift # Tham số nhiệt độ, top-p, API key
    └── Export/
        └── ShareSheetView.swift      # Trình chia sẻ file hệ thống iOS
```

---

## 🚀 Hướng Dẫn Mở & Chạy Dự Án Trên Xcode

### Yêu cầu cấu hình:
- **macOS**: Sonoma (14.0) hoặc Sequoia (15.0 trở lên).
- **Xcode**: 15.0 trở lên (khuyên dùng Xcode 15.2 hoặc 16.0).
- **Thiết bị chạy thử**:
  - Trình giả lập iOS Simulator: iPhone 15/16 Pro, iPad Pro.
  - Thiết bị thật: iPhone (A15 Bionic trở lên như iPhone 13/14/15/16), iPad (A14 / M1 trở lên), Mac (Apple Silicon M1 trở lên).

### Các bước thực hiện:
1. Mở thư mục dự án `PrivateLLM` trên máy Mac.
2. Nhấp đúp vào tệp **`PrivateLLM.xcodeproj`** để mở trực tiếp trong Xcode.
3. Chọn thiết bị mục tiêu (ví dụ: **iPhone 16 Pro** hoặc **iPad Pro (11-inch)**).
4. Nhấn tổ hợp phím **`Cmd + R`** (hoặc nút **Play**) để biên dịch và chạy ứng dụng.
5. Trải nghiệm ngay trí tuệ nhân tạo Offline cục bộ với đầy đủ tính năng: Chat, Tải mô hình, Đọc giọng nói, Xuất PDF/Markdown và Lệnh Siri Shortcuts!
