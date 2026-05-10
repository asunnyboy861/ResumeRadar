import PDFKit

struct PDFExtractor {
    static func extractText(from url: URL) -> String? {
        guard let document = PDFDocument(url: url) else { return nil }
        var text = ""
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            text += page.string ?? ""
            if i < document.pageCount - 1 {
                text += "\n"
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text
    }
}
