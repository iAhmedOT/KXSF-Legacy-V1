import Foundation
import Combine
import KXSFMidnightGlassCore

@MainActor
final class LiveShowStore: ObservableObject {
    @Published private(set) var showName: String?
    @Published private(set) var isLoading = false

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        var request = URLRequest(url: URL(string: "https://kxsf.fm/schedule-shows/")!)
        request.setValue("KXSF Midnight Glass/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
            showName = KXSFLiveShowParser.showName(
                in: String(decoding: data, as: UTF8.self)
            )
        } catch {
            showName = nil
        }
    }
}
