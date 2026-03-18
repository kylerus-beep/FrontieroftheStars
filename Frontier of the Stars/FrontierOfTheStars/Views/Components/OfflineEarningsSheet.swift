import SwiftUI

struct OfflineEarningsSheet: View {
    @EnvironmentObject private var game: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let summary = game.pendingOfflineSummary {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Welcome Back")
                        .font(.largeTitle.weight(.bold))
                    Text("You were away for \(timeString(summary.timeAway)). Rewards are capped at \(timeString(summary.cappedTime)).")
                        .font(.subheadline)
                        .foregroundStyle(FrontierTheme.subduedText)

                    if summary.timeAway > summary.cappedTime + 60 {
                        Text("You hit your offline cap this run. Extra Offline Time and caravan upgrades make long breaks more rewarding.")
                            .font(.caption)
                            .foregroundStyle(FrontierTheme.subduedText)
                    }

                    RewardSummaryCard(reward: summary.rewards)

                    if let insight = game.offlineClaimInsight(multiplier: 1) {
                        Text(insight)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(FrontierTheme.secondaryAccent)
                    }

                    FrontierActionButton("Claim Base Rewards", variant: .secondary) {
                        game.claimOfflineRewards(multiplier: 1)
                        dismiss()
                    }

                    FrontierActionButton(
                        game.rewardedButtonTitle(for: .offlineMultiplier),
                        variant: .primary,
                        isDisabled: !game.canTriggerRewardedOffer(.offlineMultiplier)
                    ) {
                        Task {
                            let claimed = await game.triggerRewardedAd(.offlineMultiplier)
                            if claimed && game.pendingOfflineSummary == nil {
                                dismiss()
                            }
                        }
                    }

                    if let pitch = game.offlineMultiplierPitch() {
                        Text(pitch)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(FrontierTheme.accent)
                    }

                    if let status = game.rewardedStatusText(for: .offlineMultiplier) {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(FrontierTheme.subduedText)
                    }
                }
                .padding(24)
            }
            .presentationDragIndicator(.visible)
        }
    }

    private func timeString(_ seconds: TimeInterval) -> String {
        FrontierFormatters.abbreviatedDuration(seconds)
    }
}

#Preview {
    let previewGame = GameViewModel.previewOffline(summary: OfflineEarningsSummary(
        timeAway: 14_400,
        cappedTime: 14_400,
        rewards: RewardBundle(resources: [.ore: 4_800, .alienDust: 1_250, .energy: 620, .refinedMetal: 42])
    ))

    return OfflineEarningsSheet()
        .environmentObject(previewGame)
}
