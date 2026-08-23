public enum PlaybackState: Equatable, Sendable {
    case idle
    case loading
    case playing

    public var isPlaying: Bool {
        switch self {
        case .playing:
            true
        case .idle, .loading:
            false
        }
    }
}
