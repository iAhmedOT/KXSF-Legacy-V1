import SwiftUI
import KXSFMidnightGlassCore

struct ListenView: View {
    @ObservedObject var player: AudioPlayerService
    @StateObject private var liveShow = LiveShowStore()

    private let signalRed = Color(red: 0.71, green: 0.11, blue: 0.14)
    private let signalYellow = Color(red: 0.95, green: 0.77, blue: 0.10)

    var body: some View {
        VStack(spacing: 24) {
            Image("KXSFLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 280, height: 280)
                .shadow(color: .black.opacity(0.65), radius: 24, y: 16)
                .accessibilityLabel("KXSF 102.5 FM, San Francisco Community Radio")

            statusPanel

            playbackControl
        }
        .padding(.top, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .top)
        .task { await liveShow.refresh() }
    }

    private var statusPanel: some View {
        VStack(spacing: 9) {
            Text(statusEyebrow)
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(signalYellow)

            Text(statusTitle)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("playback-status")
                .accessibilityLabel(player.state.isPlaying ? "Live on KXSF" : statusTitle)

            Text(statusDetail)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
    }

    private var playbackControl: some View {
        playbackButton
            .buttonStyle(.plain)
            .background(.ultraThinMaterial, in: Circle())
            .overlay { Circle().stroke(.white.opacity(0.18), lineWidth: 1) }
            .shadow(color: .black.opacity(0.34), radius: 16, y: 8)
    }

    private var playbackButton: some View {
        Button(action: player.togglePlayback) {
            Image(systemName: player.state.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 38, weight: .bold))
                .frame(width: 108, height: 108)
        }
        .tint(player.state.isPlaying ? signalRed : signalYellow)
        .accessibilityIdentifier("playback-control")
        .accessibilityLabel(player.state.isPlaying ? "Pause KXSF live stream" : "Play KXSF live stream")
    }

    private var statusEyebrow: String {
        switch player.state {
        case .playing: "ON AIR NOW"
        case .loading: "CONNECTING"
        case .failed: "STREAM STATUS"
        case .idle: "SAN FRANCISCO"
        }
    }

    private var statusTitle: String {
        switch player.state {
        case .idle: "Ready to listen"
        case .loading: "Connecting to KXSF…"
        case .playing: liveShow.showName ?? "Live on KXSF"
        case .failed: "Stream unavailable"
        }
    }

    private var statusDetail: String {
        switch player.state {
        case .failed: "Please try again in a moment."
        case .loading: "Preparing the live broadcast"
        case .playing:
            liveShow.showName == nil
                ? "Independent community radio, live from San Francisco"
                : "Live now on KXSF"
        case .idle: "Tap Play to listen live"
        }
    }
}
