import SwiftUI

struct UpgradeRow: View {
    let definition: UpgradeDefinition
    let purchased: Bool
    let canPurchase: Bool
    let onBuy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(definition.name)
                        .font(.headline)
                    Text(definition.description)
                        .font(.subheadline)
                        .foregroundStyle(FrontierTheme.subduedText)
                }
                Spacer()
                Text(purchased ? "Owned" : LargeNumberFormatter.format(definition.costAmount))
                    .font(.subheadline.weight(.semibold))
            }

            HStack {
                Text(GameContent.resourceDefinition(for: definition.costResource).name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(FrontierTheme.secondaryAccent)
                Spacer()
                if !purchased {
                    Button(action: onBuy) {
                        Text(canPurchase ? "Purchase" : "Locked")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(canPurchase ? FrontierTheme.secondaryAccent : Color.black.opacity(0.08))
                            )
                            .foregroundStyle(canPurchase ? Color.white : Color.black.opacity(0.45))
                    }
                    .disabled(!canPurchase)
                }
            }
        }
        .padding(16)
        .frontierCard()
    }
}
