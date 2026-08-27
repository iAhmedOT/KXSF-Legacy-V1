import Combine
import Foundation
import KXSFMidnightGlassCore

@MainActor
final class LiveShowStore: ObservableObject {
    @Published private(set) var schedule = KXSFSchedule(sections: [])
    @Published private(set) var isLoading = false
    @Published private(set) var didFailToLoad = false

    var currentShow: KXSFShow? { schedule.currentShow }
    var showName: String? { currentShow?.name }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        didFailToLoad = false
        defer { isLoading = false }

        var request = URLRequest(url: URL(string: "https://kxsf.fm/schedule-shows/")!)
        request.setValue("KXSF Midnight Glass/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                didFailToLoad = true
                return
            }

            let parsedSchedule = KXSFScheduleParser.schedule(in: String(decoding: data, as: UTF8.self))
            guard !parsedSchedule.shows.isEmpty else {
                didFailToLoad = true
                return
            }
            schedule = parsedSchedule
        } catch {
            didFailToLoad = true
        }
    }
}
