import SwiftUI

struct ContentView: View {
    @StateObject private var player = AudioPlayerService()
    @StateObject private var liveShow = LiveShowStore()
    @State private var selectedTab: StationTab = .listen

    var body: some View {
        GeometryReader { geometry in
            let navigationHeight: CGFloat = 70
            let bottomGap = max(12, geometry.safeAreaInsets.bottom + 4)
            let contentHeight = geometry.size.height - navigationHeight - bottomGap

            ZStack {
                StationBackdrop(isLive: player.state.isPlaying)

                selectedDestination
                    .frame(
                        width: geometry.size.width,
                        height: contentHeight,
                        alignment: .top
                    )
                    .clipped()
                    .position(
                        x: geometry.size.width / 2,
                        y: contentHeight / 2
                    )

                StationTabBar(selectedTab: $selectedTab)
                    .frame(width: geometry.size.width - 40, height: navigationHeight)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height - bottomGap - (navigationHeight / 2)
                    )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .task { await liveShow.refresh() }
    }

    @ViewBuilder
    private var selectedDestination: some View {
        switch selectedTab {
        case .listen:
            ListenView(player: player, liveShow: liveShow)
        case .shows:
            ShowsView(liveShow: liveShow)
        case .calendar:
            CalendarView(liveShow: liveShow)
        case .about:
            AboutKXSFView()
        }
    }
}

enum StationTab: String, CaseIterable, Identifiable {
    case listen, shows, calendar, about

    var id: Self { self }

    var title: String {
        switch self {
        case .listen: "Listen"
        case .shows: "Shows"
        case .calendar: "Calendar"
        case .about: "About"
        }
    }

    var icon: String {
        switch self {
        case .listen: "dot.radiowaves.left.and.right"
        case .shows: "music.mic"
        case .calendar: "calendar"
        case .about: "info.circle"
        }
    }
}

struct StationBackdrop: View {
    let isLive: Bool
    private let canvas = Color(red: 0.02, green: 0.02, blue: 0.02)
    private let signalRed = Color(red: 0.71, green: 0.11, blue: 0.14)
    private let signalYellow = Color(red: 0.95, green: 0.77, blue: 0.10)

    var body: some View {
        ZStack {
            canvas
            Circle()
                .fill(signalRed.opacity(isLive ? 0.22 : 0.14))
                .frame(width: 340, height: 340)
                .blur(radius: 104)
                .offset(x: -120, y: -240)
            Circle()
                .fill(signalYellow.opacity(isLive ? 0.12 : 0.07))
                .frame(width: 260, height: 260)
                .blur(radius: 100)
                .offset(x: 150, y: 180)
            LinearGradient(
                colors: [.clear, .black.opacity(0.40)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .accessibilityHidden(true)
    }
}

private struct StationTabBar: View {
    @Binding var selectedTab: StationTab
    private let active = Color(red: 0.95, green: 0.77, blue: 0.10)

    var body: some View {
        HStack(spacing: 4) {
            ForEach(StationTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 19, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(selectedTab == tab ? active : .white.opacity(0.70))
                    .background {
                        if selectedTab == tab {
                            Capsule().fill(.white.opacity(0.12))
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab-\(tab.rawValue)")
                .accessibilityLabel(tab.title)
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay { Capsule().stroke(.white.opacity(0.14), lineWidth: 1) }
    }
}

#Preview {
    ContentView()
}
