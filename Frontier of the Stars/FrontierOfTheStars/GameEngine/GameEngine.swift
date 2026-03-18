import Foundation

struct OfflineEarningsSummary: Identifiable {
    let id = UUID()
    let timeAway: TimeInterval
    let cappedTime: TimeInterval
    let rewards: RewardBundle
}

struct PrestigePreview {
    let badgesToEarn: Int
    let nextPermanentMultiplier: Double
}

struct ProgressTarget: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

enum GameEngine {
    static func tick(snapshot: inout GameSnapshot, deltaTime: TimeInterval, now: Date) {
        guard deltaTime > 0 else {
            snapshot.lastActiveAt = now
            return
        }

        removeExpiredBoosts(snapshot: &snapshot, now: now)
        refreshUnlocks(snapshot: &snapshot)

        let rates = productionRates(for: snapshot, now: now)
        for resource in ResourceID.allCases {
            let amount = (rates[resource] ?? 0) * deltaTime
            guard amount > 0 else { continue }
            grantResource(resource, amount: amount, snapshot: &snapshot)
        }

        snapshot.playerStats.totalPlaySeconds += deltaTime
        refreshUnlocks(snapshot: &snapshot)
        evaluateAchievements(snapshot: &snapshot, now: now)
        snapshot.lastActiveAt = now
    }

    static func productionRates(for snapshot: GameSnapshot, now: Date = .now) -> [ResourceID: Double] {
        var rates: [ResourceID: Double] = Dictionary(uniqueKeysWithValues: ResourceID.allCases.map { ($0, 0) })
        let globalMultiplier = GameEconomyMath.globalProductionMultiplier(snapshot: snapshot, now: now)

        for definition in GameContent.generators {
            let owned = snapshot.generatorOwned(definition.id)
            guard owned > 0 else { continue }
            let generatorMultiplier = GameEconomyMath.generatorProductionMultiplier(snapshot: snapshot, generatorID: definition.id)
            let resourceMultiplier = GameEconomyMath.resourceProductionMultiplier(snapshot: snapshot, resourceID: definition.resource)
            let tierMultiplier = GameEconomyMath.tierProductionMultiplier(snapshot: snapshot, tier: GameContent.resourceDefinition(for: definition.resource).tier)
            let perSecond = definition.baseProductionPerSecond * Double(owned) * generatorMultiplier * resourceMultiplier * tierMultiplier * globalMultiplier
            rates[definition.resource, default: 0] += perSecond
        }

        return rates
    }

    static func generatorCost(snapshot: GameSnapshot, generatorID: GeneratorID) -> Double {
        let definition = GameContent.generatorDefinition(for: generatorID)
        let owned = snapshot.generatorOwned(generatorID)
        let baseCost = definition.baseCost * pow(GameBalance.generatorCostScale, Double(owned))
        let multiplier = GameEconomyMath.generatorCostMultiplier(snapshot: snapshot, generatorID: generatorID)
        return max(1, baseCost * multiplier)
    }

    static func canAffordGenerator(snapshot: GameSnapshot, generatorID: GeneratorID) -> Bool {
        let definition = GameContent.generatorDefinition(for: generatorID)
        return snapshot.resourceAmount(definition.costResource) >= generatorCost(snapshot: snapshot, generatorID: generatorID)
    }

    @discardableResult
    static func buyGenerator(generatorID: GeneratorID, snapshot: inout GameSnapshot) -> Bool {
        let definition = GameContent.generatorDefinition(for: generatorID)
        guard isGeneratorUnlocked(snapshot: snapshot, definition: definition) else { return false }

        let cost = generatorCost(snapshot: snapshot, generatorID: generatorID)
        guard spendResource(definition.costResource, amount: cost, snapshot: &snapshot) else { return false }

        snapshot.updateGenerator(generatorID) {
            $0.owned += 1
            $0.unlocked = true
        }
        snapshot.playerStats.totalGeneratorPurchases += 1
        refreshUnlocks(snapshot: &snapshot)
        evaluateAchievements(snapshot: &snapshot, now: .now)
        return true
    }

