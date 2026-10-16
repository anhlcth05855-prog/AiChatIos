import Foundation
#if canImport(UIKit)
import UIKit

public final class PDFExportService {
    
    public static func generatePDF(from session: ChatSession) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Private LLM - Local AI Chat",
            kCGPDFContextAuthor: "Private LLM On-Device Engine",
            kCGPDFContextTitle: session.title
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth: CGFloat = 8.5 * 72.0
        let pageHeight: CGFloat = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 36.0
        let contentWidth = pageWidth - (margin * 2)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PrivateLLM_\(session.title.replacingOccurrences(of: " ", with: "_")).pdf")
        
        do {
            try renderer.writePDF(to: tempURL) { context in
                context.beginPage()
                var currentY: CGFloat = margin
                
                // 1. Header
                let titleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
                let titleAttr: [NSAttributedString.Key: Any] = [
                    .font: titleFont,
                    .foregroundColor: UIColor.label
                ]
                let titleString = "🔒 Private LLM - \(session.title)"
                titleString.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttr)
                currentY += 28
                
                let subFont = UIFont.systemFont(ofSize: 11, weight: .regular)
                let subAttr: [NSAttributedString.Key: Any] = [
                    .font: subFont,
                    .foregroundColor: UIColor.secondaryLabel
                ]
                let modelName = ModelCatalog.model(for: session.modelId)?.name ?? session.modelId
                let subString = "Mô hình: \(modelName) • Xuất ngày: \(session.formattedUpdatedAt) • 100% On-Device & Offline"
                subString.draw(at: CGPoint(x: margin, y: currentY), withAttributes: subAttr)
                currentY += 22
                
                // Divider line
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: currentY))
                path.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
                UIColor.separator.setStroke()
                path.lineWidth = 1
                path.stroke()
                currentY += 16
                
                // 2. Messages
                let senderFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
                let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
                
                for msg in session.messages where msg.sender != .status {
                    let senderTitle = msg.isUser ? "👤 Bạn" : "🤖 Private LLM (\(msg.modelName ?? modelName))"
                    let senderColor = msg.isUser ? UIColor.systemBlue : UIColor.systemPurple
                    
                    let senderAttr: [NSAttributedString.Key: Any] = [
                        .font: senderFont,
                        .foregroundColor: senderColor
                    ]
                    
                    let bodyAttr: [NSAttributedString.Key: Any] = [
                        .font: bodyFont,
                        .foregroundColor: UIColor.label
                    ]
                    
                    let contentBox = (msg.content as NSString).boundingRect(
                        with: CGSize(width: contentWidth - 20, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: bodyAttr,
                        context: nil
                    )
                    
                    let bubbleHeight = contentBox.height + 36
                    
                    // Check if new page needed
                    if currentY + bubbleHeight > pageHeight - margin - 20 {
                        context.beginPage()
                        currentY = margin
                    }
                    
                    // Draw bubble background
                    let bubbleRect = CGRect(x: margin, y: currentY, width: contentWidth, height: bubbleHeight)
                    let bgPath = UIBezierPath(roundedRect: bubbleRect, cornerRadius: 8)
                    let bgColor = msg.isUser ? UIColor.systemBlue.withAlphaComponent(0.08) : UIColor.secondarySystemBackground
                    bgColor.setFill()
                    bgPath.fill()
                    
                    // Draw Sender & time
                    senderTitle.draw(at: CGPoint(x: margin + 10, y: currentY + 8), withAttributes: senderAttr)
                    
                    let timeAttr: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                        .foregroundColor: UIColor.tertiaryLabel
                    ]
                    let timeStr = msg.formattedTime
                    let timeSize = (timeStr as NSString).size(withAttributes: timeAttr)
                    timeStr.draw(at: CGPoint(x: pageWidth - margin - timeSize.width - 10, y: currentY + 8), withAttributes: timeAttr)
                    
                    // Draw message content
                    let textRect = CGRect(x: margin + 10, y: currentY + 26, width: contentWidth - 20, height: contentBox.height)
                    msg.content.draw(in: textRect, withAttributes: bodyAttr)
                    
                    currentY += bubbleHeight + 12
                }
            }
            return tempURL
        } catch {
            print("[PDFExportService] PDF export error: \(error)")
            return nil
        }
    }
}
#endif
