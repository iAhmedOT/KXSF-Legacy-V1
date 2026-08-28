import ActivityKit
import SwiftUI
import WidgetKit

private let activityOrange = Color(red: 1.00, green: 0.47, blue: 0.12)
private let activityRed = Color(red: 0.71, green: 0.11, blue: 0.14)

@main
struct KXSFLiveActivities: WidgetBundle {
    var body: some Widget {
        KXSFNowPlayingLiveActivity()
        KXSFHomeWidget()
    }
}

private struct KXSFNowPlayingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KXSFLiveActivityAttributes.self) { context in
            HStack(spacing: 14) {
                LiveArtwork(url: context.state.artworkURL, size: 60)

                VStack(alignment: .leading, spacing: 3) {
                    Text("NOW PLAYING")
                        .font(.caption2.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(activityOrange)
                    Text(context.state.showTitle)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    activityMetadata(context: context)
                }

                Spacer(minLength: 0)
                playbackButton(context: context, size: 46)
            }
            .padding(.horizontal, 18)
            .activityBackgroundTint(.black)
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveArtwork(url: context.state.artworkURL, size: 46)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NOW PLAYING")
                            .font(.caption2.weight(.bold))
                            .tracking(0.8)
                            .foregroundStyle(activityOrange)
                        Text(context.state.showTitle)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        activityMetadata(context: context)
                            .font(.caption2)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    playbackButton(context: context, size: 38)
                }
            } compactLeading: {
                LiveArtwork(url: context.state.artworkURL, size: 18)
            } compactTrailing: {
                Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                    .foregroundStyle(activityOrange)
            } minimal: {
                LiveArtwork(url: context.state.artworkURL, size: 18)
            }
            .widgetURL(URL(string: "kxsf://listen"))
            .keylineTint(activityOrange)
        }
    }

    @ViewBuilder
    private func activityMetadata(
        context: ActivityViewContext<KXSFLiveActivityAttributes>
    ) -> some View {
        HStack(spacing: 5) {
            if let hostName = context.state.hostName {
                Text("with \(hostName)")
            }
            if context.state.hostName != nil, context.state.timeRange != nil {
                Text("•")
            }
            if let timeRange = context.state.timeRange {
                Text(timeRange)
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.white.opacity(0.70))
        .lineLimit(1)
    }

    private func playbackButton(
        context: ActivityViewContext<KXSFLiveActivityAttributes>,
        size: CGFloat
    ) -> some View {
        Button(intent: ToggleKXSFPlaybackIntent()) {
            Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: size * 0.40, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(activityRed, in: Circle())
                .overlay { Circle().stroke(.white.opacity(0.16), lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(context.state.isPlaying ? "Pause KXSF live stream" : "Play KXSF live stream")
    }
}
