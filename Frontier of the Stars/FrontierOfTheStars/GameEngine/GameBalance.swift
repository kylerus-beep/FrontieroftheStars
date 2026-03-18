import Foundation

enum GameBalance {
    static let generatorCostScale: Double = 1.15
    static let tickInterval: TimeInterval = 1
    static let baseOfflineCap: TimeInterval = 8 * 60 * 60
    static let rewardedProductionBoostDuration: TimeInterval = 12 * 60
    static let rewardedProductionMultiplier: Double = 1.8
    static let premiumBoostDuration: TimeInterval = 20 * 60
    static let premiumBoostMultiplier: Double = 2.35
    static let frontierBoosterMultiplier: Double = 1.35
    static let starterPackShards: Int = 350
    static let starterPackBadges: Int = 4
    static let shardBoostCost: Int = 60
    static let shardCrateCost: Int = 90
    static let frontierPushSeconds: Double = 210
    static let resourceCrateSeconds: Double = 120
    static let autosaveEveryTicks: Int = 5

    static let baseBadgeBonusPerBadge: Double = 0.015
    static let squareRootBadgeBonus: Double = 0.15
    static let prestigeUnlockScore: Double = 6.5
    static let prestigeScoreExponent: Double = 1.15
    static let prestigeScoreDivisor: Double = 2.4

    static func adCooldown(for placement: RewardedAdPlacement) -> TimeInterval {
        switch placement {
        case .productionBoost:
            return rewardedProductionBoostDuration
        case .offlineMultiplier:
            return 0
        case .resourceCrate:
            return 8 * 60
        case .frontierPush:
            return 10 * 60
        }
    }
}
