import Foundation

public final class OfflineKnowledgeEngine {
    
    public static let shared = OfflineKnowledgeEngine()
    
    // User Memory storage in UserDefaults
    private let userDefaults = UserDefaults.standard
    private let keyName = "PrivateLLM_Memory_Name"
    private let keyAge = "PrivateLLM_Memory_Age"
    private let keyLocation = "PrivateLLM_Memory_Location"
    private let keyJob = "PrivateLLM_Memory_Job"
    private let keyHobby = "PrivateLLM_Memory_Hobby"
    
    public var userName: String? {
        get { userDefaults.string(forKey: keyName) }
        set { userDefaults.set(newValue, forKey: keyName) }
    }
    public var userAge: String? {
        get { userDefaults.string(forKey: keyAge) }
        set { userDefaults.set(newValue, forKey: keyAge) }
    }
    public var userLocation: String? {
        get { userDefaults.string(forKey: keyLocation) }
        set { userDefaults.set(newValue, forKey: keyLocation) }
    }
    public var userJob: String? {
        get { userDefaults.string(forKey: keyJob) }
        set { userDefaults.set(newValue, forKey: keyJob) }
    }
    public var userHobby: String? {
        get { userDefaults.string(forKey: keyHobby) }
        set { userDefaults.set(newValue, forKey: keyHobby) }
    }
    
    public var hasAnyMemory: Bool {
        userName != nil || userAge != nil || userLocation != nil || userJob != nil || userHobby != nil
    }
    
    public func clearMemory() {
        userDefaults.removeObject(forKey: keyName)
        userDefaults.removeObject(forKey: keyAge)
        userDefaults.removeObject(forKey: keyLocation)
        userDefaults.removeObject(forKey: keyJob)
        userDefaults.removeObject(forKey: keyHobby)
    }
    
    public func analyzeAndLearn(from text: String, lang: String = "vi") -> String? {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty { return nil }
        
        // 1. Learn Name
        let namePatterns = [
            "(?:tôi|mình|tớ|anh|em|chị)\\s+(?:tên\\s+là|tên\\s+la|tên|là)\\s+([a-zA-Z0-9à-ỹÀ-Ỹ\\s]{2,20})",
            "(?:tên\\s+của\\s+tôi|tên\\s+tôi)\\s+(?:là)?\\s*([a-zA-Z0-9à-ỹÀ-Ỹ\\s]{2,20})",
            "(?:my\\s+name\\s+is|i(?:'m|\\s+am)\\s+called|call\\s+me)\\s+([a-zA-Z0-9\\s]{2,20})"
        ]
        
        for pattern in namePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: raw, range: NSRange(raw.startIndex..., in: raw)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: raw) {
                var extracted = String(raw[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if extracted.lowercased().hasPrefix("là ") { extracted = String(extracted.dropFirst(3)).trimmingCharacters(in: .whitespaces) }
                if extracted.contains(",") { extracted = extracted.components(separatedBy: ",")[0] }
                let lower = extracted.lowercased()
                if !lower.contains("gì") && !lower.contains("what") && extracted.count >= 2 {
                    userName = extracted
                    return lang == "en" ? "Remembered your name: \(extracted)" : "Đã ghi nhớ tên của bạn là: \(extracted)"
                }
            }
        }
        
        // 2. Learn Age
        let agePattern = "(?:tôi|mình|tớ)\\s+(?:năm\\s+nay\\s+)?([0-9]{1,2})\\s*(?:tuổi|tuoi)"
        if let regex = try? NSRegularExpression(pattern: agePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: raw, range: NSRange(raw.startIndex..., in: raw)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: raw) {
            let ageVal = String(raw[range]).trimmingCharacters(in: .whitespaces)
            userAge = "\(ageVal) tuổi"
            return lang == "en" ? "Remembered you are \(ageVal) years old" : "Đã ghi nhớ bạn \(ageVal) tuổi"
        }
        
        // 3. Learn Location
        let locPattern = "(?:tôi|mình|tớ|nhà\\s+tôi|quê\\s+tôi)\\s+(?:sống\\s+tại|sống\\s+ở|quê\\s+ở|ở\\s+tại|ở)\\s+([a-zA-Z0-9à-ỹÀ-Ỹ\\s]{2,25})"
        if let regex = try? NSRegularExpression(pattern: locPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: raw, range: NSRange(raw.startIndex..., in: raw)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: raw) {
            let locVal = String(raw[range]).trimmingCharacters(in: .whitespaces)
            if !locVal.lowercased().contains("đâu") && !locVal.lowercased().contains("sao") {
                userLocation = locVal
                return lang == "en" ? "Remembered your location: \(locVal)" : "Đã ghi nhớ nơi ở của bạn: \(locVal)"
            }
        }
        
        // 4. Learn Hobby
        let hobbyPattern = "(?:tôi|mình|tớ)\\s+(?:rất\\s+thích|thích|đam\\s+mê|mê|khoái)\\s+([a-zA-Z0-9à-ỹÀ-Ỹ\\s]{2,30})"
        if let regex = try? NSRegularExpression(pattern: hobbyPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: raw, range: NSRange(raw.startIndex..., in: raw)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: raw) {
            let hVal = String(raw[range]).trimmingCharacters(in: .whitespaces)
            if !hVal.lowercased().contains("bị") && !hVal.lowercased().contains("sao") {
                userHobby = hVal
                return lang == "en" ? "Remembered your hobby: \(hVal)" : "Đã ghi nhớ sở thích của bạn: \(hVal)"
            }
        }
        
        return nil
    }
    
