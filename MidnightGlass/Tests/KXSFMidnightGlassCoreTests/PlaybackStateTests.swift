import XCTest
@testable import KXSFMidnightGlassCore

final class PlaybackStateTests: XCTestCase {
    func test_idle_state_is_not_playing() {
        XCTAssertFalse(PlaybackState.idle.isPlaying)
    }

    func test_loading_state_is_not_playing() {
        XCTAssertFalse(PlaybackState.loading.isPlaying)
    }

    func test_playing_state_is_playing() {
        XCTAssertTrue(PlaybackState.playing.isPlaying)
    }
}
