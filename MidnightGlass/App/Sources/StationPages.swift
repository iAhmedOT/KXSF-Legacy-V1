import SwiftUI

private let stationYellow = Color(red: 0.95, green: 0.77, blue: 0.10)
private let stationRed = Color(red: 0.71, green: 0.11, blue: 0.14)

struct ShowsView: View {
    var body: some View {
        StationPage(title: "Shows", eyebrow: "KXSF PROGRAMMING") {
            StationCard(
                title: "Find your next show",
                detail: "Browse KXSF’s official archive of community, music, cultural, and public-affairs programming.",
                symbol: "music.mic"
            )
            Link(destination: URL(string: "https://kxsf.fm/shows/")!) {
                StationLinkLabel(title: "Browse all shows", symbol: "arrow.up.right.square")
            }

            Link(destination: URL(string: "https://kxsf.fm/schedule-shows/")!) {
                StationLinkLabel(title: "View weekly schedule", symbol: "calendar")
            }
        }
    }
}

struct CalendarView: View {
    var body: some View {
        StationPage(title: "Calendar", eyebrow: "WHAT’S ON") {
            StationCard(
                title: "Program calendar",
                detail: "See KXSF’s current program schedule, including hosts and time slots, through the station’s official calendar.",
                symbol: "calendar.badge.clock"
            )
            Link(destination: URL(string: "https://spinitron.com/KXSF/calendar")!) {
                StationLinkLabel(title: "Open program calendar", symbol: "arrow.up.right.square")
            }

            Link(destination: URL(string: "https://kxsf.fm/events/")!) {
                StationLinkLabel(title: "Station events", symbol: "ticket")
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
