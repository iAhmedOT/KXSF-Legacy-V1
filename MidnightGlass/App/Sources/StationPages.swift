import SwiftUI
import KXSFMidnightGlassCore

private let stationYellow = Color(red: 0.95, green: 0.77, blue: 0.10)
private let stationRed = Color(red: 0.71, green: 0.11, blue: 0.14)

struct ShowsView: View {
    @ObservedObject var liveShow: LiveShowStore

    var body: some View {
        StationPage(title: "Shows", eyebrow: "KXSF PROGRAMMING") {
            scheduleSurface
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("schedule-shows-content")

            Link(destination: URL(string: "https://kxsf.fm/shows/")!) {
                StationLinkLabel(title: "Browse the complete show archive", symbol: "arrow.up.right.square")
            }
        }
    }

    @ViewBuilder
    private var scheduleSurface: some View {
        if liveShow.isLoading && liveShow.schedule.shows.isEmpty {
            StationCard(title: "Loading the schedule", detail: "Getting the latest programming directly from KXSF.", symbol: "dot.radiowaves.left.and.right")
        } else if liveShow.schedule.shows.isEmpty {
            StationCard(
                title: "Official schedule unavailable",
                detail: "KXSF’s schedule could not be loaded right now. The complete show archive is still available below.",
                symbol: "wifi.exclamationmark"
            )
        } else {
            VStack(alignment: .leading, spacing: 16) {
                if let currentShow = liveShow.currentShow {
                    Text("ON AIR NOW")
                        .font(.caption.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(stationYellow)
                    ShowRow(show: currentShow, emphasis: true)
                }

                Text("THIS WEEK")
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.62))

                ForEach(liveShow.schedule.sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.day.rawValue.uppercased())
                            .font(.headline)
                            .foregroundStyle(.white)
                        ForEach(section.shows.prefix(3)) { show in
                            ShowRow(show: show)
                        }
                        if section.shows.count > 3 {
                            Text("+ \(section.shows.count - 3) more on \(section.day.rawValue)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.58))
                                .padding(.leading, 4)
                        }
                    }
                }
            }
        }
    }
}

struct CalendarView: View {
    @ObservedObject var liveShow: LiveShowStore

    var body: some View {
        StationPage(title: "Calendar", eyebrow: "WHAT’S ON") {
            scheduleSurface
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("schedule-calendar-content")

            Link(destination: URL(string: "https://spinitron.com/KXSF/calendar")!) {
                StationLinkLabel(title: "Open the station calendar", symbol: "arrow.up.right.square")
            }

            Link(destination: URL(string: "https://kxsf.fm/events/")!) {
                StationLinkLabel(title: "Station events", symbol: "ticket")
            }
        }
    }

    @ViewBuilder
    private var scheduleSurface: some View {
        if liveShow.isLoading && liveShow.schedule.shows.isEmpty {
            StationCard(title: "Loading the calendar", detail: "Getting KXSF’s current weekly time slots.", symbol: "calendar.badge.clock")
        } else if liveShow.schedule.sections.isEmpty {
            StationCard(
                title: "Official calendar unavailable",
                detail: "The live KXSF schedule could not be loaded right now. You can still open the station calendar below.",
                symbol: "wifi.exclamationmark"
            )
        } else {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(liveShow.schedule.sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.day.rawValue.uppercased())
                            .font(.headline)
                            .foregroundStyle(.white)
                        ForEach(section.shows) { show in
                            ScheduleRow(show: show)
                        }
                    }
                }
            }
        }
    }
}

struct AboutKXSFView: View {
    var body: some View {
        StationPage(title: "About KXSF", eyebrow: "SAN FRANCISCO COMMUNITY RADIO") {
            StationCard(
                title: "Broadcasting diverse voices",
                detail: "KXSF 102.5 FM is a San Francisco Community Radio project: an all-volunteer, IRS-recognized 501(c)(3) nonprofit supporting creative, socially aware, and community-led programming.",
                symbol: "building.2"
            )

            Link(destination: URL(string: "https://kxsf.fm/")!) {
                StationLinkLabel(title: "Visit KXSF.FM", symbol: "globe")
            }

            Link(destination: URL(string: "https://kxsf.fm/support/")!) {
                StationLinkLabel(title: "Support KXSF", symbol: "heart.fill", accent: stationRed)
            }
        }
    }
}

private struct ShowRow: View {
    let show: KXSFShow
    var emphasis = false

    var body: some View {
        Link(destination: show.detailURL) {
            HStack(spacing: 14) {
                ShowArtwork(show: show, size: emphasis ? 76 : 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text(show.name)
                        .font(emphasis ? .headline.weight(.bold) : .subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(show.timeRange)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.66))
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(stationYellow)
            }
            .padding(emphasis ? 14 : 10)
            .background(.white.opacity(emphasis ? 0.11 : 0.06), in: RoundedRectangle(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 1) }
        }
        .accessibilityLabel("\(show.name), \(show.day.rawValue), \(show.timeRange)")
    }
}

private struct ScheduleRow: View {
    let show: KXSFShow

    var body: some View {
        Link(destination: show.detailURL) {
            HStack(spacing: 12) {
                Text(show.timeRange)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(stationYellow)
                    .frame(width: 94, alignment: .leading)
                Text(show.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.48))
            }
            .padding(14)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
            .overlay { RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.11), lineWidth: 1) }
        }
        .accessibilityLabel("\(show.name), \(show.day.rawValue), \(show.timeRange)")
    }
}

private struct StationPage<Content: View>: View {
    let title: String
    let eyebrow: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(eyebrow)
                    .font(.caption.weight(.bold))
                    .tracking(1.15)
                    .foregroundStyle(stationYellow)
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                content
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
    }
}

private struct StationCard: View {
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(stationYellow)
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.08), in: Circle())
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(detail).font(.subheadline).foregroundStyle(.white.opacity(0.68))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay { RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.14), lineWidth: 1) }
    }
}

private struct StationLinkLabel: View {
    let title: String
    let symbol: String
    var accent: Color = stationYellow

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).frame(width: 24)
            Text(title).font(.headline)
            Spacer()
            Image(systemName: "chevron.right").font(.caption.weight(.bold))
        }
        .foregroundStyle(accent)
        .frame(maxWidth: .infinity, minHeight: 52)
        .padding(.horizontal, 16)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.12), lineWidth: 1) }
    }
}
