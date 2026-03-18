import Foundation

enum RewardedAdPlacement: String, CaseIterable, Identifiable {
    case productionBoost
    case offlineMultiplier
    case resourceCrate
    case frontierPush

    var id: String { rawValue }
}

enum StoreProductKind: String, CaseIterable, Identifiable {
    case nonConsumable
    case consumable

    var id: String { rawValue }
}

enum StoreProductGroup: String, CaseIterable, Identifiable {
    case featured
    case permanent
    case starShards

    var id: String { rawValue }
}

enum StoreProductID: String, CaseIterable, Identifiable {
    case removeAds = "com.frontierofthestars.removeads"
    case starterPack = "com.frontierofthestars.starterpack"
    case frontierBooster = "com.frontierofthestars.frontierbooster"
    case shardsSmall = "com.frontierofthestars.shards.small"
    case shardsMedium = "com.frontierofthestars.shards.medium"
    case shardsLarge = "com.frontierofthestars.shards.large"
    case extraOfflineTime = "com.frontierofthestars.extraoffline"
    case extraDailyReward = "com.frontierofthestars.extradaily"
    case chromeThemePack = "com.frontierofthestars.theme.chrome"

    var id: String { rawValue }
}

struct StoreProductDefinition: Identifiable {
    let id: StoreProductID
    let name: String
    let subtitle: String
    let kind: StoreProductKind
    let group: StoreProductGroup
    let badge: String?
    let highlights: [String]
    let fallbackPrice: String
}

struct RewardedOfferDefinition: Identifiable {
    let placement: RewardedAdPlacement
    let title: String
    let subtitle: String
    let badge: String
    let rewardDescription: String

    var id: RewardedAdPlacement { placement }
}

struct RewardBundle {
    var resources: [ResourceID: Double] = [:]
    var frontierBadges: Int = 0
    var starShards: Int = 0
    var boost: BoostTemplate?

    func scaled(by multiplier: Double) -> RewardBundle {
        RewardBundle(
            resources: resources.mapValues { $0 * multiplier },
            frontierBadges: Int((Double(frontierBadges) * multiplier).rounded(.down)),
            starShards: Int((Double(starShards) * multiplier).rounded(.down)),
            boost: boost
        )
    }
}

struct BoostTemplate {
    let kind: BoostKind
    let title: String
    let multiplier: Double
    let duration: TimeInterval
}

enum PurchaseOutcome {
    case success(StoreProductID)
    case pending
    case cancelled
    case failed(String)
}
