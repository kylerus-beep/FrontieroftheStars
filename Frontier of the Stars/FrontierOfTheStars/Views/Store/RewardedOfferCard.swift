import SwiftUI

struct RewardedOfferCard: View {
    let offer: RewardedOfferDefinition
    let buttonTitle: String
    let contextText: String?
    let statusText: String?
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(offer.title)
                    .font(.headline)
                Spacer()
                Text(offer.badge.uppercased())
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(FrontierTheme.accent.opacity(0.14))
                    )
                    .foregroundStyle(FrontierTheme.accent)
            }

            Text(offer.subtitle)
                .font(.subheadline)
                .foregroundStyle(FrontierTheme.subduedText)

            Text(offer.rewardDescription)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FrontierTheme.secondaryAccent)

            if let contextText {
                Text(contextText)
                    .font(.caption)
                    .foregroundStyle(FrontierTheme.secondaryAccent.opacity(0.85))
            }

            if let statusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(FrontierTheme.subduedText)
            }

            FrontierActionButton(buttonTitle, variant: .secondary, isDisabled: isDisabled) {
                onTap()
            }
        }
        .padding(18)
        .frontierCard()
    }
}
