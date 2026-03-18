import SwiftUI

struct GeneratorRow: View {
    let definition: GeneratorDefinition
    let state: GeneratorState
    let cost: Double
    let canAfford: Bool
    let onBuy: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(FrontierTheme.secondaryAccent.opacity(0.14))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: GameContent.resourceDefinition(for: definition.resource).icon)
                        .foregroundStyle(FrontierTheme.secondaryAccent)
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(definition.name)
                            .font(.headline)
                        Text(definition.flavor)
                            .font(.caption)
                            .foregroundStyle(FrontierTheme.subduedText)
                    }
                    Spacer()
                    Text("x\(state.owned)")
                        .font(.title3.weight(.bold))
                }

                HStack {
                    Text("+\(LargeNumberFormatter.rate(definition.baseProductionPerSecond)) each")
                        .font(.subheadline)
                        .foregroundStyle(FrontierTheme.subduedText)
                    Spacer()
                    Text("\(LargeNumberFormatter.format(cost)) \(GameContent.resourceDefinition(for: definition.costResource).name)")
                        .font(.subheadline.weight(.medium))
                }

                Button(action: onBuy) {
                    Text(state.unlocked ? (canAfford ? "Hire" : "Need More") : "Locked")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(canAfford && state.unlocked ? FrontierTheme.accent : Color.black.opacity(0.08))
                        )
                        .foregroundStyle(canAfford && state.unlocked ? Color.white : Color.black.opacity(0.5))
                }
                .disabled(!canAfford || !state.unlocked)
            }
        }
        .padding(16)
        .frontierCard()
    }
}
