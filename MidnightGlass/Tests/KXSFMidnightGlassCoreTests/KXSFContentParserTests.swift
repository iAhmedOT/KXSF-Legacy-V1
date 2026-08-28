import XCTest
@testable import KXSFMidnightGlassCore

final class KXSFContentParserTests: XCTestCase {
    func test_extracts_host_from_official_member_block() {
        let html = """
        <h1>FreeFall. Tuesday, 10AM</h1>
        <a href="https://kxsf.fm/members/david-bassin/"><span class="person_outline"></span></a>
        <h3><a href="https://kxsf.fm/members/david-bassin/">David Bassin</a></h3>
        """

        XCTAssertEqual(KXSFShowDetailParser.hostName(in: html), "David Bassin")
    }

    func test_extracts_the_host_from_an_official_show_detail_page() {
        let html = """
        <h1>FreeFall. Tuesday, 10AM</h1>
        <p>David Bassin hosts an eclectic two-hour mix of jazz, R&amp;B, global grooves &amp; abstract beats.</p>
        <h3>David Bassin</h3>
        """

        XCTAssertEqual(KXSFShowDetailParser.hostName(in: html), "David Bassin")
    }

    func test_orders_sections_starting_with_the_listener_weekday() {
        let monday = KXSFScheduleSection(day: .monday, shows: [])
        let tuesday = KXSFScheduleSection(day: .tuesday, shows: [])
        let wednesday = KXSFScheduleSection(day: .wednesday, shows: [])
        let schedule = KXSFSchedule(sections: [monday, tuesday, wednesday])

        XCTAssertEqual(
            schedule.sections(startingWith: .tuesday).map(\.day),
            [.tuesday, .wednesday, .monday]
        )
    }

    func test_parses_the_latest_official_youtube_uploads() throws {
        let feed = """
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:yt="http://www.youtube.com/xml/schemas/2015">
          <entry>
            <yt:videoId>abc123def45</yt:videoId>
            <title>KXSF Live at The Chapel</title>
            <published>2026-08-26T18:30:00+00:00</published>
            <media:group xmlns:media="http://search.yahoo.com/mrss/"><media:thumbnail url="https://i.ytimg.com/vi/abc123def45/hqdefault.jpg" /></media:group>
          </entry>
        </feed>
        """

        let upload = try XCTUnwrap(KXSFYouTubeFeedParser.uploads(in: feed).first)
        XCTAssertEqual(upload.title, "KXSF Live at The Chapel")
        XCTAssertEqual(upload.videoID, "abc123def45")
        XCTAssertEqual(upload.thumbnailURL?.absoluteString, "https://i.ytimg.com/vi/abc123def45/hqdefault.jpg")
        XCTAssertEqual(upload.watchURL.absoluteString, "https://www.youtube.com/watch?v=abc123def45")
    }

    func test_skips_youtube_entries_without_a_video_id() {
        let feed = "<feed xmlns=\"http://www.w3.org/2005/Atom\"><entry><title>Broken</title></entry></feed>"

        XCTAssertTrue(KXSFYouTubeFeedParser.uploads(in: feed).isEmpty)
    }

    func test_parses_official_youtube_videos_page_when_atom_feed_is_unavailable() throws {
        let page = """
        <script>
        var ytInitialData = {"contents":{"twoColumnBrowseResultsRenderer":{"tabs":[{"tabRenderer":{"content":{"richGridRenderer":{"contents":[{"richItemRenderer":{"content":{"lockupViewModel":{"contentId":"dZAC4-xTj3U","contentImage":{"thumbnailViewModel":{"image":{"sources":[{"url":"https://i.ytimg.com/vi/dZAC4-xTj3U/hqdefault.jpg","width":480,"height":270}]}}},"metadata":{"lockupMetadataViewModel":{"title":{"content":"Amy Obenski on KXSF, June 28th, 2026"}}}}}}]}}}}]}};
        </script>
        """

        let upload = try XCTUnwrap(KXSFYouTubePageParser.uploads(in: page).first)
        XCTAssertEqual(upload.videoID, "dZAC4-xTj3U")
        XCTAssertEqual(upload.title, "Amy Obenski on KXSF, June 28th, 2026")
        XCTAssertEqual(upload.thumbnailURL?.absoluteString, "https://i.ytimg.com/vi/dZAC4-xTj3U/hqdefault.jpg")
    }
}
