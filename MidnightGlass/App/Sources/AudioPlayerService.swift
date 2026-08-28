import AVFoundation
import Combine
import KXSFMidnightGlassCore

@MainActor
final class AudioPlayerService: NSObject, ObservableObject {
    static let shared = AudioPlayerService()

    @Published private(set) var state: PlaybackState = .idle

    private let endpoint: any StreamEndpointProviding
    private var player: AVPlayer?
    private var timeControlObservation: NSKeyValueObservation?

    init(endpoint: any StreamEndpointProviding = DirectKXSFEndpoint()) {
        self.endpoint = endpoint
        super.init()
    }

    func togglePlayback() {
        state.isPlaying ? pause() : play()
    }

    func play() {
        guard !state.isPlaying else { return }

        state = state.applying(.playRequested)

        Task { [weak self] in
            guard await Self.configureAudioSession() else {
                self?.state = .failed(.streamUnavailable)
                return
            }
            guard let self else { return }

            let player = AVPlayer(url: endpoint.liveStreamURL)
            self.player = player
            observePlaybackState(of: player)
            player.play()
        }
    }

    func pause() {
        player?.pause()
        state = .idle
    }

    private nonisolated static func configureAudioSession() async -> Bool {
        await Task.detached(priority: .userInitiated) {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default)
                try session.setActive(true)
                return true
            } catch {
                return false
            }
        }.value
    }

    private func observePlaybackState(of player: AVPlayer) {
        timeControlObservation = player.observe(
            \.timeControlStatus,
            options: [.initial, .new]
        ) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }

                switch player.timeControlStatus {
                case .playing:
                    self.state = .playing
                case .waitingToPlayAtSpecifiedRate:
                    self.state = .loading
                case .paused:
                    if player.currentItem?.status == .failed {
                        self.state = .failed(.streamUnavailable)
                    }
                @unknown default:
                    self.state = .failed(.streamUnavailable)
                }
            }
        }
    }
}
