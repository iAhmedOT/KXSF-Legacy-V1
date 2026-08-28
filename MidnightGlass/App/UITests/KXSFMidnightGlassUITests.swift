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
        XCTAssertTrue(app.staticTexts["Ready to listen"].exists)
    }

    @MainActor
    func test_bottom_navigation_reaches_station_destinations() {
        let app = XCUIApplication()
        app.launch()
        defer { app.terminate() }

        attachScreenshot(named: "Listen")

        app.buttons["tab-shows"].tap()
        let showsTitle = app.scrollViews.staticTexts["Shows"]
        let windowFrame = app.windows.firstMatch.frame
        let tabFrame = app.buttons["tab-shows"].frame
        print("KXSF_LAYOUT window=\(windowFrame) title=\(showsTitle.frame) tab=\(tabFrame)")
        XCTAssertTrue(showsTitle.exists)
        XCTAssertTrue(showsTitle.isHittable)
        XCTAssertGreaterThanOrEqual(showsTitle.frame.minY, 76)
        XCTAssertLessThanOrEqual(showsTitle.frame.minY, 112)
        XCTAssertGreaterThanOrEqual(tabFrame.maxY, 828)
        XCTAssertLessThanOrEqual(tabFrame.maxY, 850)
        XCTAssertTrue(app.otherElements["schedule-shows-content"].exists)
        attachScreenshot(named: "Shows")

        app.buttons["tab-live"].tap()
        let liveTitle = app.scrollViews.staticTexts["KXSF Live"]
        XCTAssertTrue(liveTitle.exists)
        XCTAssertTrue(liveTitle.isHittable)
        XCTAssertGreaterThanOrEqual(liveTitle.frame.minY, 76)
        XCTAssertLessThanOrEqual(liveTitle.frame.minY, 136)
        attachScreenshot(named: "KXSF Live")

        app.buttons["tab-about"].tap()
        let aboutTitle = app.scrollViews.staticTexts["About KXSF"]
        XCTAssertTrue(aboutTitle.exists)
        XCTAssertTrue(aboutTitle.isHittable)
        XCTAssertGreaterThanOrEqual(aboutTitle.frame.minY, 76)
        XCTAssertLessThanOrEqual(aboutTitle.frame.minY, 136)
        attachScreenshot(named: "About")
    }

    @MainActor
    func test_play_starts_the_kxsf_stream() {
        let app = XCUIApplication()
        app.launch()
        defer { app.terminate() }

        app.buttons["playback-control"].tap()

        let liveStatus = app.staticTexts.matching(identifier: "playback-status").firstMatch
        let becameLive = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Live on KXSF"),
            object: liveStatus
        )
        let result = XCTWaiter.wait(for: [becameLive], timeout: 20)
        print("KXSF_PLAYBACK_STATUS label=\(liveStatus.label)")
        XCTAssertEqual(result, .completed)
    }

    @MainActor
    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
