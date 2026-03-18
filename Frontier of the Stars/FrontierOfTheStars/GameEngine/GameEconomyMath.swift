import Foundation

enum GameEconomyMath {
    static func generatorProductionMultiplier(snapshot: GameSnapshot, generatorID: GeneratorID) -> Double {
        GameContent.upgrades.reduce(1) { partial, upgrade in
            guard snapshot.hasUpgrade(upgrade.id) else { return partial }
            switch upgrade.effect {
            case let .generatorProduction(target, multiplier) where target == generatorID:
                return partial * multiplier
            default:
                return partial
            }
        }
    }

    static func resourceProductionMultiplier(snapshot: GameSnapshot, resourceID: ResourceID) -> Double {
        GameContent.upgrades.reduce(1) { partial, upgrade in
            guard snapshot.hasUpgrade(upgrade.id) else { return partial }
            switch upgrade.effect {
            case let .resourceProduction(target, multiplier) where target == resourceID:
                return partial * multiplier
            default:
                return partial
            }
        }
    }

    static func tierProductionMultiplier(snapshot: GameSnapshot, tier: ResourceTier) -> Double {
        GameContent.upgrades.reduce(1) { partial, upgrade in
            guard snapshot.hasUpgrade(upgrade.id) else { return partial }
            switch upgrade.effect {
            case let .tierProduction(targetTier, multiplier) where targetTier == tier:
                return partial * multiplier
            default:
                return partial
            }
        }
    }

    static func generatorCostMultiplier(snapshot: GameSnapshot, generatorID: GeneratorID) -> Double {
        GameContent.upgrades.reduce(1) { partial, upgrade in
            guard snapshot.hasUpgrade(upgrade.id) else { return partial }
            switch upgrade.effect {
            case let .generatorCost(target, multiplier) where target == generatorID:
                return partial * multiplier
            default:
                return partial
            }
        }
    }

    static func offlineCapMultiplier(snapshot: GameSnapshot) -> Double {
        var multiplier = 1.0
        for upgrade in GameContent.upgrades where snapshot.hasUpgrade(upgrade.id) {
            if case let .offlineCap(value) = upgrade.effect {
                multiplier *= value
            }
        }
        if snapshot.hasMetaUpgrade(.longHaulCaravans) {
            multiplier *= 1.5
        }
        return multiplier
    }

    static func prestigeRewardMultiplier(snapshot: GameSnapshot) -> Double {
        var multiplier = 1.0
        for upgrade in GameContent.upgrades where snapshot.hasUpgrade(upgrade.id) {
            if case let .prestigeRewards(value) = upgrade.effect {
                multiplier *= value
            }
        }
        if snapshot.hasMetaUpgrade(.frontierCouncil) {
            multiplier *= 1.05
        }
        return multiplier
    }

    static func globalProductionMultiplier(snapshot: GameSnapshot, now: Date) -> Double {
        var multiplier = permanentMultiplier(snapshot: snapshot)

        for upgrade in GameContent.upgrades where snapshot.hasUpgrade(upgrade.id) {
            if case let .globalProduction(value) = upgrade.effect {
                multiplier *= value
            }
        }

        if snapshot.hasMetaUpgrade(.guildCharters) {
            multiplier *= 1.15
        }

        multiplier *= sectorProductionMultiplier(snapshot: snapshot)
        multiplier *= activeBoostMultiplier(snapshot: snapshot, now: now)
        return multiplier
    }

    static func permanentMultiplier(snapshot: GameSnapshot) -> Double {
        let badges = Double(snapshot.prestigeState.frontierBadges)
        var multiplier =
            1.0 +
            (badges * GameBalance.baseBadgeBonusPerBadge) +
            (sqrt(max(badges, 0)) * GameBalance.squareRootBadgeBonus) +
            snapshot.prestigeState.achievementProductionBonus
        if snapshot.entitlements.frontierBooster {
            multiplier *= GameBalance.frontierBoosterMultiplier
        }
        return max(multiplier, 1)
    }

    static func sectorProductionMultiplier(snapshot: GameSnapshot) -> Double {
        let bonusPerSector: Double = snapshot.hasMetaUpgrade(.sectorMaps) ? 0.12 : 0.08
        let bonusSectors = max(0, GameEngine.unlockedSectors(snapshot: snapshot).count - 1)
        return 1 + Double(bonusSectors) * bonusPerSector
    }

    static func activeBoostMultiplier(snapshot: GameSnapshot, now: Date) -> Double {
        snapshot.activeBoosts
            .filter { $0.expiresAt > now }
            .reduce(1) { $0 * $1.multiplier }
    }

    static func manualCollectMultiplier(snapshot: GameSnapshot) -> Double {
        tierProductionMultiplier(snapshot: snapshot, tier: .tier1) * permanentMultiplier(snapshot: snapshot)
    }

    static func totalLifetimeResources(snapshot: GameSnapshot) -> Double {
        snapshot.resources.reduce(0) { $0 + $1.lifetimeEarned }
    }

    static func prestigeProgressScore(snapshot: GameSnapshot) -> Double {
        let weightedProgress =
            snapshot.lifetimeEarned(.ore) / 5_000 +
            snapshot.lifetimeEarned(.alienDust) / 3_500 +
            snapshot.lifetimeEarned(.energy) / 2_400 +
            snapshot.lifetimeEarned(.refinedMetal) / 300 +
            snapshot.lifetimeEarned(.plasmaCells) / 160 +
            snapshot.lifetimeEarned(.exoticCrystals) / 90 +
            snapshot.lifetimeEarned(.terraformUnits) / 18 +
            snapshot.lifetimeEarned(.alienTech) / 10 +
            snapshot.lifetimeEarned(.starCores) * 8

        let unlockedTier3Count = [ResourceID.terraformUnits, .alienTech, .starCores].filter { resourceID in
            snapshot.resources.first(where: { $0.id == resourceID })?.unlocked ?? false
        }.count
        let upgradeScore = Double(snapshot.upgrades.filter(\.purchased).count) * 0.85
        let generatorScore = Double(snapshot.generators.reduce(0) { $0 + $1.owned }) * 0.05
        return weightedProgress + upgradeScore + generatorScore + Double(unlockedTier3Count) * 2.5
    }

    static func scoreNeeded(forBadgeCount badgeCount: Int) -> Double {
        guard badgeCount > 0 else { return GameBalance.prestigeUnlockScore }
        let excess = pow(Double(badgeCount) * GameBalance.prestigeScoreDivisor, 1 / GameBalance.prestigeScoreExponent)
        return GameBalance.prestigeUnlockScore + excess
    }

    static func nextBadgeScoreShortfall(snapshot: GameSnapshot) -> Double {
        let currentScore = prestigeProgressScore(snapshot: snapshot)
        let nextBadgeTarget = GameEngine.potentialPrestigeBadges(snapshot: snapshot) + 1
        return max(0, scoreNeeded(forBadgeCount: nextBadgeTarget) - currentScore)
    }
}
