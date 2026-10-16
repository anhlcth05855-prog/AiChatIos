import Foundation
import SwiftUI

public enum MarkdownSegmentType: Equatable {
    case text
    case code(language: String)
}

public struct MarkdownSegment: Identifiable, Equatable {
    public let id = UUID()
    public let type: MarkdownSegmentType
    public let content: String
}

public struct MarkdownFormatter {
    
    private static let codeBlockRegex = try? NSRegularExpression(
        pattern: "```([a-zA-Z0-9_+-]*)\\n?([\\s\\S]*?)```",
        options: []
    )
    
    public static func parseSegments(_ text: String) -> [MarkdownSegment] {
        guard let regex = codeBlockRegex, !text.isEmpty else {
            return [MarkdownSegment(type: .text, content: text)]
        }
        
        var segments: [MarkdownSegment] = []
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        var lastEnd = 0
        for match in matches {
            if match.range.location > lastEnd {
                let textRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let textContent = nsString.substring(with: textRange).trimmingCharacters(in: .whitespacesAndNewlines)
                if !textContent.isEmpty {
                    segments.append(MarkdownSegment(type: .text, content: textContent))
                }
            }
            
            var lang = ""
            if match.numberOfRanges > 1 && match.range(at: 1).location != NSNotFound {
                lang = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            var code = ""
            if match.numberOfRanges > 2 && match.range(at: 2).location != NSNotFound {
                code = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .newlines)
            }
            
            segments.append(MarkdownSegment(type: .code(language: normalizeLanguage(lang)), content: code))
            lastEnd = match.range.location + match.range.length
        }
        
        if lastEnd < nsString.length {
            let remainRange = NSRange(location: lastEnd, length: nsString.length - lastEnd)
            let remainContent = nsString.substring(with: remainRange).trimmingCharacters(in: .whitespacesAndNewlines)
            if !remainContent.isEmpty {
                segments.append(MarkdownSegment(type: .text, content: remainContent))
            }
        }
        
        return segments.isEmpty ? [MarkdownSegment(type: .text, content: text)] : segments
    }
    
    public static func normalizeLanguage(_ raw: String) -> String {
        let l = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch l {
        case "swift": return "Swift 🟧"
        case "python", "py": return "Python 🐍"
        case "kt", "kotlin": return "Kotlin 🟣"
        case "js", "javascript": return "JavaScript 🟨"
        case "ts", "typescript": return "TypeScript 🔷"
        case "cpp", "c++": return "C++ 🔵"
        case "c": return "C ⚙️"
        case "sh", "bash", "zsh": return "Shell 💻"
        case "json": return "JSON 📋"
        case "html": return "HTML 🌐"
        case "css": return "CSS 🎨"
        case "sql": return "SQL 🗄️"
        default: return l.isEmpty ? "Code 📝" : l.capitalized
        }
    }
}
