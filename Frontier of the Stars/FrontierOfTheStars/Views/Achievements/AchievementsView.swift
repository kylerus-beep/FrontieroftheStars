import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(game.achievementDefinitions()) { achievement in
                    AchievementRow(
                        definition: achievement,
                        progress: game.achievementProgress(for: achievement),
                        completed: game.snapshot.achievementState(achievement.id).isCompleted
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .navigationTitle("Achievements")
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
    .environmentObject(GameViewModel.preview())
}