    static func canPurchaseUpgrade(snapshot: GameSnapshot, upgradeID: UpgradeID) -> Bool {
        let definition = GameContent.upgradeDefinition(for: upgradeID)
        guard !snapshot.hasUpgrade(upgradeID), isUpgradeUnlocked(snapshot: snapshot, definition: definition) else { return false }
        return snapshot.resourceAmount(definition.costResource) >= definition.costAmount
    }

    @discardableResult
    static func buyUpgrade(upgradeID: UpgradeID, snapshot: inout GameSnapshot) -> Bool {
        let definition = GameContent.upgradeDefinition(for: upgradeID)
        guard canPurchaseUpgrade(snapshot: snapshot, upgradeID: upgradeID) else { return false }
        guard spendResource(definition.costResource, amount: definition.costAmount, snapshot: &snapshot) else { return false }
        snapshot.updateUpgrade(upgradeID) { $0.purchased = true }
        snapshot.playerStats.totalUpgradePurchases += 1
        refreshUnlocks(snapshot: &snapshot)
        evaluateAchievements(snapshot: &snapshot, now: .now)
        return true
    }

    static func canPurchaseMetaUpgrade(snapshot: GameSnapshot, metaID: MetaUpgradeID) -> Bool {
        let definition = GameContent.metaUpgradeDefinition(for: metaID)
        return !snapshot.hasMetaUpgrade(metaID) && snapshot.prestigeState.frontierBadges >= definition.costBadges
    }

    @discardableResult
    static func buyMetaUpgrade(metaID: MetaUpgradeID, snapshot: inout GameSnapshot) -> Bool {
        let definition = GameContent.metaUpgradeDefinition(for: metaID)
        guard canPurchaseMetaUpgrade(snapshot: snapshot, metaID: metaID) else { return false }
        snapshot.prestigeState.frontierBadges -= definition.costBadges
        snapshot.updateMetaUpgrade(metaID) { $0.purchased = true }
        refreshUnlocks(snapshot: &snapshot)
        evaluateAchievements(snapshot: &snapshot, now: .now)
        return true
    }

    static func manualCollect(resourceID: ResourceID, snapshot: inout GameSnapshot) {
        let definition = GameContent.resourceDefinition(for: resourceID)
        guard definition.manualYield > 0 else { return }
        guard snapshot.resources.first(where: { $0.id == resourceID })?.unlocked == true else { return }
        let multiplier = GameEconomyMath.manualCollectMultiplier(snapshot: snapshot)
        grantResource(resourceID, amount: definition.manualYield * multiplier, snapshot: &snapshot)
        snapshot.playerStats.totalManualCollects += 1
        refreshUnlocks(snapshot: &snapshot)
        evaluateAchievements(snapshot: &snapshot, now: .now)
    }

    static func pendingOfflineRewards(snapshot: GameSnapshot, now: Date) -> OfflineEarningsSummary? {
        let rawAway = now.timeIntervalSince(snapshot.lastActiveAt)
        guard rawAway > 30 else { return nil }

        let cap = offlineCap(snapshot: snapshot)
        let cappedTime = min(rawAway, cap)
        let rates = productionRates(for: snapshot, now: now)
        var rewards: [ResourceID: Double] = [:]
        for (resource, rate) in rates where rate > 0 {
            rewards[resource] = rate * cappedTime
        }

        guard rewards.values.contains(where: { $0 > 0 }) else { return nil }
        return OfflineEarningsSummary(timeAway: rawAway, cappedTime: cappedTime, rewards: RewardBundle(resources: rewards))
    }

    static func claimOfflineRewards(summary: OfflineEarningsSummary, multiplier: Double, snapshot: inout GameSnapshot) {
        let reward = summary.rewards.scaled(by: multiplier)
        applyRewardBundle(reward, snapshot: &snapshot, now: .now)
        snapshot.playerStats.totalOfflineSecondsClaimed += summary.cappedTime
        snapshot.playerStats.lastLongestOfflineSeconds = max(snapshot.playerStats.lastLongestOfflineSeconds, summary.cappedTime)
        snapshot.lastActiveAt = .now
        evaluateAchievements(snapshot: &snapshot, now: .now)
    }

