import XCTest

final class KXSFMidnightGlassUITests: XCTestCase {
    @MainActor
    func test_launch_exposes_the_play_control() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["playback-control"].exists)
        XCTAssertEqual(app.staticTexts["playback-status"].label, "Ready to listen")
    }

    @MainActor
    func test_play_starts_the_kxsf_stream() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["playback-control"].tap()

        let liveStatus = app.staticTexts["playback-status"]
        let becameLive = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Live on KXSF"),
            object: liveStatus
        )
        XCTAssertEqual(XCTWaiter.wait(for: [becameLive], timeout: 20), .completed)
    }
}
