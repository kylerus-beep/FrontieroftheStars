import SwiftUI

struct DailyRewardSheet: View {
    @EnvironmentObject private var game: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let reward = game.currentDailyReward()

        VStack(alignment: .leading, spacing: 20) {
            Text("Daily Supply Drop")
                .font(.largeTitle.weight(.bold))
            Text("Your streak is \(game.snapshot.dailyRewardState.streak) day\(game.snapshot.dailyRewardState.streak == 1 ? "" : "s").")
                .font(.subheadline)
                .foregroundStyle(FrontierTheme.subduedText)

            RewardSummaryCard(reward: reward)

            FrontierActionButton("Claim Reward") {
                game.claimDailyReward()
                dismiss()
            }

            Spacer()
        }
        .padding(24)
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    DailyRewardSheet()
        .environmentObject(GameViewModel.preview())
}
