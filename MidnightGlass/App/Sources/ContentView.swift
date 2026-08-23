import SwiftUI
import KXSFMidnightGlassCore

struct ContentView: View {
    @StateObject private var player = AudioPlayerService()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.06, green: 0.08, blue: 0.13)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("KXSF")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)

                Text("102.5 FM · San Francisco")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.72))

                VStack(spacing: 8) {
                    Text(statusTitle)
                        .font(.title2.weight(.semibold))
                        .accessibilityIdentifier("playback-status")
                    Text(statusDetail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
                .padding(.horizontal, 24)

                playbackControl

                Spacer()
            }
            .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var playbackControl: some View {
        if #available(iOS 26.0, *) {
            playbackButton.buttonStyle(.glass)
        } else {
            playbackButton.buttonStyle(.borderedProminent)
        }
    }

    private var playbackButton: some View {
        Button(action: player.togglePlayback) {
            Image(systemName: player.state.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 32, weight: .bold))
                .frame(width: 88, height: 88)
        }
        .accessibilityIdentifier("playback-control")
        .accessibilityLabel(player.state.isPlaying ? "Pause KXSF" : "Play KXSF")
    }

    private var statusTitle: String {
        switch player.state {
        case .idle:
            "Ready to listen"
        case .loading:
            "Connecting to KXSF…"
        case .playing:
            "Live on KXSF"
        case .failed:
            "Stream unavailable"
        }
    }

    private var statusDetail: String {
        switch player.state {
        case .failed:
            "Please try again in a moment."
        case .loading:
            "Preparing the live stream"
        default:
            "102.5 FM · San Francisco"
        }
    }
}

#Preview {
    ContentView()
}
