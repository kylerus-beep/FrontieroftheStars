import Foundation

extension GameSnapshot {
    static func sampleFrontier(now: Date = .now) -> GameSnapshot {
        var snapshot = GameSnapshot.freshStart(now: now)
        snapshot.onboardingCompleted = true
        snapshot.dailyRewardState = DailyRewardState(lastClaimDate: Calendar.current.date(byAdding: .day, value: -1, to: now), streak: 3)
        snapshot.prestigeState = PrestigeState(frontierBadges: 14, totalBadgesEarned: 22, totalPrestiges: 2, unlockedSectorCount: 2, achievementProductionBonus: 0.12)
        snapshot.premiumWallet = PremiumCurrencyWallet(starShards: 360, totalSpent: 120)
        snapshot.entitlements = PremiumEntitlements(removeAds: false, starterPackClaimed: true, frontierBooster: false, extraOfflineHours: 0, extraDailyRewardSlot: false, chromeThemePack: false)
        snapshot.activeBoosts = [
            ActiveBoost(id: UUID(), kind: .productionRush, title: "Prospector's Rush", multiplier: 2.0, expiresAt: now.addingTimeInterval(8 * 60))
        ]

        let resourceValues: [ResourceID: (Double, Bool, Double)] = [
            .ore: (12_400, true, 54_000),
            .alienDust: (4_280, true, 16_500),
            .energy: (1_820, true, 9_800),
            .refinedMetal: (210, true, 1_300),
            .plasmaCells: (62, true, 280),
            .exoticCrystals: (18, true, 70),
            .terraformUnits: (0, false, 0),
            .alienTech: (0, false, 0),
            .starCores: (0, false, 0)
        ]

        for (resourceID, tuple) in resourceValues {
            snapshot.updateResource(resourceID) {
                $0.amount = tuple.0
                $0.unlocked = tuple.1
                $0.lifetimeEarned = tuple.2
            }
        }

        let generatorValues: [GeneratorID: Int] = [
            .oreDrill: 18,
            .dustHarvester: 12,
            .fusionPump: 8,
            .refinery: 5,
            .plasmaCondenser: 3,
            .crystalExtractor: 1
        ]

        for (generatorID, owned) in generatorValues {
            snapshot.updateGenerator(generatorID) {
                $0.owned = owned
                $0.unlocked = true
            }
        }

        let unlockedUpgrades: [UpgradeID] = [
            .oreRigCalibration,
            .dustSeparatorNozzles,
            .fusionCoupons,
            .campLogistics,
            .claimJumpersGuild,
            .frontierLedger,
            .refineryAutomation
        ]

        for upgrade in unlockedUpgrades {
            snapshot.updateUpgrade(upgrade) { $0.purchased = true }
        }

        let completedAchievements: [AchievementID] = [
            .firstClaim,
            .firstRig,
            .tenDrills,
            .dustUnlocked,
            .powerRails,
            .industrialHeart,
            .claimJumper,
            .firstExpansion
        ]

        for achievement in completedAchievements {
            snapshot.updateAchievement(achievement) {
                $0.isCompleted = true
                $0.rewardClaimed = true
                $0.completedAt = now
            }
        }

        snapshot.updateMetaUpgrade(.longHaulCaravans) { $0.purchased = true }
        snapshot.updateMetaUpgrade(.guildCharters) { $0.purchased = true }

        snapshot.playerStats = PlayerStats(
            totalManualCollects: 120,
            totalGeneratorPurchases: 54,
            totalUpgradePurchases: 7,
            totalOfflineSecondsClaimed: 18_000,
            totalAdRewardsClaimed: 4,
            totalPlaySeconds: 12_000,
            lastLongestOfflineSeconds: 12_000
        )

        return snapshot
    }
}
