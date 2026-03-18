import SwiftUI

struct StoreProductCard: View {
    let product: StoreProductDefinition
    let price: String
    let buttonTitle: String
    let isOwned: Bool
    let canPurchase: Bool
    let onPurchase: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(product.name)
                            .font(.headline)
                        if let badge = product.badge {
                            Text(badge.uppercased())
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(FrontierTheme.secondaryAccent.opacity(0.14))
                                )
                                .foregroundStyle(FrontierTheme.secondaryAccent)
                        }
                    }
                    Text(product.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(FrontierTheme.subduedText)
                }

                Spacer()

                Text(price)
                    .font(.headline.weight(.bold))
            }

            if !product.highlights.isEmpty {
                ForEach(product.highlights, id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(FrontierTheme.accent)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(line)
                            .font(.subheadline)
                    }
                }
            }

            FrontierActionButton(buttonTitle, variant: isOwned ? .ghost : .primary, isDisabled: !canPurchase) {
                onPurchase()
            }
        }
        .padding(18)
        .frontierCard()
    }
}
