import Combine
import Foundation
import KXSFMidnightGlassCore

@MainActor
final class LiveShowStore: ObservableObject {
    private static let scheduleURL = URL(string: "https://kxsf.fm/schedule-shows/")!
    private static let youTubeFeedURL = URL(string: "https://www.youtube.com/feeds/videos.xml?channel_id=UC4s6CEhvgmbCIPkUB1BRjsw")!
    private static let youTubeVideosURL = URL(string: "https://www.youtube.com/@kxsfradio/videos")!

    @Published private(set) var schedule = KXSFSchedule(sections: [])
    @Published private(set) var uploads: [KXSFYouTubeUpload] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingUploads = false
    @Published private(set) var didFailToLoad = false

    var currentShow: KXSFShow? { schedule.currentShow }
    var showName: String? { currentShow?.name }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        didFailToLoad = false
        defer { isLoading = false }

        do {
            let parsedSchedule = try await loadSchedule()
            guard !parsedSchedule.shows.isEmpty else {
                didFailToLoad = true
                return
            }
            schedule = parsedSchedule
            await refreshShowHosts()
        } catch {
            didFailToLoad = true
        }
    }

    func refreshUploads() async {
        guard !isLoadingUploads else { return }
        isLoadingUploads = true
        defer { isLoadingUploads = false }

        do {
            let atomData = try await fetch(Self.youTubeFeedURL)
            let atomUploads = KXSFYouTubeFeedParser.uploads(in: String(decoding: atomData, as: UTF8.self))
            if !atomUploads.isEmpty {
                uploads = atomUploads
                return
            }
        } catch {
            // YouTube's documented Atom endpoint currently returns 404 for KXSF.
            // Fall through to the station's public, official Videos page.
        }

        do {
            let pageData = try await fetch(Self.youTubeVideosURL)
            uploads = KXSFYouTubePageParser.uploads(in: String(decoding: pageData, as: UTF8.self))
        } catch {
            uploads = []
        }
    }

    private func fetch(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private func loadSchedule() async throws -> KXSFSchedule {
        var request = URLRequest(url: Self.scheduleURL)
        request.setValue("KXSF Midnight Glass/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return KXSFScheduleParser.schedule(in: String(decoding: data, as: UTF8.self))
    }

    private func refreshShowHosts() async {
        let shows = schedule.shows
        let enriched = await withTaskGroup(of: (String, String?).self, returning: [String: String].self) { group in
            for show in shows {
                group.addTask {
                    var request = URLRequest(url: show.detailURL)
                    request.setValue("KXSF Midnight Glass/1.0", forHTTPHeaderField: "User-Agent")
                    request.timeoutInterval = 10
                    let host = try? await URLSession.shared.data(for: request).0
                    let parsed = host.map { KXSFShowDetailParser.hostName(in: String(decoding: $0, as: UTF8.self)) } ?? nil
                    return (show.id, parsed)
                }
            }

            var result: [String: String] = [:]
            for await (id, host) in group {
                if let host { result[id] = host }
            }
            return result
        }

        schedule = KXSFSchedule(sections: schedule.sections.map { section in
            KXSFScheduleSection(day: section.day, shows: section.shows.map { show in
                KXSFShow(
                    day: show.day,
                    name: show.name,
                    timeRange: show.timeRange,
                    detailURL: show.detailURL,
                    artworkURL: show.artworkURL,
                    hostName: enriched[show.id],
                    isNowPlaying: show.isNowPlaying
                )
            })
        })
    }
}
