import Foundation

public enum KXSFShowDetailParser {
    public static func hostName(in html: String) -> String? {
        if let heading = firstCapture("<h3[^>]*>(.*?)</h3>", in: html), let name = plainText(heading) {
            return name
        }

        guard let hostPhrase = firstCapture("([A-Z][A-Za-z’'\\-]+(?:\\s+[A-Z][A-Za-z’'\\-]+){0,3})\\s+(?:hosts|curates|presents)", in: html) else {
            return nil
        }
        return plainText(hostPhrase)
    }
}

public struct KXSFYouTubeUpload: Sendable, Equatable, Identifiable {
    public let videoID: String
    public let title: String
    public let publishedAt: Date?
    public let thumbnailURL: URL?

    public var id: String { videoID }
    public var watchURL: URL { URL(string: "https://www.youtube.com/watch?v=\(videoID)")! }

    public init(videoID: String, title: String, publishedAt: Date?, thumbnailURL: URL?) {
        self.videoID = videoID
        self.title = title
        self.publishedAt = publishedAt
        self.thumbnailURL = thumbnailURL
    }
}

public enum KXSFYouTubeFeedParser {
    public static func uploads(in xml: String) -> [KXSFYouTubeUpload] {
        matches("<entry\\b[^>]*>.*?</entry>", in: xml).compactMap { entry in
            guard
                let videoID = firstCapture("<yt:videoId>(.*?)</yt:videoId>", in: entry),
                let title = firstCapture("<title>(.*?)</title>", in: entry).flatMap(plainText),
                !videoID.isEmpty
            else {
                return nil
            }

            let publishedAt = firstCapture("<published>(.*?)</published>", in: entry)
                .flatMap { ISO8601DateFormatter().date(from: $0) }
            let thumbnailURL = firstCapture("<media:thumbnail[^>]*url=[\\\"']([^\\\"']+)[\\\"']", in: entry)
                .flatMap { URL(string: decodeEntities($0)) }

            return KXSFYouTubeUpload(
                videoID: videoID,
                title: title,
                publishedAt: publishedAt,
                thumbnailURL: thumbnailURL
            )
        }
    }
}

/// Parses the public, official KXSF YouTube Videos page only as a fallback when
/// YouTube's documented Atom endpoint is unavailable. Entries missing a stable
/// YouTube video ID, title, or thumbnail are intentionally discarded.
public enum KXSFYouTubePageParser {
    public static func uploads(in html: String) -> [KXSFYouTubeUpload] {
        lockupJSONObjects(in: html)
            .compactMap { object in
                guard
                    let videoID = string(at: ["contentId"], in: object),
                    !videoID.isEmpty,
                    let title = string(at: ["metadata", "lockupMetadataViewModel", "title", "content"], in: object),
                    let thumbnail = string(at: ["contentImage", "thumbnailViewModel", "image", "sources", "0", "url"], in: object),
                    let thumbnailURL = URL(string: thumbnail)
                else { return nil }
                return KXSFYouTubeUpload(videoID: videoID, title: title, publishedAt: nil, thumbnailURL: thumbnailURL)
            }
            .removingDuplicateVideoIDs()
    }
}

private func lockupJSONObjects(in source: String) -> [[String: Any]] {
    let marker = "\"lockupViewModel\":"
    var searchStart = source.startIndex
    var objects: [[String: Any]] = []

    while let markerRange = source.range(of: marker, range: searchStart..<source.endIndex),
          let objectStart = source[markerRange.upperBound...].firstIndex(of: "{"),
          let objectText = balancedJSONObject(in: source, from: objectStart),
          let data = objectText.data(using: .utf8),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        objects.append(object)
        searchStart = source.index(after: objectStart)
    }
    return objects
}

private func balancedJSONObject(in source: String, from start: String.Index) -> String? {
    var depth = 0
    var isEscaped = false
    var inString = false

    for index in source.indices[start...] {
        let character = source[index]
        if inString {
            if isEscaped { isEscaped = false }
            else if character == "\\" { isEscaped = true }
            else if character == "\"" { inString = false }
            continue
        }
        if character == "\"" { inString = true }
        else if character == "{" { depth += 1 }
        else if character == "}" {
            depth -= 1
            if depth == 0 { return String(source[start...index]) }
        }
    }
    return nil
}

private func string(at path: [String], in object: [String: Any]) -> String? {
    var value: Any = object
    for component in path {
        if let dictionary = value as? [String: Any] {
            value = dictionary[component] as Any
        } else if let array = value as? [Any], let index = Int(component), array.indices.contains(index) {
            value = array[index]
        } else {
            return nil
        }
    }
    return value as? String
}

private extension Array where Element == KXSFYouTubeUpload {
    func removingDuplicateVideoIDs() -> [KXSFYouTubeUpload] {
        var seen = Set<String>()
        return filter { seen.insert($0.videoID).inserted }
    }
}

private func firstCapture(_ pattern: String, in source: String) -> String? {
    guard
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
        let match = regex.firstMatch(in: source, range: NSRange(source.startIndex..<source.endIndex, in: source)),
        let range = Range(match.range(at: 1), in: source)
    else {
        return nil
    }
    return String(source[range])
}

private func matches(_ pattern: String, in source: String) -> [String] {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
        return []
    }
    let range = NSRange(source.startIndex..<source.endIndex, in: source)
    return regex.matches(in: source, range: range).compactMap { match in
        guard let range = Range(match.range, in: source) else { return nil }
        return String(source[range])
    }
}

private func plainText(_ source: String) -> String? {
    let text = decodeEntities(source.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression))
        .split(whereSeparator: { $0.isWhitespace })
        .joined(separator: " ")
    return text.isEmpty ? nil : text
}

private func decodeEntities(_ source: String) -> String {
    source
        .replacingOccurrences(of: "&amp;", with: "&")
        .replacingOccurrences(of: "&#8217;", with: "’")
        .replacingOccurrences(of: "&quot;", with: "\"")
        .replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
}
