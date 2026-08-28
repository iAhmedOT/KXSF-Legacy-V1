import AppIntents
import SwiftUI
import WidgetKit
import KXSFMidnightGlassCore

private let widgetOrange = Color(red: 1.00, green: 0.47, blue: 0.12)
private let widgetRed = Color(red: 0.71, green: 0.11, blue: 0.14)

struct KXSFHomeEntry: TimelineEntry {
    let date: Date
    let showTitle: String
    let timeRange: String?
    let artworkURL: URL?
    let isPlaying: Bool
}

struct KXSFHomeWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "KXSF Now Playing"
    static let description = IntentDescription("Show KXSF's current program and control the live stream.")
}

struct KXSFHomeWidget: Widget {
    let kind = "KXSFHomeWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: KXSFHomeWidgetIntent.self, provider: KXSFHomeTimelineProvider()) { entry in
            KXSFHomeWidgetView(entry: entry)
        }
        .configurationDisplayName("KXSF Now Playing")
        .description("See the current KXSF show and control the live stream.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct KXSFHomeTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> KXSFHomeEntry {
        KXSFHomeEntry(date: .now, showTitle: "KXSF live radio", timeRange: nil, artworkURL: nil, isPlaying: KXSFPlaybackSnapshot.isPlaying)
    }

    func snapshot(for configuration: KXSFHomeWidgetIntent, in context: Context) async -> KXSFHomeEntry {
        await currentEntry()
    }

    func timeline(for configuration: KXSFHomeWidgetIntent, in context: Context) async -> Timeline<KXSFHomeEntry> {
        let entry = await currentEntry()
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    private func currentEntry() async -> KXSFHomeEntry {
        guard let url = URL(string: "https://kxsf.fm/schedule-shows/") else {
            return fallbackEntry
        }
        do {
            var request = URLRequest(url: url)
            request.setValue("KXSF Midnight Glass/1.0", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: request)
            let schedule = KXSFScheduleParser.schedule(in: String(decoding: data, as: UTF8.self))
            if let show = schedule.currentShow {
                return KXSFHomeEntry(
                    date: .now,
                    showTitle: show.name,
                    timeRange: show.timeRange,
                    artworkURL: show.artworkURL,
                    isPlaying: KXSFPlaybackSnapshot.isPlaying
                )
            }
        } catch { }
        return fallbackEntry
    }

    private var fallbackEntry: KXSFHomeEntry {
        KXSFHomeEntry(date: .now, showTitle: "KXSF live radio", timeRange: nil, artworkURL: nil, isPlaying: KXSFPlaybackSnapshot.isPlaying)
    }
}

private struct KXSFHomeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: KXSFHomeEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallLayout
            default:
                mediumLayout
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [.black, Color(red: 0.13, green: 0.025, blue: 0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var mediumLayout: some View {
        HStack(spacing: 14) {
            WidgetArtwork(url: entry.artworkURL, size: 70)

            VStack(alignment: .leading, spacing: 5) {
                Text(entry.isPlaying ? "NOW PLAYING" : "KXSF 102.5 FM")
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(widgetOrange)
                Text(entry.showTitle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                if let timeRange = entry.timeRange {
                    Text(timeRange)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.70))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)
            playbackButton(size: 46)
        }
        .accessibilityElement(children: .contain)
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                WidgetArtwork(url: entry.artworkURL, size: 60)
                Spacer(minLength: 6)
                playbackButton(size: 44)
            }

            Spacer(minLength: 0)

            Text(entry.isPlaying ? "NOW PLAYING" : "KXSF 102.5 FM")
                .font(.caption2.weight(.bold))
                .tracking(0.7)
                .foregroundStyle(widgetOrange)
            Text(entry.showTitle)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .accessibilityElement(children: .contain)
    }

    private func playbackButton(size: CGFloat) -> some View {
        Button(intent: ToggleKXSFPlaybackIntent()) {
            Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(widgetRed, in: Circle())
                .overlay { Circle().stroke(.white.opacity(0.16), lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.isPlaying ? "Pause KXSF live stream" : "Play KXSF live stream")
    }
}

private struct WidgetArtwork: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    if case let .success(image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(colors: [widgetRed, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "music.note")
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundStyle(widgetOrange)
        }
    }
}
