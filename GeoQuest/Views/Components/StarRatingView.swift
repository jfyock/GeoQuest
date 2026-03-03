import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int
    var maxRating: Int = 5
    var size: CGFloat = 28
    var interactive: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(star <= rating ? .yellow : .gray.opacity(0.3))
                    .onTapGesture {
                        if interactive {
                            withAnimation(GQTheme.bouncyQuick) {
                                rating = star
                            }
                        }
                    }
                    .scaleEffect(star <= rating ? 1.1 : 1.0)
                    .animation(GQTheme.bouncy, value: rating)
            }
        }
    }
}

struct StarRatingDisplay: View {
    let rating: Double
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: Double(star) <= rating ? "star.fill" :
                        Double(star) - 0.5 <= rating ? "star.leadinghalf.filled" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(.yellow)
            }
        }
    }
}
