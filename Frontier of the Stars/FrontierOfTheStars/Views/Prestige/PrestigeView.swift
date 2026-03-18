import SwiftUI

struct PrestigeView: View {
    @EnvironmentObject private var game: GameViewModel
    @State private var showingConfirmation = false

    var body: some View {
        let preview = game.prestigePreview()

        ScrollView {
            VStack(spacing: 18) {
                SectionCard(title: "Frontier Expansion", subtitle: "Reset your current run to secure permanent progress.") {
                    VStack(alignment: .leading, spacing: 12) {
                        MetricRow(title: "Current Badges", value: "\(game.snapshot.prestigeState.frontierBadges)")
                        MetricRow(title: "Potential Badges", value: "+\(preview.badgesToEarn)")
                        MetricRow(title: "Permanent Multiplier", value: FrontierFormatters.multiplier(game.permanentMultiplier()))
                        MetricRow(title: "After Expansion", value: FrontierFormatters.multiplier(preview.nextPermanentMultiplier))

                        FrontierActionButton(
                            preview.badgesToEarn > 0 ? "Expand the Frontier" : "Push Further First",
                            variant: preview.badgesToEarn > 0 ? .primary : .secondary,
                            isDisabled: preview.badgesToEarn == 0
                        ) {
                            showingConfirmation = true
                        }
                    }
                }

                SectionCard(title: "What Resets", subtitle: "Run progress goes back to camp.") {
                    Text("Resources, generators, most upgrades, and temporary boosts.")
                        .font(.subheadline)
                }

                SectionCard(title: "What Stays", subtitle: "Meta progress shapes every new run.") {
                    Text("Frontier Badges, achievements, meta upgrades, Star Shards, and premium entitlements.")
                        .font(.subheadline)
                }

                SectionCard(title: "Meta Research", subtitle: "Permanent badge upgrades.") {
                    ForEach(game.metaUpgradeDefinitions()) { upgrade in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(upgrade.name)
                                    .font(.headline)
                                Text(upgrade.description)
                                    .font(.subheadline)
                                    .foregroundStyle(FrontierTheme.subduedText)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 8) {
                                Text("\(upgrade.costBadges) badges")
                                    .font(.caption.weight(.semibold))
                                Button(game.snapshot.hasMetaUpgrade(upgrade.id) ? "Owned" : "Buy") {
                                    game.buyMetaUpgrade(upgrade.id)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(game.snapshot.hasMetaUpgrade(upgrade.id) ? .gray : FrontierTheme.secondaryAccent)
                                .disabled(game.snapshot.hasMetaUpgrade(upgrade.id) || !game.canPurchaseMetaUpgrade(upgrade.id))
                            }
                        }
                        .padding(16)
                        .frontierCard()
                    }
                }

                SectionCard(title: "Frontier Sectors", subtitle: "Long-term milestones for the forever loop.") {
                    ForEach(GameContent.sectors) { sector in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sector.name)
                                    .font(.headline)
                                Text(sector.description)
                                    .font(.subheadline)
                                    .foregroundStyle(FrontierTheme.subduedText)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(sector.requiredBadges) badges")
                                    .font(.caption)
                                Image(systemName: game.snapshot.prestigeState.totalBadgesEarned >= sector.requiredBadges ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(game.snapshot.prestigeState.totalBadgesEarned >= sector.requiredBadges ? FrontierTheme.positive : FrontierTheme.subduedText)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .navigationTitle("Prestige")
        .alert("Expand the Frontier?", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) {
            }
            Button("Confirm Reset", role: .destructive) {
                game.performPrestige()
            }
        } message: {
            Text("You will reset run progress and earn \(preview.badgesToEarn) Frontier Badges.")
        }
    }
}

#Preview {
    NavigationStack {
        PrestigeView()
    }
    .environmentObject(GameViewModel.preview())
}
