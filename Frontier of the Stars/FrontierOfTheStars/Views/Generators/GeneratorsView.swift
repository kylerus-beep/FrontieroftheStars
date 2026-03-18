import SwiftUI

struct GeneratorsView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(GameContent.generators) { generator in
                    let state = game.generatorState(for: generator.id)
                    let visible = state.unlocked || game.resourceState(for: generator.costResource).unlocked
                    if visible {
                        GeneratorRow(
                            definition: generator,
                            state: state,
                            cost: game.currentGeneratorCost(generator.id),
                            canAfford: game.canAffordGenerator(generator.id)
                        ) {
                            game.buyGenerator(generator.id)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .navigationTitle("Generators")
    }
}

#Preview {
    NavigationStack {
        GeneratorsView()
    }
    .environmentObject(GameViewModel.preview())
}
