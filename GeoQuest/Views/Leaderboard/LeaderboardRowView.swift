import SwiftUI

struct LeaderboardRowView: View {
    let rank: Int
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 14) {
            // Rank badge
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [rankColor, rankColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                        .shadow(color: rankColor.opacity(0.4), radius: 4, y: 2)
                    Text("\(rank)")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 38, height: 38)
                }
            }

            AvatarPreviewView(config: entry.avatarConfig, size: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.displayName)
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Label("\(entry.questsCompleted) solved", systemImage: "checkmark.circle")
                    Label("\(entry.questsCreated) created", systemImage: "plus.circle")
                }
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.totalScore)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(GQTheme.accent)
                Text("pts")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(GQTheme.paddingMedium)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                    .fill(rank <= 3 ? rankColor.opacity(0.06) : GQTheme.cardBackground)
                if rank <= 3 {
                    RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                        .stroke(rankColor.opacity(0.25), lineWidth: 2)
                }
            }
        )
        .gqShadow()
    }

    private var rankColor: Color {
        switch rank {
        case 1: return GQTheme.gold
        case 2: return .gray
        case 3: return GQTheme.accent
        default: return .clear
        }
    }
}
