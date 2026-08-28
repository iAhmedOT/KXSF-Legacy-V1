import Foundation

public enum KXSFWeekday: String, CaseIterable, Sendable, Equatable, Identifiable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"

    public var id: String { rawValue }
}

public struct KXSFShow: Sendable, Equatable, Identifiable {
    public let day: KXSFWeekday
    public let name: String
    public let timeRange: String
    public let detailURL: URL
    public let artworkURL: URL?
    public let hostName: String?
    public let isNowPlaying: Bool

    public var id: String { detailURL.absoluteString }

    public init(
        day: KXSFWeekday,
        name: String,
        timeRange: String,
        detailURL: URL,
        artworkURL: URL?,
        hostName: String? = nil,
        isNowPlaying: Bool
    ) {
        self.day = day
        self.name = name
        self.timeRange = timeRange
        self.detailURL = detailURL
        self.artworkURL = artworkURL
        self.hostName = hostName
        self.isNowPlaying = isNowPlaying
    }
}

public struct KXSFScheduleSection: Sendable, Equatable, Identifiable {
    public let day: KXSFWeekday
    public let shows: [KXSFShow]

    public var id: KXSFWeekday { day }

    public init(day: KXSFWeekday, shows: [KXSFShow]) {
        self.day = day
        self.shows = shows
    }
}

public struct KXSFSchedule: Sendable, Equatable {
    public let sections: [KXSFScheduleSection]

    public var shows: [KXSFShow] { sections.flatMap(\.shows) }
    public var currentShow: KXSFShow? { shows.first(where: \.isNowPlaying) }

    public func sections(startingWith day: KXSFWeekday) -> [KXSFScheduleSection] {
        guard let startIndex = sections.firstIndex(where: { $0.day == day }) else { return sections }
        return Array(sections[startIndex...]) + Array(sections[..<startIndex])
    }

    public init(sections: [KXSFScheduleSection]) {
        self.sections = sections
    }
}

public enum KXSFScheduleParser {
    public static func schedule(in html: String) -> KXSFSchedule {
        let dayMarkers = markers(in: html)
        let articles = matches(
            "<article\\b[^>]*>.*?</article>",
            in: html
        )

        var showsByDay: [KXSFWeekday: [KXSFShow]] = [:]
        var encounteredDays: [KXSFWeekday] = []

        for article in articles {
            guard
                let day = dayMarkers.last(where: { $0.offset <= article.offset })?.day,
                let show = parseShow(article.text, day: day)
            else {
                continue
            }

            if showsByDay[day] == nil {
                encounteredDays.append(day)
            }
            showsByDay[day, default: []].append(show)
        }

        return KXSFSchedule(
            sections: encounteredDays.compactMap { day in
                guard let shows = showsByDay[day], !shows.isEmpty else { return nil }
                return KXSFScheduleSection(day: day, shows: shows)
            }
        )
    }

    private static func parseShow(_ article: String, day: KXSFWeekday) -> KXSFShow? {
        guard
            let titleHTML = firstCapture(
                "<h3[^>]*class=[\\\"'][^\\\"']*proradio-post__title[^\\\"']*[\\\"'][^>]*>(.*?)</h3>",
                in: article
            ),
            let name = text(fromHTML: titleHTML),
            let detailURLString = firstCapture(
                "<a[^>]*class=[\\\"'][^\\\"']*proradio-post__header__link[^\\\"']*[\\\"'][^>]*href=[\\\"']([^\\\"']+)[\\\"']",
                in: article
            ),
            let detailURL = URL(string: decodeHTML(detailURLString)),
            let timeHTML = firstCapture(
                "<p[^>]*class=[\\\"'][^\\\"']*proradio-itemmetas[^\\\"']*[\\\"'][^>]*>(.*?)</p>",
                in: article
            ),
            let timeRange = text(fromHTML: timeHTML)
        else {
            return nil
        }

        let artworkURL = firstCapture("<img[^>]*src=[\\\"']([^\\\"']+)[\\\"']", in: article)
            .flatMap { URL(string: decodeHTML($0)) }

        return KXSFShow(
            day: day,
            name: name,
            timeRange: timeRange,
            detailURL: detailURL,
            artworkURL: artworkURL,
            isNowPlaying: article.range(of: "now playing", options: [.caseInsensitive, .diacriticInsensitive]) != nil
        )
    }

    private static func markers(in html: String) -> [(offset: Int, day: KXSFWeekday)] {
        KXSFWeekday.allCases.flatMap { day in
            let escapedDay = NSRegularExpression.escapedPattern(for: day.rawValue)
            return matches("<h[1-6][^>]*>\\s*\(escapedDay)\\s*</h[1-6]>", in: html)
                .map { (offset: $0.offset, day: day) }
        }
        .sorted { $0.offset < $1.offset }
    }

    private static func text(fromHTML html: String) -> String? {
        let withoutTags = html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let normalized = decodeHTML(withoutTags)
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        return normalized.isEmpty ? nil : normalized
    }

    private static func decodeHTML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#8217;", with: "’")
            .replacingOccurrences(of: "&#8216;", with: "‘")
            .replacingOccurrences(of: "&#8220;", with: "“")
            .replacingOccurrences(of: "&#8221;", with: "”")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }

    private static func firstCapture(_ pattern: String, in text: String) -> String? {
        matches(pattern, in: text).first?.captures.first
    }

    private static func matches(_ pattern: String, in text: String) -> [Match] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return []
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { result in
            guard let fullRange = Range(result.range, in: text) else { return nil }
            let captures = (1..<result.numberOfRanges).compactMap { index -> String? in
                guard let range = Range(result.range(at: index), in: text) else { return nil }
                return String(text[range])
            }
            return Match(offset: result.range.location, text: String(text[fullRange]), captures: captures)
        }
    }

    private struct Match {
        let offset: Int
        let text: String
        let captures: [String]
    }
}
