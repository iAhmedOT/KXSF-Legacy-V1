import SwiftUI

struct LiveArtwork: View {
    let url: String?
    let size: CGFloat

    init(url: String?, size: CGFloat = 44) {
        self.url = url
        self.size = size
    }

    var body: some View {
        Group {
            if let url, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { phase in
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
    }

    private var fallback: some View {
        ZStack {
            Color(red: 0.71, green: 0.11, blue: 0.14)
            Image(systemName: "music.note")
                .foregroundStyle(Color(red: 0.95, green: 0.77, blue: 0.10))
        }
    }
}
