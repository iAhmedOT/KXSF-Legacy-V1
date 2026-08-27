import XCTest

final class KXSFMidnightGlassUITests: XCTestCase {
    @MainActor
    func test_launch_exposes_the_play_control() {
        let app = XCUIApplication()
        app.launch()
        defer { app.terminate() }

        let playControl = app.buttons["playback-control"]
        XCTAssertTrue(playControl.exists)
        XCTAssertTrue(playControl.isHittable)
        XCTAssertEqual(app.staticTexts["playback-status"].label, "Ready to listen")
    }

    @MainActor
    func test_bottom_navigation_reaches_station_destinations() {
        let app = XCUIApplication()
        app.launch()
        defer { app.terminate() }

        app.buttons["tab-shows"].tap()
        XCTAssertTrue(app.staticTexts["Shows"].exists)

        app.buttons["tab-calendar"].tap()
        XCTAssertTrue(app.staticTexts["Calendar"].exists)

        app.buttons["tab-about"].tap()
        XCTAssertTrue(app.staticTexts["About KXSF"].exists)
    }

    @MainActor
    func test_play_starts_the_kxsf_stream() {
        let app = XCUIApplication()
        app.launch()
        defer { app.terminate() }

        app.buttons["playback-control"].tap()

        let liveStatus = app.staticTexts["playback-status"]
        let becameLive = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Live on KXSF"),
            object: liveStatus
        )
        XCTAssertEqual(XCTWaiter.wait(for: [becameLive], timeout: 20), .completed)
    }
}
