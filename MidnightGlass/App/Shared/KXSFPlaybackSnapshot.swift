import Foundation

/// A small cross-process snapshot for WidgetKit surfaces. It is written only
/// after the app's AVPlayer publishes its real playback state.
enum KXSFPlaybackSnapshot {
    private static let suiteName = "group.com.KXSF.fm"
    private static let isPlayingKey = "isPlaying"

    static var isPlaying: Bool {
        UserDefaults(suiteName: suiteName)?.bool(forKey: isPlayingKey) ?? false
    }

    static func setIsPlaying(_ isPlaying: Bool) {
        UserDefaults(suiteName: suiteName)?.set(isPlaying, forKey: isPlayingKey)
    }
}
