import Foundation
import XCTest
@testable import KXSFMidnightGlassCore

final class KXSFScheduleParserTests: XCTestCase {
    private let fixture = """
    <h3 class="proradio-schedule__dayname">Monday</h3>
    <article class="proradio-post proradio-post__card--shows">
      <div class="proradio-bgimg">
        <img src="https://kxsf.fm/wp-content/uploads/moon-wax.jpg" alt="Moon Wax Radio" />
      </div>
      <div class="proradio-post__headercont">
        <h5 class="proradio-tag-nowplaying"><span>Now playing</span></h5>
        <a class="proradio-post__header__link" href="https://kxsf.fm/shows/moon-wax-radio/"></a>
        <h3 class="proradio-post__title"><a href="https://kxsf.fm/shows/moon-wax-radio/">Moon Wax &amp; Friends</a></h3>
        <p class="proradio-itemmetas"> 12:00 pm - 2:00 pm </p>
      </div>
    </article>
    <article class="proradio-post proradio-post__card--shows">
      <a class="proradio-post__header__link" href="https://kxsf.fm/shows/power-machine/"></a>
      <h3 class="proradio-post__title"><a href="https://kxsf.fm/shows/power-machine/">Power Machine</a></h3>
      <p class="proradio-itemmetas"> 4:00 pm - 6:00 pm </p>
    </article>
    <h3 class="proradio-schedule__dayname">Tuesday</h3>
    <article class="proradio-post proradio-post__card--shows">
      <img src="https://kxsf.fm/wp-content/uploads/freefall.png" alt="FreeFall" />
      <a class="proradio-post__header__link" href="https://kxsf.fm/shows/freefall/"></a>
      <h3 class="proradio-post__title"><a href="https://kxsf.fm/shows/freefall/">FreeFall</a></h3>
      <p class="proradio-itemmetas"> 10:00 am - 12:00 pm </p>
    </article>
    """

    func test_parses_weekday_show_metadata_and_artwork() throws {
        let schedule = KXSFScheduleParser.schedule(in: fixture)

        XCTAssertEqual(schedule.shows.count, 3)
        let show = try XCTUnwrap(schedule.shows.first)
        XCTAssertEqual(show.day, .monday)
        XCTAssertEqual(show.name, "Moon Wax & Friends")
        XCTAssertEqual(show.timeRange, "12:00 pm - 2:00 pm")
        XCTAssertEqual(show.detailURL.absoluteString, "https://kxsf.fm/shows/moon-wax-radio/")
        XCTAssertEqual(show.artworkURL?.absoluteString, "https://kxsf.fm/wp-content/uploads/moon-wax.jpg")
        XCTAssertTrue(show.isNowPlaying)
    }

    func test_groups_shows_in_website_weekday_order() {
        let schedule = KXSFScheduleParser.schedule(in: fixture)

        XCTAssertEqual(schedule.sections.map(\.day), [.monday, .tuesday])
        XCTAssertEqual(schedule.sections[0].shows.map(\.name), ["Moon Wax & Friends", "Power Machine"])
        XCTAssertEqual(schedule.sections[1].shows.map(\.name), ["FreeFall"])
    }

    func test_exposes_the_current_show_with_artwork() {
        let schedule = KXSFScheduleParser.schedule(in: fixture)

        XCTAssertEqual(schedule.currentShow?.name, "Moon Wax & Friends")
        XCTAssertEqual(
            schedule.currentShow?.artworkURL?.absoluteString,
            "https://kxsf.fm/wp-content/uploads/moon-wax.jpg"
        )
    }

    func test_skips_incomplete_cards_instead_of_inventing_data() {
        let html = """
        <h3 class="proradio-schedule__dayname">Monday</h3>
        <article><h3>Missing URL and time</h3></article>
        """

        XCTAssertTrue(KXSFScheduleParser.schedule(in: html).shows.isEmpty)
    }
}
