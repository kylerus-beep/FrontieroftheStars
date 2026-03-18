import Foundation
import SwiftData
import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var snapshot = GameSnapshot.freshStart()
    @Published private(set) var pendingOfflineSummary: OfflineEarningsSummary?
    @Published private(set) var lastClaimedDailyReward: RewardBundle?
    @Published var showingDailyRewardSheet = false
    @Published var showingOfflineSheet = false
    @Published var showingOnboarding = false
    @Published var showingSettings = false
    @Published var toastMessage: String?
    @Published private(set) var isReady = false

    let purchaseManager = PurchaseManager()
    private let adManager: AdManager
    private let persistenceService = PersistenceService()

    private var modelContext: ModelContext?
    private var record: PersistedGameState?
    private var timer: Timer?
    private var lastTickDate: Date?
    private var autosaveCounter = 0

    init(adManager: AdManager = MockAdManager()) {
        self.adManager = adManager
    }

    static func preview(snapshot: GameSnapshot = .sampleFrontier()) -> GameViewModel {
        let viewModel = GameViewModel()
        viewModel.snapshot = snapshot
        viewModel.isReady = true
        viewModel.showingOnboarding = false
        return viewModel
    }

    static func previewOffline(summary: OfflineEarningsSummary) -> GameViewModel {
        let viewModel = preview()
        viewModel.pendingOfflineSummary = summary
        viewModel.showingOfflineSheet = true
        return viewModel
    }

    deinit {
        timer?.invalidate()
    }

    func attach(context: ModelContext) {
        guard modelContext == nil else { return }
        modelContext = context

        do {
            let (record, snapshot) = try persistenceService.loadSnapshot(context: context)
            self.record = record
            self.snapshot = snapshot
            self.isReady = true
            self.showingOnboarding = !snapshot.onboardingCompleted
            handleAppBecameActive()
            startTimer()
            Task {
                await purchaseManager.loadProducts()
                await syncEntitlementsFromStore()
            }
        } catch {
            toastMessage = "Failed to load save data."
        }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            handleAppBecameActive()
        case .inactive, .background:
            snapshot.lastActiveAt = .now
            persist()
        @unknown default:
            break
        }
    }

    func completeOnboarding() {
        snapshot.onboardingCompleted = true
        showingOnboarding = false
        persist()
    }

    func manualCollect(_ resourceID: ResourceID) {
        GameEngine.manualCollect(resourceID: resourceID, snapshot: &snapshot)
        persistIfNeeded()
    }

    func buyGenerator(_ generatorID: GeneratorID) {
        if GameEngine.buyGenerator(generatorID: generatorID, snapshot: &snapshot) {
            toastMessage = "\(GameContent.generatorDefinition(for: generatorID).name) hired."
            persistIfNeeded()
        }
    }

    func buyUpgrade(_ upgradeID: UpgradeID) {
        if GameEngine.buyUpgrade(upgradeID: upgradeID, snapshot: &snapshot) {
            toastMessage = "\(GameContent.upgradeDefinition(for: upgradeID).name) purchased."
            persistIfNeeded()
        }
    }

    func buyMetaUpgrade(_ metaID: MetaUpgradeID) {
        if GameEngine.buyMetaUpgrade(metaID: metaID, snapshot: &snapshot) {
            toastMessage = "\(GameContent.metaUpgradeDefinition(for: metaID).name) unlocked."
            persist()
        }
    }

    func performPrestige() {
        let badges = GameEngine.potentialPrestigeBadges(snapshot: snapshot)
        guard badges > 0 else { return }
        GameEngine.performPrestige(snapshot: &snapshot, now: .now)
        toastMessage = "Frontier expanded. +\(badges) badges."
        persist()
    }

    func claimDailyReward() {
        guard let reward = GameEngine.claimDailyReward(snapshot: &snapshot, now: .now) else { return }
        lastClaimedDailyReward = reward
        showingDailyRewardSheet = false
        toastMessage = "Daily reward claimed."
        persist()
    }

    func claimOfflineRewards(multiplier: Double) {
        guard let summary = pendingOfflineSummary else { return }
        GameEngine.claimOfflineRewards(summary: summary, multiplier: multiplier, snapshot: &snapshot)
        pendingOfflineSummary = nil
        showingOfflineSheet = false
        toastMessage = multiplier > 1 ? "Offline rewards amplified." : "Offline rewards claimed."
        persist()
    }

    func useShardBoost() {
        guard GameEngine.spendStarShards(GameBalance.shardBoostCost, snapshot: &snapshot) else {
            toastMessage = "Not enough Star Shards."
            return
        }
        GameEngine.addBoost(
            BoostTemplate(kind: .premiumMomentum, title: "Premium Momentum", multiplier: GameBalance.premiumBoostMultiplier, duration: GameBalance.premiumBoostDuration),
            snapshot: &snapshot,
            now: .now
        )
        toastMessage = "Premium boost activated."
        persist()
    }

    func useShardCrate() {
        guard GameEngine.spendStarShards(GameBalance.shardCrateCost, snapshot: &snapshot) else {
            toastMessage = "Not enough Star Shards."
            return
        }
        let reward = RewardBundle(resources: crateRewardResources(seconds: GameBalance.resourceCrateSeconds), frontierBadges: 0, starShards: 0, boost: nil)
        GameEngine.applyRewardBundle(reward, snapshot: &snapshot, now: .now)
        toastMessage = "Supply crate opened."
        persist()
    }

    func restorePurchases() async {
        _ = await purchaseManager.restorePurchases()
        await syncEntitlementsFromStore()
        toastMessage = "Purchases restored."
        persist()
    }

    func purchase(_ productDefinition: StoreProductDefinition) async {
        let result = await purchaseManager.purchase(productDefinition.id)
        switch result {
        case let .success(id):
            applyPurchasedProduct(id)
            toastMessage = "\(productDefinition.name) unlocked."
            persist()
        case .pending:
            toastMessage = "Purchase pending approval."
        case .cancelled:
            break
        case let .failed(message):
            toastMessage = message
        }
    }

    func triggerRewardedAd(_ placement: RewardedAdPlacement) async -> Bool {
        let removeAdsEntitlement = snapshot.entitlements.removeAds
        guard adManager.canPresentAd(for: placement, removeAdsEntitlement: removeAdsEntitlement) else {
            let remaining = adManager.cooldownRemaining(for: placement, now: .now)
            toastMessage = "Ad cooling down for \(Int(remaining / 60))m."
            return false
        }

        let success = await adManager.presentRewardedAd(for: placement, removeAdsEntitlement: removeAdsEntitlement)
        guard success else { return false }

        snapshot.playerStats.totalAdRewardsClaimed += 1
        switch placement {
        case .productionBoost:
            GameEngine.addBoost(
                BoostTemplate(kind: .productionRush, title: "Prospector's Rush", multiplier: GameBalance.rewardedProductionMultiplier, duration: GameBalance.rewardedProductionBoostDuration),
                snapshot: &snapshot,
                now: .now
            )
            toastMessage = "Production rush started."
        case .offlineMultiplier:
            claimOfflineRewards(multiplier: 3)
            return true
        case .resourceCrate:
            let reward = RewardBundle(resources: crateRewardResources(seconds: GameBalance.resourceCrateSeconds))
            GameEngine.applyRewardBundle(reward, snapshot: &snapshot, now: .now)
            toastMessage = "Rewarded crate delivered."
        case .frontierPush:
            let reward = RewardBundle(resources: crateRewardResources(seconds: GameBalance.frontierPushSeconds))
            GameEngine.applyRewardBundle(reward, snapshot: &snapshot, now: .now)
            toastMessage = "Emergency shipment arrived."
        }
        persist()
        return true
    }

    func resetSaveData() {
        guard let context = modelContext else { return }
        do {
            snapshot = try persistenceService.reset(context: context)
            let result = try persistenceService.loadSnapshot(context: context)
            record = result.0
            pendingOfflineSummary = nil
            showingOfflineSheet = false
            showingDailyRewardSheet = false
            showingOnboarding = true
            toastMessage = "Save data reset."
            lastTickDate = .now
        } catch {
            toastMessage = "Failed to reset save."
        }
    }

    func clearToast() {
        toastMessage = nil
    }

    func availableUpgrades() -> [UpgradeDefinition] {
        GameContent.upgrades.filter { !snapshot.hasUpgrade($0.id) && GameEngine.isUpgradeVisible(snapshot: snapshot, definition: $0) }
    }

    func purchasedUpgrades() -> [UpgradeDefinition] {
        GameContent.upgrades.filter { snapshot.hasUpgrade($0.id) }
    }

    func achievementDefinitions() -> [AchievementDefinition] {
        GameContent.achievements
    }

    func metaUpgradeDefinitions() -> [MetaUpgradeDefinition] {
        GameContent.metaUpgrades
    }

    func storeProducts(in group: StoreProductGroup) -> [StoreProductDefinition] {
        GameContent.storeProducts.filter { $0.group == group }
    }

    func rewardedOfferDefinitions() -> [RewardedOfferDefinition] {
        GameContent.rewardedOffers.filter { offer in
            switch offer.placement {
            case .productionBoost:
                return snapshot.generators.reduce(0) { $0 + $1.owned } >= 6 && !hasActiveOutputBoost()
            case .resourceCrate:
                return true
            case .frontierPush:
                return snapshot.resources.contains(where: { GameContent.resourceDefinition(for: $0.id).tier.rawValue >= 2 && $0.unlocked })
            case .offlineMultiplier:
                return false
            }
        }
    }

    func productionRate(for resourceID: ResourceID) -> Double {
        GameEngine.productionRates(for: snapshot)[resourceID] ?? 0
    }

    func resourceState(for resourceID: ResourceID) -> ResourceState {
        snapshot.resources.first(where: { $0.id == resourceID }) ?? ResourceState(id: resourceID, amount: 0, unlocked: false, lifetimeEarned: 0)
    }

    func generatorState(for generatorID: GeneratorID) -> GeneratorState {
        snapshot.generators.first(where: { $0.id == generatorID }) ?? GeneratorState(id: generatorID, owned: 0, unlocked: false)
    }

    func currentGeneratorCost(_ generatorID: GeneratorID) -> Double {
        GameEngine.generatorCost(snapshot: snapshot, generatorID: generatorID)
    }

    func canAffordGenerator(_ generatorID: GeneratorID) -> Bool {
        GameEngine.canAffordGenerator(snapshot: snapshot, generatorID: generatorID)
    }

    func canPurchaseUpgrade(_ upgradeID: UpgradeID) -> Bool {
        GameEngine.canPurchaseUpgrade(snapshot: snapshot, upgradeID: upgradeID)
    }

    func canPurchaseMetaUpgrade(_ metaID: MetaUpgradeID) -> Bool {
        GameEngine.canPurchaseMetaUpgrade(snapshot: snapshot, metaID: metaID)
    }

    func achievementProgress(for definition: AchievementDefinition) -> Double {
        GameEngine.achievementProgress(snapshot: snapshot, definition: definition)
    }

    func prestigePreview() -> PrestigePreview {
        GameEngine.prestigePreview(snapshot: snapshot)
    }

    func progressionTargets() -> [ProgressTarget] {
        GameEngine.progressionTargets(snapshot: snapshot)
    }

    func currentSector() -> SectorDefinition {
        GameEngine.currentSector(snapshot: snapshot)
    }

    func unlockedSectors() -> [SectorDefinition] {
        GameEngine.unlockedSectors(snapshot: snapshot)
    }

    func permanentMultiplier() -> Double {
        GameEngine.currentPermanentMultiplierDisplay(snapshot: snapshot)
    }

    func canClaimDailyReward() -> Bool {
        GameEngine.canClaimDailyReward(snapshot: snapshot, now: .now)
    }

    func currentDailyReward() -> RewardBundle {
        GameEngine.dailyRewardPreview(snapshot: snapshot)
    }

    func adCooldownRemaining(for placement: RewardedAdPlacement) -> TimeInterval {
        adManager.cooldownRemaining(for: placement, now: .now)
    }

    func setSoundEnabled(_ enabled: Bool) {
        snapshot.soundEnabled = enabled
        persist()
    }

    func isProductOwned(_ productID: StoreProductID) -> Bool {
        switch productID {
        case .removeAds:
            return snapshot.entitlements.removeAds
        case .starterPack:
            return snapshot.entitlements.starterPackClaimed
        case .frontierBooster:
            return snapshot.entitlements.frontierBooster
        case .extraOfflineTime:
            return snapshot.entitlements.extraOfflineHours > 0
        case .extraDailyReward:
            return snapshot.entitlements.extraDailyRewardSlot
        case .chromeThemePack:
            return snapshot.entitlements.chromeThemePack
        case .shardsSmall, .shardsMedium, .shardsLarge:
            return false
        }
    }

    func purchaseButtonTitle(for product: StoreProductDefinition) -> String {
        if product.kind == .nonConsumable && isProductOwned(product.id) {
            return "Owned"
        }
        return product.kind == .consumable ? "Purchase" : "Unlock"
    }

    func canPurchase(_ product: StoreProductDefinition) -> Bool {
        product.kind == .consumable || !isProductOwned(product.id)
    }

    func rewardedButtonTitle(for placement: RewardedAdPlacement) -> String {
        if placement == .offlineMultiplier && pendingOfflineSummary == nil {
            return "Need Offline Rewards"
        }
        return snapshot.entitlements.removeAds ? "Claim Instantly" : "Watch Rewarded Ad"
    }

    func canTriggerRewardedOffer(_ placement: RewardedAdPlacement) -> Bool {
        if placement == .offlineMultiplier && pendingOfflineSummary == nil {
            return false
        }
        return adManager.canPresentAd(for: placement, removeAdsEntitlement: snapshot.entitlements.removeAds)
    }

    func rewardedStatusText(for placement: RewardedAdPlacement) -> String? {
        if placement == .offlineMultiplier && pendingOfflineSummary == nil {
            return "Return from an idle session to use this multiplier."
        }
        if placement == .productionBoost && hasActiveOutputBoost() {
            return "You already have an active output boost running."
        }
        let remaining = adCooldownRemaining(for: placement)
        guard remaining > 0, !snapshot.entitlements.removeAds else { return nil }
        return "Available in \(FrontierFormatters.abbreviatedDuration(remaining))."
    }

    func rewardedContextText(for placement: RewardedAdPlacement) -> String? {
        switch placement {
        case .productionBoost:
            if let upgrade = availableUpgrades().first {
                return "Useful when pushing toward \(upgrade.name)."
            }
            return "Best during an active buying streak."
        case .resourceCrate:
            if let hint = projectedClaimHint(multiplier: 1, using: RewardBundle(resources: crateRewardResources(seconds: GameBalance.resourceCrateSeconds))) {
                return hint
            }
            return "A small nudge toward your next unlock."
        case .frontierPush:
            if let hint = projectedClaimHint(multiplier: 1, using: RewardBundle(resources: crateRewardResources(seconds: GameBalance.frontierPushSeconds))) {
                return hint
            }
            return "Most useful when a prestige or upgrade is close."
        case .offlineMultiplier:
            return offlineMultiplierPitch()
        }
    }

    func offlineClaimInsight(multiplier: Double) -> String? {
        guard let summary = pendingOfflineSummary else { return nil }
        return projectedClaimHint(multiplier: multiplier, using: summary.rewards)
    }

    func offlineMultiplierPitch() -> String? {
        guard pendingOfflineSummary != nil else { return nil }
        return projectedClaimHint(multiplier: 3, using: pendingOfflineSummary!.rewards)
    }

    private func startTimer() {
        timer?.invalidate()
        lastTickDate = .now
        timer = Timer.scheduledTimer(withTimeInterval: GameBalance.tickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.handleTick()
            }
        }
    }

    private func handleTick() {
        guard isReady else { return }
        let now = Date()
        let delta = lastTickDate.map { now.timeIntervalSince($0) } ?? GameBalance.tickInterval
        GameEngine.tick(snapshot: &snapshot, deltaTime: min(max(delta, 0), 5), now: now)
        lastTickDate = now
        autosaveCounter += 1

        if canClaimDailyReward() && snapshot.onboardingCompleted {
            showingDailyRewardSheet = true
        }

        persistIfNeeded()
    }

    private func handleAppBecameActive() {
        guard isReady else { return }
        let now = Date()
        pendingOfflineSummary = GameEngine.pendingOfflineRewards(snapshot: snapshot, now: now)
        showingOfflineSheet = pendingOfflineSummary != nil
        showingDailyRewardSheet = pendingOfflineSummary == nil && GameEngine.canClaimDailyReward(snapshot: snapshot, now: now) && snapshot.onboardingCompleted
        snapshot.lastActiveAt = now
        lastTickDate = now
        persist()
    }

    private func persistIfNeeded() {
        if autosaveCounter >= GameBalance.autosaveEveryTicks {
            persist()
            autosaveCounter = 0
        }
    }

    private func persist() {
        guard let context = modelContext, let record else { return }
        do {
            try persistenceService.save(snapshot: snapshot, into: record, context: context)
        } catch {
            toastMessage = "Autosave failed."
        }
    }

    private func syncEntitlementsFromStore() async {
        let ownedIDs = purchaseManager.purchasedProductIDs.compactMap(StoreProductID.init(rawValue:))
        for id in ownedIDs {
            applyPurchasedProduct(id)
        }
        persist()
    }

    private func applyPurchasedProduct(_ id: StoreProductID) {
        switch id {
        case .removeAds:
            snapshot.entitlements.removeAds = true
        case .starterPack:
            guard !snapshot.entitlements.starterPackClaimed else { return }
            snapshot.entitlements.starterPackClaimed = true
            snapshot.premiumWallet.starShards += GameBalance.starterPackShards
            snapshot.prestigeState.frontierBadges += GameBalance.starterPackBadges
            snapshot.prestigeState.totalBadgesEarned += GameBalance.starterPackBadges
            GameEngine.applyRewardBundle(
                RewardBundle(
                    resources: [.ore: 280, .alienDust: 120, .energy: 80],
                    boost: BoostTemplate(kind: .premiumMomentum, title: "Starter Booster", multiplier: 1.75, duration: 15 * 60)
                ),
                snapshot: &snapshot,
                now: .now
            )
        case .frontierBooster:
            snapshot.entitlements.frontierBooster = true
        case .shardsSmall:
            snapshot.premiumWallet.starShards += 180
        case .shardsMedium:
            snapshot.premiumWallet.starShards += 500
        case .shardsLarge:
            snapshot.premiumWallet.starShards += 1_200
        case .extraOfflineTime:
            snapshot.entitlements.extraOfflineHours = max(snapshot.entitlements.extraOfflineHours, 4)
        case .extraDailyReward:
            snapshot.entitlements.extraDailyRewardSlot = true
        case .chromeThemePack:
            snapshot.entitlements.chromeThemePack = true
        }
    }

    private func crateRewardResources(seconds: Double) -> [ResourceID: Double] {
        let rates = GameEngine.productionRates(for: snapshot)
        var rewards = rates.mapValues { $0 * seconds }
        let unlockedTier = snapshot.resources.filter(\.unlocked).map { GameContent.resourceDefinition(for: $0.id).tier.rawValue }.max() ?? 1

        if unlockedTier >= 3 {
            rewards[.alienTech, default: 0] += 1
        } else if unlockedTier == 2 {
            rewards[.refinedMetal, default: 0] += 5
        } else {
            rewards[.ore, default: 0] += 80
            rewards[.alienDust, default: 0] += 30
        }

        return rewards.filter { $0.value > 0 }
    }

    private func projectedClaimHint(multiplier: Double, using reward: RewardBundle) -> String? {
        var simulated = snapshot
        GameEngine.applyRewardBundle(reward.scaled(by: multiplier), snapshot: &simulated, now: .now)

        let currentBadges = GameEngine.potentialPrestigeBadges(snapshot: snapshot)
        let newBadges = GameEngine.potentialPrestigeBadges(snapshot: simulated)
        if newBadges > currentBadges {
            return multiplier > 1 ? "The boosted claim raises your next expansion to +\(newBadges) badges." : "This claim improves your next expansion to +\(newBadges) badges."
        }

        if let upgrade = GameContent.upgrades.first(where: {
            !snapshot.hasUpgrade($0.id) &&
            GameEngine.isUpgradeUnlocked(snapshot: simulated, definition: $0) &&
            simulated.resourceAmount($0.costResource) >= $0.costAmount
        }) {
            return multiplier > 1 ? "The boosted claim buys \(upgrade.name) immediately." : "This claim buys \(upgrade.name)."
        }

        if let generator = GameContent.generators.first(where: {
            !GameEngine.canAffordGenerator(snapshot: snapshot, generatorID: $0.id) &&
            GameEngine.canAffordGenerator(snapshot: simulated, generatorID: $0.id)
        }) {
            return multiplier > 1 ? "The boosted claim lets you hire \(generator.name)." : "This claim lets you hire \(generator.name)."
        }

        if let lockedGenerator = GameContent.generators.first(where: { definition in
            guard !generatorState(for: definition.id).unlocked else { return false }
            guard let unlockResource = definition.unlockResource else { return false }
            return max(simulated.resourceAmount(unlockResource), simulated.lifetimeEarned(unlockResource)) >= definition.unlockAmount
        }) {
            return multiplier > 1 ? "The boosted claim unlocks \(lockedGenerator.name)." : "This claim unlocks \(lockedGenerator.name)."
        }

        return nil
    }

    private func hasActiveOutputBoost() -> Bool {
        snapshot.activeBoosts.contains { boost in
            boost.expiresAt > .now && [.productionRush, .premiumMomentum, .dailyBlessing].contains(boost.kind)
        }
    }
}
