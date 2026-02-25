import SwiftUI

struct LeaderboardRowView: View {
    let rank: Int
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 14) {
            // Rank
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 36, height: 36)
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                }
            }

            // Avatar
            AvatarPreviewView(config: entry.avatarConfig, size: 42)

            // Name and stats
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(GQTheme.bodyFont.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Label("\(entry.questsCompleted) solved", systemImage: "checkmark.circle")
                    Label("\(entry.questsCreated) created", systemImage: "plus.circle")
                }
                .font(GQTheme.caption2Font)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.totalScore)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(GQTheme.accent)
                Text("pts")
                    .font(GQTheme.caption2Font)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(GQTheme.paddingMedium)
        .background(
            rank <= 3 ? rankColor.opacity(0.05) : Color.clear,
            in: RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
        )
        .overlay {
            if rank <= 3 {
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                    .strokeBorder(rankColor.opacity(0.2), lineWidth: 1)
            }
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .clear
        }
    }
}
