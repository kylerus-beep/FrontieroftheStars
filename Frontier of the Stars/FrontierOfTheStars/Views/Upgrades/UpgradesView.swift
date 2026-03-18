import SwiftUI

struct UpgradesView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SectionCard(title: "Available Upgrades", subtitle: "Meaningful jumps in efficiency and prestige.") {
                    if game.availableUpgrades().isEmpty {
                        Text("Keep building. New upgrades appear at generator and resource milestones.")
                            .font(.subheadline)
                            .foregroundStyle(FrontierTheme.subduedText)
                    } else {
                        ForEach(game.availableUpgrades()) { upgrade in
                            UpgradeRow(definition: upgrade, purchased: false, canPurchase: game.canPurchaseUpgrade(upgrade.id)) {
                                game.buyUpgrade(upgrade.id)
                            }
                        }
                    }
                }

                SectionCard(title: "Purchased", subtitle: "Your current run's tuned machinery.") {
                    if game.purchasedUpgrades().isEmpty {
                        Text("No upgrades yet.")
                            .font(.subheadline)
                            .foregroundStyle(FrontierTheme.subduedText)
                    } else {
                        ForEach(game.purchasedUpgrades()) { upgrade in
                            UpgradeRow(definition: upgrade, purchased: true, canPurchase: false) {
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .navigationTitle("Upgrades")
    }
}

#Preview {
    NavigationStack {
        UpgradesView()
    }
    .environmentObject(GameViewModel.preview())
}
