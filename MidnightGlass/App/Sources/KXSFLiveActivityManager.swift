import ActivityKit
import Foundation

enum KXSFLiveActivityManager {
    static func synchronize(
        showTitle: String,
        hostName: String?,
        timeRange: String?,
        artworkURL: String?,
        isPlaying: Bool
    ) {
        let state = KXSFLiveActivityAttributes.ContentState(
            showTitle: showTitle,
            hostName: hostName,
            timeRange: timeRange,
            artworkURL: artworkURL,
            isPlaying: isPlaying
        )

        Task.detached(priority: .userInitiated) {
            let activities = Activity<KXSFLiveActivityAttributes>.activities
            if isPlaying {
                if let activity = activities.first {
                    await activity.update(ActivityContent(state: state, staleDate: nil))
                } else {
                    _ = try? Activity.request(
                        attributes: KXSFLiveActivityAttributes(stationName: "KXSF 102.5 FM"),
                        content: ActivityContent(state: state, staleDate: nil),
                        pushType: nil
                    )
                }
            } else {
                for activity in activities {
                    await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
                }
            }
        }
    }
}