    static func canClaimDailyReward(snapshot: GameSnapshot, now: Date) -> Bool {
        guard let lastClaim = snapshot.dailyRewardState.lastClaimDate else { return true }
        return !Calendar.current.isDate(lastClaim, inSameDayAs: now)
    }

    static func dailyRewardPreview(snapshot: GameSnapshot) -> RewardBundle {
        let rewardIndex = min(snapshot.dailyRewardState.streak, GameContent.dailyRewards.count - 1)
        var reward = GameContent.dailyRewards[rewardIndex]
        if snapshot.entitlements.extraDailyRewardSlot || snapshot.hasMetaUpgrade(.frontierCouncil) {
            reward = reward.scaled(by: 1.25)
        }
        return reward
    }

    @discardableResult
    static func claimDailyReward(snapshot: inout GameSnapshot, now: Date) -> RewardBundle? {
        guard canClaimDailyReward(snapshot: snapshot, now: now) else { return nil }

        if let lastClaim = snapshot.dailyRewardState.lastClaimDate {
            let dayGap = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lastClaim), to: Calendar.current.startOfDay(for: now)).day ?? 0
            snapshot.dailyRewardState.streak = dayGap > 1 ? 0 : snapshot.dailyRewardState.streak
        }

        let reward = dailyRewardPreview(snapshot: snapshot)

        snapshot.dailyRewardState.lastClaimDate = now
        snapshot.dailyRewardState.streak = min(snapshot.dailyRewardState.streak + 1, GameContent.dailyRewards.count)
        applyRewardBundle(reward, snapshot: &snapshot, now: now)
        evaluateAchievements(snapshot: &snapshot, now: now)
        return reward
    }

    static func prestigePreview(snapshot: GameSnapshot) -> PrestigePreview {
        let badges = potentialPrestigeBadges(snapshot: snapshot)
        let futureBadges = snapshot.prestigeState.frontierBadges + badges
        var futureSnapshot = snapshot
        futureSnapshot.prestigeState.frontierBadges = futureBadges
        let nextMultiplier = GameEconomyMath.permanentMultiplier(snapshot: futureSnapshot)
        return PrestigePreview(badgesToEarn: badges, nextPermanentMultiplier: nextMultiplier)
    }

    static func potentialPrestigeBadges(snapshot: GameSnapshot) -> Int {
        let progress = GameEconomyMath.prestigeProgressScore(snapshot: snapshot)
        let excess = max(0, progress - GameBalance.prestigeUnlockScore)
        let rawBadges = pow(excess, GameBalance.prestigeScoreExponent) / GameBalance.prestigeScoreDivisor
        guard rawBadges >= 1 else { return 0 }

        let base = Int(rawBadges.rounded(.down))
        let multiplier = GameEconomyMath.prestigeRewardMultiplier(snapshot: snapshot)
        return max(0, Int((Double(base) * multiplier).rounded(.down)))
    }

    static func canPrestige(snapshot: GameSnapshot) -> Bool {
        potentialPrestigeBadges(snapshot: snapshot) > 0
    }

    static func performPrestige(snapshot: inout GameSnapshot, now: Date) {
        let earnedBadges = potentialPrestigeBadges(snapshot: snapshot)
        guard earnedBadges > 0 else { return }

        let preserveAchievementBonus = snapshot.prestigeState.achievementProductionBonus
        let preserveMetaUpgrades = snapshot.metaUpgrades
        let preserveAchievements = snapshot.achievements
        let preserveWallet = snapshot.premiumWallet
        let preserveEntitlements = snapshot.entitlements
        let preserveStats = snapshot.playerStats
        let preserveDailyReward = snapshot.dailyRewardState
        let preserveOnboarding = snapshot.onboardingCompleted
        let preserveSoundEnabled = snapshot.soundEnabled
        let previousPrestiges = snapshot.prestigeState.totalPrestiges
        let previousBadges = snapshot.prestigeState.frontierBadges
        let previousTotalBadges = snapshot.prestigeState.totalBadgesEarned

        snapshot = .freshStart(now: now)
        snapshot.metaUpgrades = preserveMetaUpgrades
        snapshot.achievements = preserveAchievements
        snapshot.premiumWallet = preserveWallet
        snapshot.entitlements = preserveEntitlements
        snapshot.playerStats = preserveStats
        snapshot.dailyRewardState = preserveDailyReward
        snapshot.onboardingCompleted = preserveOnboarding
        snapshot.soundEnabled = preserveSoundEnabled
        snapshot.prestigeState.frontierBadges = previousBadges + earnedBadges
        snapshot.prestigeState.totalBadgesEarned = previousTotalBadges + earnedBadges
        snapshot.prestigeState.totalPrestiges = previousPrestiges + 1
        snapshot.prestigeState.achievementProductionBonus = preserveAchievementBonus
        refreshUnlocks(snapshot: &snapshot)
        evaluateAchievements(snapshot: &snapshot, now: now)
    }

    static func applyRewardBundle(_ reward: RewardBundle, snapshot: inout GameSnapshot, now: Date) {
        for (resource, amount) in reward.resources where amount > 0 {
            grantResource(resource, amount: amount, snapshot: &snapshot)
        }

        if reward.frontierBadges > 0 {
            snapshot.prestigeState.frontierBadges += reward.frontierBadges
            snapshot.prestigeState.totalBadgesEarned += reward.frontierBadges
        }

        if reward.starShards > 0 {
            snapshot.premiumWallet.starShards += reward.starShards
        }

        if let boost = reward.boost {
            addBoost(boost, snapshot: &snapshot, now: now)
        }

        refreshUnlocks(snapshot: &snapshot)
    }

    static func addBoost(_ template: BoostTemplate, snapshot: inout GameSnapshot, now: Date) {
        let boost = ActiveBoost(id: UUID(), kind: template.kind, title: template.title, multiplier: template.multiplier, expiresAt: now.addingTimeInterval(template.duration))
        snapshot.activeBoosts.removeAll { $0.kind == template.kind }
        snapshot.activeBoosts.append(boost)
    }

    static func spendStarShards(_ amount: Int, snapshot: inout GameSnapshot) -> Bool {
        guard snapshot.premiumWallet.starShards >= amount else { return false }
        snapshot.premiumWallet.starShards -= amount
        snapshot.premiumWallet.totalSpent += amount
        return true
    }

    static func currentSector(snapshot: GameSnapshot) -> SectorDefinition {
        let unlocked = unlockedSectors(snapshot: snapshot)
        return unlocked.last ?? GameContent.sectors[0]
    }

    static func unlockedSectors(snapshot: GameSnapshot) -> [SectorDefinition] {
        GameContent.sectors.filter { snapshot.prestigeState.totalBadgesEarned >= $0.requiredBadges }
    }

    static func currentPermanentMultiplierDisplay(snapshot: GameSnapshot) -> Double {
        GameEconomyMath.permanentMultiplier(snapshot: snapshot)
    }

    static func progressionTargets(snapshot: GameSnapshot) -> [ProgressTarget] {
        var targets: [ProgressTarget] = []

        if let nearUpgrade = GameContent.upgrades
            .filter({ !snapshot.hasUpgrade($0.id) && isUpgradeVisible(snapshot: snapshot, definition: $0) })
            .sorted(by: { affordabilityRatio(snapshot: snapshot, upgrade: $0) > affordabilityRatio(snapshot: snapshot, upgrade: $1) })
            .first {
            let progress = Int(affordabilityRatio(snapshot: snapshot, upgrade: nearUpgrade) * 100)
            targets.append(ProgressTarget(title: "Closest Upgrade", detail: "\(nearUpgrade.name) is \(progress)% funded. Save \(LargeNumberFormatter.format(nearUpgrade.costAmount)) \(GameContent.resourceDefinition(for: nearUpgrade.costResource).name)."))
        }

        if let nextGenerator = GameContent.generators.first(where: { !isGeneratorUnlocked(snapshot: snapshot, definition: $0) }) {
            let requirementName = nextGenerator.unlockResource.map { GameContent.resourceDefinition(for: $0).name } ?? "Frontier"
            targets.append(ProgressTarget(title: "Next Generator", detail: "Reach \(LargeNumberFormatter.format(nextGenerator.unlockAmount)) \(requirementName) to unlock \(nextGenerator.name)."))
        }

        if let nextSector = GameContent.sectors.first(where: { $0.requiredBadges > snapshot.prestigeState.totalBadgesEarned }) {
            let remaining = nextSector.requiredBadges - snapshot.prestigeState.totalBadgesEarned
            targets.append(ProgressTarget(title: "Next Sector", detail: "Earn \(remaining) more Frontier Badges to reach \(nextSector.name)."))
        }

        if let nextAchievement = GameContent.achievements
            .filter({ !snapshot.achievementState($0.id).isCompleted })
            .sorted(by: { achievementProgress(snapshot: snapshot, definition: $0) > achievementProgress(snapshot: snapshot, definition: $1) })
            .first {
            let progress = Int(achievementProgress(snapshot: snapshot, definition: nextAchievement) * 100)
            targets.append(ProgressTarget(title: "Next Achievement", detail: "\(nextAchievement.title) is \(progress)% complete. \(nextAchievement.description)"))
        }

        let preview = prestigePreview(snapshot: snapshot)
        if preview.badgesToEarn > 0 {
            targets.append(ProgressTarget(title: "Ready to Expand", detail: "Reset now for \(preview.badgesToEarn) Frontier Badges and a stronger next run."))
        } else {
            let shortfall = LargeNumberFormatter.format(GameEconomyMath.nextBadgeScoreShortfall(snapshot: snapshot), precision: 1)
            targets.append(ProgressTarget(title: "First Prestige", detail: "You are roughly \(shortfall) score away from your next badge. Tier 2 unlocks and upgrades are the fastest route."))
        }

        return Array(targets.prefix(4))
    }

    static func achievementProgress(snapshot: GameSnapshot, definition: AchievementDefinition) -> Double {
        if snapshot.achievementState(definition.id).isCompleted {
            return 1
        }

        switch definition.condition {
        case let .lifetimeResource(resourceID, target):
            return min(snapshot.lifetimeEarned(resourceID) / target, 1)
        case let .currentResource(resourceID, target):
            return min(snapshot.resourceAmount(resourceID) / target, 1)
        case let .totalLifetime(target):
            return min(GameEconomyMath.totalLifetimeResources(snapshot: snapshot) / target, 1)
        case let .generatorOwned(generatorID, target):
            return min(Double(snapshot.generatorOwned(generatorID)) / Double(target), 1)
        case let .unlockResource(resourceID):
            return snapshot.resources.first(where: { $0.id == resourceID })?.unlocked == true ? 1 : 0
        case let .prestigeCount(target):
            return min(Double(snapshot.prestigeState.totalPrestiges) / Double(target), 1)
        case let .offlineClaimHours(target):
            return min(snapshot.playerStats.lastLongestOfflineSeconds / 3600 / target, 1)
        case let .permanentMultiplier(target):
            return min(GameEconomyMath.permanentMultiplier(snapshot: snapshot) / target, 1)
        }
    }

    static func isAchievementComplete(snapshot: GameSnapshot, definition: AchievementDefinition) -> Bool {
        achievementProgress(snapshot: snapshot, definition: definition) >= 1
    }

    static func offlineCap(snapshot: GameSnapshot) -> TimeInterval {
        let additiveHours = Double(snapshot.entitlements.extraOfflineHours) * 60 * 60
        return GameBalance.baseOfflineCap * GameEconomyMath.offlineCapMultiplier(snapshot: snapshot) + additiveHours
    }

    private static func evaluateAchievements(snapshot: inout GameSnapshot, now: Date) {
        for achievement in GameContent.achievements {
            guard isAchievementComplete(snapshot: snapshot, definition: achievement) else { continue }
            guard !snapshot.achievementState(achievement.id).rewardClaimed else { continue }
            snapshot.updateAchievement(achievement.id) {
                $0.isCompleted = true
                $0.rewardClaimed = true
                $0.completedAt = now
            }
            snapshot.premiumWallet.starShards += achievement.reward.starShards
            snapshot.prestigeState.frontierBadges += achievement.reward.frontierBadges
            snapshot.prestigeState.totalBadgesEarned += achievement.reward.frontierBadges

            let bonusMultiplier = snapshot.hasMetaUpgrade(.relicVault) ? 1.25 : 1.0
            snapshot.prestigeState.achievementProductionBonus += achievement.reward.permanentProductionBonus * bonusMultiplier
        }

        snapshot.prestigeState.unlockedSectorCount = unlockedSectors(snapshot: snapshot).count
    }

    private static func refreshUnlocks(snapshot: inout GameSnapshot) {
        for definition in GameContent.generators {
            let unlocked = isGeneratorUnlocked(snapshot: snapshot, definition: definition)
            if unlocked {
                snapshot.updateGenerator(definition.id) { $0.unlocked = true }
                snapshot.updateResource(definition.resource) { $0.unlocked = true }
            }
        }

        for resource in GameContent.resources {
            let isUnlocked = resource.baseUnlocked ||
                snapshot.resourceAmount(resource.id) > 0 ||
                snapshot.lifetimeEarned(resource.id) > 0 ||
                snapshot.generators.contains(where: {
                    let definition = GameContent.generatorDefinition(for: $0.id)
                    return definition.resource == resource.id && ($0.unlocked || $0.owned > 0)
                })
            snapshot.updateResource(resource.id) { $0.unlocked = isUnlocked }
        }
    }

    private static func isGeneratorUnlocked(snapshot: GameSnapshot, definition: GeneratorDefinition) -> Bool {
        if definition.startsUnlocked { return true }
        guard let unlockResource = definition.unlockResource else { return false }
        let available = max(snapshot.resourceAmount(unlockResource), snapshot.lifetimeEarned(unlockResource))
        return available >= definition.unlockAmount
    }

    static func isUpgradeUnlocked(snapshot: GameSnapshot, definition: UpgradeDefinition) -> Bool {
        guard isUpgradeVisible(snapshot: snapshot, definition: definition) else { return false }
        if let unlockResource = definition.unlockResource {
            guard max(snapshot.resourceAmount(unlockResource), snapshot.lifetimeEarned(unlockResource)) >= definition.unlockAmount else { return false }
        }
        if let unlockGenerator = definition.unlockGenerator {
            guard snapshot.generatorOwned(unlockGenerator) >= definition.unlockOwned else { return false }
        }
        return true
    }

    static func isUpgradeVisible(snapshot: GameSnapshot, definition: UpgradeDefinition) -> Bool {
        if let unlockResource = definition.unlockResource {
            return snapshot.resources.first(where: { $0.id == unlockResource })?.unlocked == true || snapshot.lifetimeEarned(unlockResource) > 0
        }
        return true
    }

    private static func spendResource(_ id: ResourceID, amount: Double, snapshot: inout GameSnapshot) -> Bool {
        guard snapshot.resourceAmount(id) >= amount else { return false }
        snapshot.updateResource(id) { $0.amount -= amount }
        return true
    }

    private static func grantResource(_ id: ResourceID, amount: Double, snapshot: inout GameSnapshot) {
        guard amount > 0 else { return }
        snapshot.updateResource(id) {
            $0.unlocked = true
            $0.amount += amount
            $0.lifetimeEarned += amount
        }
    }

    private static func removeExpiredBoosts(snapshot: inout GameSnapshot, now: Date) {
        snapshot.activeBoosts.removeAll { $0.expiresAt <= now }
    }

    private static func affordabilityRatio(snapshot: GameSnapshot, upgrade: UpgradeDefinition) -> Double {
        min(snapshot.resourceAmount(upgrade.costResource) / max(upgrade.costAmount, 1), 1)
    }
}
