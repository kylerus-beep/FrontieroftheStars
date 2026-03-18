import SwiftUI

struct StoreView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                premiumHero

                SectionCard(title: "Star Shards", subtitle: "Optional convenience currency.") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(game.snapshot.premiumWallet.starShards)")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("Spend on boosts and crates, not mandatory progression.")
                                .font(.subheadline)
                                .foregroundStyle(FrontierTheme.subduedText)
                        }
                        Spacer()
                    }

                    VStack(spacing: 12) {
                        FrontierActionButton("Boost \(GameBalance.shardBoostCost)", variant: .secondary, isDisabled: game.snapshot.premiumWallet.starShards < GameBalance.shardBoostCost) {
                            game.useShardBoost()
                        }

                        FrontierActionButton("Crate \(GameBalance.shardCrateCost)", variant: .ghost, isDisabled: game.snapshot.premiumWallet.starShards < GameBalance.shardCrateCost) {
                            game.useShardCrate()
                        }
                    }
                }

                SectionCard(title: "Rewarded Actions", subtitle: "Optional ad rewards at natural friction points.") {
                    ForEach(game.rewardedOfferDefinitions()) { offer in
                        RewardedOfferCard(
                            offer: offer,
                            buttonTitle: game.rewardedButtonTitle(for: offer.placement),
                            contextText: game.rewardedContextText(for: offer.placement),
                            statusText: game.rewardedStatusText(for: offer.placement),
                            isDisabled: !game.canTriggerRewardedOffer(offer.placement)
                        ) {
                            Task {
                                _ = await game.triggerRewardedAd(offer.placement)
                            }
                        }
                    }
                }

                SectionCard(title: "Featured Offers", subtitle: "Clean value, no mandatory access.") {
                    ForEach(game.storeProducts(in: .featured)) { product in
                        StoreProductCard(
                            product: product,
                            price: game.purchaseManager.priceLabel(for: product),
                            buttonTitle: game.purchaseButtonTitle(for: product),
                            isOwned: game.isProductOwned(product.id),
                            canPurchase: game.canPurchase(product)
                        ) {
                            Task {
                                await game.purchase(product)
                            }
                        }
                    }
                }

                SectionCard(title: "Permanent Upgrades", subtitle: "Long-term convenience and style.") {
                    ForEach(game.storeProducts(in: .permanent)) { product in
                        StoreProductCard(
                            product: product,
                            price: game.purchaseManager.priceLabel(for: product),
                            buttonTitle: game.purchaseButtonTitle(for: product),
                            isOwned: game.isProductOwned(product.id),
                            canPurchase: game.canPurchase(product)
                        ) {
                            Task {
                                await game.purchase(product)
                            }
                        }
                    }
                }

                SectionCard(title: "Shard Bundles", subtitle: "Optional currency packs for convenience spends.") {
                    ForEach(game.storeProducts(in: .starShards)) { product in
                        StoreProductCard(
                            product: product,
                            price: game.purchaseManager.priceLabel(for: product),
                            buttonTitle: game.purchaseButtonTitle(for: product),
                            isOwned: false,
                            canPurchase: true
                        ) {
                            Task {
                                await game.purchase(product)
                            }
                        }
                    }

                    FrontierActionButton("Restore Purchases", variant: .ghost) {
                        Task {
                            await game.restorePurchases()
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .navigationTitle("Store")
    }

    private var premiumHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Marshal's Exchange")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)
            Text("Optional acceleration, polished QoL, and premium cosmetics for the frontier. The full game loop remains playable for free.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.82))

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Star Shards")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.74))
                    Text("\(game.snapshot.premiumWallet.starShards)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("Permanent Output")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.74))
                    Text(FrontierFormatters.multiplier(game.permanentMultiplier()))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(FrontierTheme.premiumGradient)
                .shadow(color: FrontierTheme.shadow, radius: 18, x: 0, y: 10)
        )
    }
}

#Preview {
    NavigationStack {
        StoreView()
    }
    .environmentObject(GameViewModel.preview())
}
