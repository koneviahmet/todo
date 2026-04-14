import Foundation

struct LinkMetadataResult {
    let title: String?
    let host: String?
}

actor LinkMetadataFetcher {
    static let shared = LinkMetadataFetcher()

    func fetch(for url: URL) async -> LinkMetadataResult {
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return LinkMetadataResult(title: nil, host: normalizedHost(from: url))
            }
            let html = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
            let title = extractTitle(from: html)
            return LinkMetadataResult(title: title, host: normalizedHost(from: url))
        } catch {
            return LinkMetadataResult(title: nil, host: normalizedHost(from: url))
        }
    }

    private func extractTitle(from html: String) -> String? {
        let patterns = [
            "<meta[^>]*property=[\"']og:title[\"'][^>]*content=[\"']([^\"']+)[\"'][^>]*>",
            "<meta[^>]*name=[\"']twitter:title[\"'][^>]*content=[\"']([^\"']+)[\"'][^>]*>",
            "<title[^>]*>(.*?)</title>"
        ]

        for pattern in patterns {
            if let value = firstMatch(in: html, pattern: pattern) {
                let cleaned = cleanHTML(value)
                if !cleaned.isEmpty { return cleaned }
            }
        }
        return nil
    }

    private func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range), match.numberOfRanges > 1,
              let matchRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[matchRange])
    }

    private func cleanHTML(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedHost(from url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        return host.replacingOccurrences(of: "www.", with: "")
    }
}