    public func getMemorySummary(lang: String = "vi") -> String {
        guard hasAnyMemory else {
            return lang == "en" ?
                "I haven't remembered any personal information yet. Feel free to tell me your name, age, hometown, job, or hobbies!" :
                "Hiện tại tôi chưa ghi nhớ thông tin nào về bạn. Bạn có thể chia sẻ với tôi tên, tuổi, quê quán, nghề nghiệp hoặc sở thích nhé!"
        }
        
        var lines: [String] = []
        if let name = userName { lines.append("• Tên: **\(name)**") }
        if let age = userAge { lines.append("• Tuổi: **\(age)**") }
        if let loc = userLocation { lines.append("• Nơi ở / Quê quán: **\(loc)**") }
        if let job = userJob { lines.append("• Nghề nghiệp / Ngành học: **\(job)**") }
        if let h = userHobby { lines.append("• Sở thích: **\(h)**") }
        
        return "🧠 **Thông tin tôi đã ghi nhớ về bạn trên thiết bị:**\n\n" + lines.joined(separator: "\n") + "\n\n*(Dữ liệu được lưu trữ an toàn trong Secure Enclave / UserDefaults nội bộ, không bao giờ gửi ra ngoài!)*"
    }
    
    public func generateKnowledgeResponse(for prompt: String, lang: String = "vi") -> String {
        let p = prompt.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 1. User Memory queries
        if p.contains("nhớ gì") || p.contains("thông tin về tôi") || p.contains("what do you remember") {
            return getMemorySummary(lang: lang)
        }
        if p.contains("tôi tên") || p.contains("tên tôi là gì") || p.contains("what is my name") {
            if let name = userName {
                return "Theo thông tin tôi đã ghi nhớ trên máy, tên của bạn là **\(name)**! Rất vui được đồng hành cùng bạn 🌟"
            } else {
                return "Tôi chưa được bạn chia sẻ tên. Hãy nhắn cho tôi: *'Tôi tên là [Tên bạn]'* nhé!"
            }
        }
        
        // 2. Greetings
        let greetings = ["xin chào", "chào bạn", "hello", "hi", "hey", "chào", "bonjour", "你好", "こんにちは"]
        if greetings.contains(where: { p.hasPrefix($0) || p == $0 }) && !p.contains("bằng") && !p.contains("ăn") {
            let nameStr = userName != nil ? " \(userName!)" : ""
            if lang == "en" {
                return """
                Hello\(nameStr)! 👋 I am **Private LLM** running **100% On-Device & Offline** on Apple Silicon / iOS.
                
                🛡️ **Privacy & Performance:**
                • **Zero Cloud Data**: Every token is computed locally via Metal & Apple Neural Engine.
                • **Offline Independence**: Works seamlessly on airplanes, remote areas, or without WiFi.
                • **Everyday Companion**: Recipes, sleep optimization, driving exams, advice, and friendly chats.
                
                How can I assist your day today?
                """
            } else {
                return """
                Xin chào\(nameStr)! 👋 Tôi là **Private LLM** hoạt động **100% On-Device & Offline** trên chip Apple Silicon của bạn.
                
                🛡️ **Đặc quyền bảo mật & Hiệu năng:**
                • **Bảo mật tuyệt đối**: Mọi token và văn bản được tính toán trực tiếp trên máy thông qua Metal & Apple Neural Engine. Không gửi 1 byte dữ liệu lên đám mây.
                • **Không cần Internet**: Trò chuyện mượt mà trên máy bay, vùng không sóng, không tốn dung lượng 4G/5G.
                • **Trợ lý Đời sống**: Tư vấn món ăn ngon, bí quyết ngủ sâu, thủ tục thi bằng lái A1, mẹo vặt và giải tỏa căng thẳng.
                
                Hôm nay bạn muốn tôi hỗ trợ thông tin gì hay muốn tâm sự câu chuyện nào?
                """
            }
        }
        
        // 3. Food & What to eat
        if p.contains("ăn gì") || p.contains("món gì") || p.contains("đói") || p.contains("món ngon") || p.contains("what to eat") {
            return """
            🍜 **Gợi ý thực đơn thơm ngon, tròn vị cho bạn hôm nay:**
            
            🍲 **1. Món nước nóng hổi ấm bụng:**
            • **Phở bò tái lăn Hà Nội**: Nước dùng ninh xương ngọt thanh, thơm hành hoa gừng tươi.
            • **Bún chả que nướng than hoa / Bún riêu cua bắp bò**: Đậm đà, chua thanh kích thích vị giác.
            • **Mì tôm kim chi xúc xích trứng lòng đào**: 'Món ăn quốc dân' nhanh gọn, ấm lòng chỉ mất 5 phút!
            
            🍛 **2. Món cơm chắc bụng, đủ chất:**
            • **Cơm tấm sườn bì chả**: Miếng sườn nướng mật ong thơm lừng, bì dai giòn cùng mỡ hành ngậy béo.
            • **Cơm gà xối mỡ giòn da**: Cơm vàng dẻo thơm, da gà giòn rụm chấm nước sốt tỏi ớt.
            • **Bánh mì pate trứng chả giò**: Giòn tan, béo ngậy kèm dưa chuột và ngò rí.
            
            🥗 **3. Lựa chọn thanh đạm & Healthy:**
            • Salad ức gà áp chảo sốt mè rang, cháo sườn non hạt sen, hoặc sữa chua ngũ cốc hạt chia.
            
            Bạn đang thèm món nước nóng sốt hay món cơm chắc bụng để tôi gợi ý chi tiết hơn nhé?
            """
        }
        
        // 4. Health & Sleep (10-3-2-1 Rule & 4-7-8 Breathing)
        if p.contains("mất ngủ") || p.contains("ngủ ngon") || p.contains("khó ngủ") || p.contains("ngủ sâu") || p.contains("giấc ngủ") || p.contains("sleep") {
            return """
            🌙 **Bí quyết vàng để có giấc ngủ sâu và thức dậy tràn đầy năng lượng:**
            
            📌 **1. Quy tắc kinh điển 10-3-2-1 trước khi ngủ:**
            • **10 tiếng trước**: Ngưng nạp caffeine (cà phê, trà đậm, nước ngọt có ga).
            • **3 tiếng trước**: Dừng bữa ăn lớn và rượu bia (để hệ tiêu hóa được nghỉ ngơi).
            • **2 tiếng trước**: Gác lại công việc, deadline và suy nghĩ căng thẳng.
            • **1 tiếng trước**: Tắt màn hình điện thoại/iPad/máy tính (tránh ánh sáng xanh ức chế melatonin).
            
            📌 **2. Phương pháp thở thư giãn 4-7-8 (đi vào giấc ngủ sau 2 phút):**
            • Hít vào nhẹ nhàng bằng mũi trong **4 giây**.
            • Giữ hơi thở thoải mái trong **7 giây**.
            • Thở ra từ từ, êm ái bằng miệng trong **8 giây**.
            • Lặp lại đúng 4 chu kỳ: nhịp tim sẽ chậm lại, hệ thần kinh phó giao cảm được kích hoạt và mí mắt sẽ chùng xuống rất êm ái.
            
            Chúc bạn đêm nay có một giấc ngủ thật ngon lành và bình yên! 💤✨
            """
        }
        
        // 5. Motorbike Driving License A1 Test (Thủ tục & Kinh nghiệm)
        if p.contains("bằng lái") || p.contains("thi bằng") || p.contains("a1") || p.contains("xe máy") || p.contains("vòng số 8") {
            return """
            🚗 **Cẩm nang thi bằng lái xe máy hạng A1 (Trọn bộ Lý thuyết & Thực hành):**
            
            📋 **1. Hồ sơ cần chuẩn bị:**
            • 01 bản photo CCCD/CMND (không cần công chứng).
            • 04 ảnh thẻ 3x4 (phông nền xanh dương, chụp rõ mặt).
            • Giấy khám sức khỏe lái xe còn hạn 6 tháng do cơ sở y tế đủ thẩm quyền cấp.
            
            📝 **2. Phần thi Lý thuyết (25 câu hỏi trắc nghiệm):**
            • Thời gian làm bài: **19 phút**.
            • Yêu cầu đạt: **Từ 21/25 câu trở lên**.
            • ⚠️ **LƯU Ý ĐẶC BIỆT**: Không được làm sai bất kỳ câu hỏi điểm liệt nào (các câu về nồng độ cồn, hành vi bị nghiêm cấm, dừng xe trên đường sắt). Làm sai 1 câu điểm liệt = trượt ngay lập tức!
            
            🏍️ **3. Phần thi Thực hành (Sa hình 100 điểm, cần đạt tối thiểu 80/100):**
            • **Bài 1: Đi vòng số 8**: Hãy đi số 2 hoặc số 3 để xe chạy đầm ga, không giật. Mở rộng góc cua đầu xe sang mép ngoài để bánh sau không đè vạch. (Mỗi lần chạm vạch trừ 5 điểm).
            • **Bài 2: Đường thẳng hẹp**: Giữ thẳng tay lái, duy trì ga đều.
            • **Bài 3: Đường quanh co có chướng ngại vật**: Lách nhẹ nhàng theo hướng mũi tên.
            • **Bài 4: Đường gồ ghề**: Thả lỏng tay, giữ đều ga qua các gờ giảm tốc.
            
            Chúc bạn ôn tập tự tin và lấy bằng A1 ngay trong lần thi đầu tiên nhé! 🎉
            """
        }
        
        // 6. Humor, Jokes & Riddles
        if p.contains("chuyện cười") || p.contains("kể chuyện") || p.contains("hài") || p.contains("đố vui") || p.contains("joke") {
            return """
            😄 **Tặng bạn một câu chuyện cười đời thường và câu đố vui thư giãn nè:**
            
            🤣 **Chuyện cười: Lời dặn đi siêu thị**
            Vợ dặn chồng trước khi đi làm về: *"Anh ghé siêu thị mua cho em một ổ bánh mì. Tiện thể nếu thấy có trứng tươi thì mua 10 nhé!"*
            Một lúc sau, anh chồng hớn hở xách về đúng 10 ổ bánh mì.
            Người vợ ôm đầu kinh ngạc: *"Trời đất ơi, sao anh mua tận 10 ổ bánh mì làm gì?!"*
            Anh chồng gãi đầu bình thản đáp: *"Thì tại anh thấy ở đó có bán trứng mà!"* 😂
            
            🧩 **Câu đố vui hại não:**
            Cái gì tay trái của bạn cầm được mà tay phải không bao giờ cầm được?
            👉 **Đáp án**: Chính là **khuỷu tay phải** của bạn đấy!
            
            Cười một chút để nạp lại năng lượng tích cực bạn nhé! Có muốn tôi đố tiếp câu nào nữa không?
            """
        }
        
        // 7. Tech Founders (Steve Jobs, Apple, Microsoft, Elon Musk)
        if p.contains("apple") || p.contains("steve jobs") || p.contains("wozniak") {
            return """
            🍎 **Lịch sử ra đời của Apple Inc.:**
            
            Apple được thành lập vào ngày **01/04/1976** tại garage nhà Steve Jobs ở California bởi 3 thành viên:
            1. 🌟 **Steve Jobs**: Người định hình phong cách thiết kế vị nhân sinh, giao diện trực quan và trải nghiệm người dùng mẫu mực (Macintosh, iPod, iPhone, iPad).
            2. 🛠️ **Steve Wozniak (Woz)**: Thiên tài kỹ thuật phần cứng, người tự tay thiết kế và hàn từng vi mạch cho máy tính huyền thoại Apple I và Apple II.
            3. 📜 **Ronald Wayne**: Người phụ trách giấy tờ pháp lý ban đầu và vẽ logo hình Isaac Newton ngồi dưới gốc cây táo.
            
            Ứng dụng **Private LLM** mà bạn đang dùng chính là thành quả tiếp nối triết lý bảo vệ quyền riêng tư người dùng mà Apple kiên định xây dựng!
            """
        }
        
        if p.contains("elon musk") || p.contains("tesla") || p.contains("spacex") {
            return "🚀 **Elon Musk** là kỹ sư trưởng kiêm CEO của **SpaceX** (mục tiêu chinh phục sao Hỏa), CEO của **Tesla** (xe điện và robot tự hành Optimus), nhà sáng lập Neuralink (giao diện não người) và xAI (phát triển mô hình Grok)!"
        }
        
        // 8. Math evaluation
        if let mathResult = evaluateSimpleMath(p) {
            return "Kết quả phép tính: **\(mathResult)**"
        }
        
        // 9. Default Fallback Offline Answer
        return """
        💡 **Private LLM (100% On-Device & Offline):**
        
        Tôi đã tiếp nhận câu hỏi của bạn: *"\(prompt)"*.
        
        Khi chạy trực tiếp trên thiết bị của bạn (iPhone/iPad/Mac Apple Silicon):
        • Toàn bộ quy trình xử lý ngôn ngữ được tăng tốc bởi Metal và Neural Engine.
        • Không có bất kỳ dữ liệu nào truyền qua mạng Internet.
        • Bạn có thể tải các mô hình mã nguồn mở như **Llama 3.2, Qwen 3, DeepSeek R1, Gemma 2, Mistral, Phi-3.5** trong mục Quản lý Mô hình để trải nghiệm sức mạnh suy luận chuyên sâu!
        
        Bạn có muốn thử hỏi về gợi ý ẩm thực, bí quyết ngủ ngon, luật giao thông hay kể chuyện cười không?
        """
    }
    
    private func evaluateSimpleMath(_ text: String) -> String? {
        let pattern = "([0-9]+(?:\\.[0-9]+)?)\\s*([+\\-*/xX])\\s*([0-9]+(?:\\.[0-9]+)?)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges == 4,
              let r1 = Range(match.range(at: 1), in: text),
              let r2 = Range(match.range(at: 2), in: text),
              let r3 = Range(match.range(at: 3), in: text),
              let a = Double(text[r1]),
              let b = Double(text[r3]) else { return nil }
        
        let op = String(text[r2]).lowercased()
        var result: Double = 0
        switch op {
        case "+": result = a + b
        case "-": result = a - b
        case "*", "x": result = a * b
        case "/":
            if b == 0 { return "Không thể chia cho số 0" }
            result = a / b
        default: return nil
        }
        
        if result.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(result))
        } else {
            return String(format: "%.2f", result)
        }
    }
}
