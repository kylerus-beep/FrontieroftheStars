import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroCard

                if !game.snapshot.activeBoosts.isEmpty {
                    BoostBanner(boosts: game.snapshot.activeBoosts)
                }

                SectionCard(title: "Frontier Ledger", subtitle: "Your live resource economy.") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(GameContent.resources.filter { game.resourceState(for: $0.id).unlocked }) { resource in
                            ResourceChip(
                                resource: resource,
                                amount: game.resourceState(for: resource.id).amount,
                                rate: game.productionRate(for: resource.id)
                            )
                        }
                    }
                }

                SectionCard(title: "Prospector Actions", subtitle: "Early taps still matter in short sessions.") {
                    ForEach(GameContent.resources.filter { $0.manualYield > 0 && game.resourceState(for: $0.id).unlocked }) { resource in
                        Button {
                            game.manualCollect(resource.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Prospect \(resource.name)")
                                        .font(.headline)
                                    Text("+\(LargeNumberFormatter.format(resource.manualYield)) base")
                                        .font(.subheadline)
                                        .foregroundStyle(FrontierTheme.subduedText)
                                }
                                Spacer()
                                Image(systemName: resource.icon)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.62))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                SectionCard(title: "Top Hands", subtitle: "Your most valuable machines right now.") {
                    let topGenerators = GameContent.generators.filter { game.generatorState(for: $0.id).owned > 0 }.prefix(3)
                    if topGenerators.isEmpty {
                        Text("Hire your first generator to start the frontier economy.")
                            .font(.subheadline)
                            .foregroundStyle(FrontierTheme.subduedText)
                    } else {
                        ForEach(Array(topGenerators)) { generator in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(generator.name)
                                        .font(.headline)
                                    Text("\(game.generatorState(for: generator.id).owned) owned")
                                        .font(.subheadline)
                                        .foregroundStyle(FrontierTheme.subduedText)
                                }
                                Spacer()
                                Text(LargeNumberFormatter.rate(game.productionRate(for: generator.resource)))
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                }

                SectionCard(title: "Targets", subtitle: "Always another frontier to chase.") {
                    ForEach(game.progressionTargets()) { target in
                        TargetCard(target: target)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .navigationTitle("Frontier")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    game.showingSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
    }

    private var heroCard: some View {
        let sector = game.currentSector()
        let preview = game.prestigePreview()

        return SectionCard(title: sector.name, subtitle: sector.description) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(game.snapshot.prestigeState.frontierBadges) Badges")
                            .font(.title.weight(.bold))
                        Text("\(FrontierFormatters.multiplier(game.permanentMultiplier())) permanent output")
                            .font(.subheadline)
                            .foregroundStyle(FrontierTheme.subduedText)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Next Expansion")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(FrontierTheme.secondaryAccent)
                        Text("+\(preview.badgesToEarn)")
                            .font(.title.weight(.bold))
                    }
                }

                Text(sector.bonusLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FrontierTheme.secondaryAccent)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(GameViewModel.preview())
}
