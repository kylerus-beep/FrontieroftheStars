import SwiftUI

struct AchievementRow: View {
    let definition: AchievementDefinition
    let progress: Double
    let completed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(definition.title)
                        .font(.headline)
                    Text(definition.description)
                        .font(.subheadline)
                        .foregroundStyle(FrontierTheme.subduedText)
                }
                Spacer()
                Image(systemName: completed ? "checkmark.seal.fill" : "seal")
                    .foregroundStyle(completed ? FrontierTheme.positive : FrontierTheme.subduedText)
            }

            ProgressView(value: progress)
                .tint(completed ? FrontierTheme.positive : FrontierTheme.accent)

            Text(rewardLabel(definition.reward))
                .font(.caption.weight(.medium))
                .foregroundStyle(FrontierTheme.secondaryAccent)
        }
        .padding(16)
        .frontierCard()
    }

    private func rewardLabel(_ reward: AchievementReward) -> String {
        var parts: [String] = []
        if reward.frontierBadges > 0 { parts.append("+\(reward.frontierBadges) Frontier Badges") }
        if reward.starShards > 0 { parts.append("+\(reward.starShards) Star Shards") }
        if reward.permanentProductionBonus > 0 { parts.append("+\(Int(reward.permanentProductionBonus * 100))% permanent output") }
        return parts.joined(separator: " • ")
    }
}
