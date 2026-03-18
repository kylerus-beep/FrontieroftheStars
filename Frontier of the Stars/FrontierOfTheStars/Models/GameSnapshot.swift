import Foundation
import SwiftData

@Model
final class PersistedGameState {
    @Attribute(.unique) var id: UUID
    var schemaVersion: Int
    var updatedAt: Date
    var snapshotData: Data

    init(id: UUID = UUID(), schemaVersion: Int = 1, updatedAt: Date = .now, snapshotData: Data) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.updatedAt = updatedAt
        self.snapshotData = snapshotData
    }
}

struct ResourceState: Codable, Identifiable {
    let id: ResourceID
    var amount: Double
    var unlocked: Bool
    var lifetimeEarned: Double
}

struct GeneratorState: Codable, Identifiable {
    let id: GeneratorID
    var owned: Int
    var unlocked: Bool
}

struct UpgradePurchaseState: Codable, Identifiable {
    let id: UpgradeID
    var purchased: Bool
}

struct MetaUpgradePurchaseState: Codable, Identifiable {
    let id: MetaUpgradeID
    var purchased: Bool
}

struct AchievementProgressState: Codable, Identifiable {
    let id: AchievementID
    var isCompleted: Bool
    var rewardClaimed: Bool
    var completedAt: Date?
}

struct DailyRewardState: Codable {
    var lastClaimDate: Date?
    var streak: Int
}

struct PrestigeState: Codable {
    var frontierBadges: Int
    var totalBadgesEarned: Int
    var totalPrestiges: Int
    var unlockedSectorCount: Int
    var achievementProductionBonus: Double
}

struct PremiumCurrencyWallet: Codable {
    var starShards: Int
    var totalSpent: Int
}

struct PremiumEntitlements: Codable {
    var removeAds: Bool
    var starterPackClaimed: Bool
    var frontierBooster: Bool
    var extraOfflineHours: Int
    var extraDailyRewardSlot: Bool
    var chromeThemePack: Bool
}

struct ActiveBoost: Codable, Identifiable {
    var id: UUID
    var kind: BoostKind
    var title: String
    var multiplier: Double
    var expiresAt: Date
}

struct PlayerStats: Codable {
    var totalManualCollects: Int
    var totalGeneratorPurchases: Int
    var totalUpgradePurchases: Int
    var totalOfflineSecondsClaimed: TimeInterval
    var totalAdRewardsClaimed: Int
    var totalPlaySeconds: TimeInterval
    var lastLongestOfflineSeconds: TimeInterval
}

struct GameSnapshot: Codable {
    var schemaVersion: Int
    var createdAt: Date
    var lastActiveAt: Date
    var onboardingCompleted: Bool
    var soundEnabled: Bool
    var resources: [ResourceState]
    var generators: [GeneratorState]
    var upgrades: [UpgradePurchaseState]
    var metaUpgrades: [MetaUpgradePurchaseState]
    var achievements: [AchievementProgressState]
    var dailyRewardState: DailyRewardState
    var prestigeState: PrestigeState
    var premiumWallet: PremiumCurrencyWallet
    var entitlements: PremiumEntitlements
    var activeBoosts: [ActiveBoost]
    var playerStats: PlayerStats
}

extension GameSnapshot {
    static func freshStart(now: Date = .now) -> GameSnapshot {
        GameSnapshot(
            schemaVersion: 1,
            createdAt: now,
            lastActiveAt: now,
            onboardingCompleted: false,
            soundEnabled: true,
            resources: ResourceID.allCases.map {
                ResourceState(
                    id: $0,
                    amount: 0,
                    unlocked: GameContent.resourceDefinition(for: $0).baseUnlocked,
                    lifetimeEarned: 0
                )
            },
            generators: GeneratorID.allCases.map { GeneratorState(id: $0, owned: 0, unlocked: GameContent.generatorDefinition(for: $0).startsUnlocked) },
            upgrades: UpgradeID.allCases.map { UpgradePurchaseState(id: $0, purchased: false) },
            metaUpgrades: MetaUpgradeID.allCases.map { MetaUpgradePurchaseState(id: $0, purchased: false) },
            achievements: AchievementID.allCases.map { AchievementProgressState(id: $0, isCompleted: false, rewardClaimed: false, completedAt: nil) },
            dailyRewardState: DailyRewardState(lastClaimDate: nil, streak: 0),
            prestigeState: PrestigeState(frontierBadges: 0, totalBadgesEarned: 0, totalPrestiges: 0, unlockedSectorCount: 1, achievementProductionBonus: 0),
            premiumWallet: PremiumCurrencyWallet(starShards: 80, totalSpent: 0),
            entitlements: PremiumEntitlements(removeAds: false, starterPackClaimed: false, frontierBooster: false, extraOfflineHours: 0, extraDailyRewardSlot: false, chromeThemePack: false),
            activeBoosts: [],
            playerStats: PlayerStats(totalManualCollects: 0, totalGeneratorPurchases: 0, totalUpgradePurchases: 0, totalOfflineSecondsClaimed: 0, totalAdRewardsClaimed: 0, totalPlaySeconds: 0, lastLongestOfflineSeconds: 0)
        )
    }

    func resourceAmount(_ id: ResourceID) -> Double {
        resources.first(where: { $0.id == id })?.amount ?? 0
    }

    func lifetimeEarned(_ id: ResourceID) -> Double {
        resources.first(where: { $0.id == id })?.lifetimeEarned ?? 0
    }

    func generatorOwned(_ id: GeneratorID) -> Int {
        generators.first(where: { $0.id == id })?.owned ?? 0
    }

    func hasUpgrade(_ id: UpgradeID) -> Bool {
        upgrades.first(where: { $0.id == id })?.purchased ?? false
    }

    func hasMetaUpgrade(_ id: MetaUpgradeID) -> Bool {
        metaUpgrades.first(where: { $0.id == id })?.purchased ?? false
    }

    func achievementState(_ id: AchievementID) -> AchievementProgressState {
        achievements.first(where: { $0.id == id }) ?? AchievementProgressState(id: id, isCompleted: false, rewardClaimed: false, completedAt: nil)
    }

    mutating func updateResource(_ id: ResourceID, mutate: (inout ResourceState) -> Void) {
        guard let index = resources.firstIndex(where: { $0.id == id }) else { return }
        mutate(&resources[index])
    }

    mutating func updateGenerator(_ id: GeneratorID, mutate: (inout GeneratorState) -> Void) {
        guard let index = generators.firstIndex(where: { $0.id == id }) else { return }
        mutate(&generators[index])
    }

    mutating func updateUpgrade(_ id: UpgradeID, mutate: (inout UpgradePurchaseState) -> Void) {
        guard let index = upgrades.firstIndex(where: { $0.id == id }) else { return }
        mutate(&upgrades[index])
    }

    mutating func updateMetaUpgrade(_ id: MetaUpgradeID, mutate: (inout MetaUpgradePurchaseState) -> Void) {
        guard let index = metaUpgrades.firstIndex(where: { $0.id == id }) else { return }
        mutate(&metaUpgrades[index])
    }

    mutating func updateAchievement(_ id: AchievementID, mutate: (inout AchievementProgressState) -> Void) {
        guard let index = achievements.firstIndex(where: { $0.id == id }) else { return }
        mutate(&achievements[index])
    }
}
