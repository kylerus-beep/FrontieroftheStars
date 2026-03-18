import SwiftUI

struct RewardSummaryCard: View {
    let reward: RewardBundle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(ResourceID.allCases.filter { (reward.resources[$0] ?? 0) > 0 }, id: \.self) { resource in
                HStack {
                    Text(GameContent.resourceDefinition(for: resource).name)
                    Spacer()
                    Text(LargeNumberFormatter.format(reward.resources[resource] ?? 0))
                }
                .font(.subheadline)
            }

            if reward.frontierBadges > 0 {
                MetricRow(title: "Frontier Badges", value: "+\(reward.frontierBadges)")
            }

            if reward.starShards > 0 {
                MetricRow(title: "Star Shards", value: "+\(reward.starShards)")
            }

            if let boost = reward.boost {
                MetricRow(title: boost.title, value: "\(FrontierFormatters.percent(boost.multiplier)) • \(FrontierFormatters.abbreviatedDuration(boost.duration))")
            }
        }
        .padding(18)
        .frontierCard()
    }
}
