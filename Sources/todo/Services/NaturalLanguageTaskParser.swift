import Foundation

struct ParsedTaskInput {
    let title: String
    let dueDate: Date?
    let parseStatus: ParseStatus
}

enum ParseStatus {
    case parsed
    case notDetected
    case ambiguous
}

struct NaturalLanguageTaskParser {
    private let calendar = Calendar.current

    func parse(_ rawText: String) -> ParsedTaskInput {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return ParsedTaskInput(title: text, dueDate: nil, parseStatus: .notDetected)
        }

        let lowered = text.lowercased()
        let hasTimeKeyword = lowered.contains("saat")
        let dayOffset = dayOffsetFromText(lowered)
        let extractedTime = extractTime(text: lowered)

        if hasTimeKeyword && extractedTime == nil {
            return ParsedTaskInput(title: cleanupTitle(text), dueDate: nil, parseStatus: .ambiguous)
        }

        guard let dayOffset, let extractedTime else {
            return ParsedTaskInput(title: cleanupTitle(text), dueDate: nil, parseStatus: .notDetected)
        }

        var components = calendar.dateComponents([.year, .month, .day], from: .now)
        components.day = (components.day ?? 0) + dayOffset
        components.hour = extractedTime.hour
        components.minute = extractedTime.minute
        components.second = 0

        let dueDate = calendar.date(from: components)
        return ParsedTaskInput(title: cleanupTitle(text), dueDate: dueDate, parseStatus: .parsed)
    }

    private func dayOffsetFromText(_ lowered: String) -> Int? {
        if lowered.contains("bugun") || lowered.contains("bugün") {
            return 0
        }
        if lowered.contains("yarin") || lowered.contains("yarın") {
            return 1
        }
        return nil
    }

    private func extractTime(text: String) -> (hour: Int, minute: Int)? {
        let pattern = #"saat\s+(\d{1,2})[:.](\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let hourRange = Range(match.range(at: 1), in: text),
              let minuteRange = Range(match.range(at: 2), in: text),
              let hour = Int(text[hourRange]),
              let minute = Int(text[minuteRange]),
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return nil
        }
        return (hour, minute)
    }

    private func cleanupTitle(_ text: String) -> String {
        text.replacingOccurrences(of: #"(?i)\b(bugün|bugun|yarın|yarin)\b"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)\bsaat\s+\d{1,2}[:.]\d{2}\b"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
