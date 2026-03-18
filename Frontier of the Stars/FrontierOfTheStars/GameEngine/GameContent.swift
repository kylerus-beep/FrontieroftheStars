import Foundation

struct ResourceDefinition: Identifiable {
    let id: ResourceID
    let name: String
    let subtitle: String
    let tier: ResourceTier
    let icon: String
    let manualYield: Double
    let baseUnlocked: Bool
}

struct GeneratorDefinition: Identifiable {
    let id: GeneratorID
    let name: String
    let resource: ResourceID
    let costResource: ResourceID
    let baseCost: Double
    let baseProductionPerSecond: Double
    let startsUnlocked: Bool
    let unlockResource: ResourceID?
    let unlockAmount: Double
    let flavor: String
}

enum UpgradeEffect {
    case generatorProduction(GeneratorID, Double)
    case resourceProduction(ResourceID, Double)
    case generatorCost(GeneratorID, Double)
    case offlineCap(Double)
    case tierProduction(ResourceTier, Double)
    case prestigeRewards(Double)
    case globalProduction(Double)
}

struct UpgradeDefinition: Identifiable {
    let id: UpgradeID
    let name: String
    let description: String
    let costResource: ResourceID
    let costAmount: Double
    let effect: UpgradeEffect
    let unlockResource: ResourceID?
    let unlockAmount: Double
    let unlockGenerator: GeneratorID?
    let unlockOwned: Int
}

enum AchievementCondition {
    case lifetimeResource(ResourceID, Double)
    case currentResource(ResourceID, Double)
    case totalLifetime(Double)
    case generatorOwned(GeneratorID, Int)
    case unlockResource(ResourceID)
    case prestigeCount(Int)
    case offlineClaimHours(Double)
    case permanentMultiplier(Double)
}

struct AchievementReward {
    var frontierBadges: Int = 0
    var starShards: Int = 0
    var permanentProductionBonus: Double = 0
}

struct AchievementDefinition: Identifiable {
    let id: AchievementID
    let title: String
    let description: String
    let condition: AchievementCondition
    let reward: AchievementReward
}

struct MetaUpgradeDefinition: Identifiable {
    let id: MetaUpgradeID
    let name: String
    let description: String
    let costBadges: Int
}

struct SectorDefinition: Identifiable {
    let id: SectorID
    let name: String
    let description: String
    let requiredBadges: Int
    let bonusLabel: String
}

enum GameContent {
    static let resources: [ResourceDefinition] = [
        ResourceDefinition(id: .ore, name: "Ore", subtitle: "Scrap-rich bedrock", tier: .tier1, icon: "shippingbox.fill", manualYield: 4, baseUnlocked: true),
        ResourceDefinition(id: .alienDust, name: "Alien Dust", subtitle: "Shimmering storm residue", tier: .tier1, icon: "aqi.medium", manualYield: 2, baseUnlocked: false),
        ResourceDefinition(id: .energy, name: "Energy", subtitle: "Captured frontier current", tier: .tier1, icon: "bolt.fill", manualYield: 1, baseUnlocked: false),
        ResourceDefinition(id: .refinedMetal, name: "Refined Metal", subtitle: "Forged alloy bars", tier: .tier2, icon: "cube.transparent.fill", manualYield: 0, baseUnlocked: false),
        ResourceDefinition(id: .plasmaCells, name: "Plasma Cells", subtitle: "Condensed charge cores", tier: .tier2, icon: "battery.100percent.bolt", manualYield: 0, baseUnlocked: false),
        ResourceDefinition(id: .exoticCrystals, name: "Exotic Crystals", subtitle: "Resonant alien lattice", tier: .tier2, icon: "sparkles.rectangle.stack", manualYield: 0, baseUnlocked: false),
        ResourceDefinition(id: .terraformUnits, name: "Terraform Units", subtitle: "World-shaping packages", tier: .tier3, icon: "globe.americas.fill", manualYield: 0, baseUnlocked: false),
        ResourceDefinition(id: .alienTech, name: "Alien Tech", subtitle: "Recovered ruin schematics", tier: .tier3, icon: "memorychip.fill", manualYield: 0, baseUnlocked: false),
        ResourceDefinition(id: .starCores, name: "Star Cores", subtitle: "Empire-grade singularity fuel", tier: .tier3, icon: "star.fill", manualYield: 0, baseUnlocked: false)
    ]

    static let generators: [GeneratorDefinition] = [
        GeneratorDefinition(id: .oreDrill, name: "Ore Drill", resource: .ore, costResource: .ore, baseCost: 10, baseProductionPerSecond: 0.72, startsUnlocked: true, unlockResource: nil, unlockAmount: 0, flavor: "Dusty rotary drill rigs on rented claims."),
        GeneratorDefinition(id: .dustHarvester, name: "Dust Harvester", resource: .alienDust, costResource: .ore, baseCost: 40, baseProductionPerSecond: 0.30, startsUnlocked: false, unlockResource: .ore, unlockAmount: 28, flavor: "Canvas-bellied skimmers sweep the dunes for reactive grit."),
        GeneratorDefinition(id: .fusionPump, name: "Fusion Pump", resource: .energy, costResource: .ore, baseCost: 105, baseProductionPerSecond: 0.18, startsUnlocked: false, unlockResource: .alienDust, unlockAmount: 14, flavor: "Retro-futurist rigs tap thermal seams below the town."),
        GeneratorDefinition(id: .refinery, name: "Refinery", resource: .refinedMetal, costResource: .energy, baseCost: 72, baseProductionPerSecond: 0.082, startsUnlocked: false, unlockResource: .energy, unlockAmount: 18, flavor: "Rail-fed smelters turn frontier scrap into durable metal."),
        GeneratorDefinition(id: .plasmaCondenser, name: "Plasma Condenser", resource: .plasmaCells, costResource: .refinedMetal, baseCost: 36, baseProductionPerSecond: 0.036, startsUnlocked: false, unlockResource: .refinedMetal, unlockAmount: 10, flavor: "Charged vats distill storms into portable cells."),
        GeneratorDefinition(id: .crystalExtractor, name: "Crystal Extractor", resource: .exoticCrystals, costResource: .plasmaCells, baseCost: 24, baseProductionPerSecond: 0.018, startsUnlocked: false, unlockResource: .plasmaCells, unlockAmount: 8, flavor: "Tuned sonic rigs tease rare growths from canyon walls."),
        GeneratorDefinition(id: .terraformPress, name: "Terraform Press", resource: .terraformUnits, costResource: .exoticCrystals, baseCost: 14, baseProductionPerSecond: 0.008, startsUnlocked: false, unlockResource: .exoticCrystals, unlockAmount: 6, flavor: "Massive presses stamp out habitable futures from frontier dust."),
        GeneratorDefinition(id: .ruinDecoder, name: "Ruin Decoder", resource: .alienTech, costResource: .terraformUnits, baseCost: 9, baseProductionPerSecond: 0.0048, startsUnlocked: false, unlockResource: .terraformUnits, unlockAmount: 4, flavor: "Clockwork analyzers translate impossible schematics from buried shrines."),
        GeneratorDefinition(id: .starForge, name: "Star Forge", resource: .starCores, costResource: .alienTech, baseCost: 5, baseProductionPerSecond: 0.0022, startsUnlocked: false, unlockResource: .alienTech, unlockAmount: 3, flavor: "The frontier's finest machine hammers starlight into tradeable cores.")
    ]

    static let upgrades: [UpgradeDefinition] = [
        UpgradeDefinition(id: .oreRigCalibration, name: "Ore Rig Calibration", description: "Ore Drills produce 2x.", costResource: .ore, costAmount: 90, effect: .generatorProduction(.oreDrill, 2.0), unlockResource: .ore, unlockAmount: 65, unlockGenerator: .oreDrill, unlockOwned: 5),
        UpgradeDefinition(id: .dustSeparatorNozzles, name: "Dust Separator Nozzles", description: "Alien Dust production +50%.", costResource: .alienDust, costAmount: 72, effect: .resourceProduction(.alienDust, 1.5), unlockResource: .alienDust, unlockAmount: 45, unlockGenerator: .dustHarvester, unlockOwned: 4),
        UpgradeDefinition(id: .fusionCoupons, name: "Fusion Coupons", description: "Fusion Pumps cost 10% less.", costResource: .energy, costAmount: 92, effect: .generatorCost(.fusionPump, 0.9), unlockResource: .energy, unlockAmount: 44, unlockGenerator: .fusionPump, unlockOwned: 4),
        UpgradeDefinition(id: .campLogistics, name: "Camp Logistics", description: "Offline earnings cap +25%.", costResource: .refinedMetal, costAmount: 36, effect: .offlineCap(1.25), unlockResource: .refinedMetal, unlockAmount: 12, unlockGenerator: .refinery, unlockOwned: 3),
        UpgradeDefinition(id: .claimJumpersGuild, name: "Claim Jumper's Guild", description: "All Tier 1 resources +20%.", costResource: .plasmaCells, costAmount: 38, effect: .tierProduction(.tier1, 1.2), unlockResource: .plasmaCells, unlockAmount: 12, unlockGenerator: .plasmaCondenser, unlockOwned: 3),
        UpgradeDefinition(id: .badgeMinting, name: "Badge Minting", description: "Prestige rewards +10%.", costResource: .exoticCrystals, costAmount: 18, effect: .prestigeRewards(1.1), unlockResource: .exoticCrystals, unlockAmount: 8, unlockGenerator: .crystalExtractor, unlockOwned: 3),
        UpgradeDefinition(id: .refineryAutomation, name: "Refinery Automation", description: "Refineries produce 2x.", costResource: .refinedMetal, costAmount: 180, effect: .generatorProduction(.refinery, 2.0), unlockResource: .refinedMetal, unlockAmount: 70, unlockGenerator: .refinery, unlockOwned: 7),
        UpgradeDefinition(id: .crystalResonance, name: "Crystal Resonance", description: "Exotic Crystals +75%.", costResource: .exoticCrystals, costAmount: 54, effect: .resourceProduction(.exoticCrystals, 1.75), unlockResource: .exoticCrystals, unlockAmount: 24, unlockGenerator: .crystalExtractor, unlockOwned: 5),
        UpgradeDefinition(id: .frontierLedger, name: "Frontier Ledger", description: "All production +15%.", costResource: .plasmaCells, costAmount: 90, effect: .globalProduction(1.15), unlockResource: .plasmaCells, unlockAmount: 32, unlockGenerator: .plasmaCondenser, unlockOwned: 5),
        UpgradeDefinition(id: .ruinScanners, name: "Ruin Scanners", description: "Ruin Decoders produce 2x.", costResource: .alienTech, costAmount: 12, effect: .generatorProduction(.ruinDecoder, 2.0), unlockResource: .alienTech, unlockAmount: 5, unlockGenerator: .ruinDecoder, unlockOwned: 3),
        UpgradeDefinition(id: .starCoreCompression, name: "Star Core Compression", description: "Star Forges produce 2x.", costResource: .starCores, costAmount: 6, effect: .generatorProduction(.starForge, 2.0), unlockResource: .starCores, unlockAmount: 2, unlockGenerator: .starForge, unlockOwned: 2),
        UpgradeDefinition(id: .silverTonguedBroker, name: "Silver-Tongued Broker", description: "All Tier 2 resources +20%.", costResource: .alienTech, costAmount: 22, effect: .tierProduction(.tier2, 1.2), unlockResource: .alienTech, unlockAmount: 9, unlockGenerator: .ruinDecoder, unlockOwned: 4)
    ]

    static let achievements: [AchievementDefinition] = [
        AchievementDefinition(id: .firstClaim, title: "Stake Your First Claim", description: "Produce 100 Ore total.", condition: .lifetimeResource(.ore, 100), reward: AchievementReward(frontierBadges: 0, starShards: 15, permanentProductionBonus: 0.00)),
        AchievementDefinition(id: .firstRig, title: "First Rig on the Ridge", description: "Own your first Ore Drill.", condition: .generatorOwned(.oreDrill, 1), reward: AchievementReward(frontierBadges: 0, starShards: 10, permanentProductionBonus: 0.01)),
        AchievementDefinition(id: .tenDrills, title: "Ten Drills Down", description: "Own 10 Ore Drills.", condition: .generatorOwned(.oreDrill, 10), reward: AchievementReward(frontierBadges: 1, starShards: 0, permanentProductionBonus: 0.01)),
        AchievementDefinition(id: .oreTown, title: "Ore Town Rising", description: "Own 25 Ore Drills.", condition: .generatorOwned(.oreDrill, 25), reward: AchievementReward(frontierBadges: 2, starShards: 0, permanentProductionBonus: 0.02)),
        AchievementDefinition(id: .dustUnlocked, title: "Dust on the Horizon", description: "Unlock Alien Dust.", condition: .unlockResource(.alienDust), reward: AchievementReward(frontierBadges: 1, starShards: 0, permanentProductionBonus: 0.00)),
        AchievementDefinition(id: .powerRails, title: "Power the Rails", description: "Unlock Energy.", condition: .unlockResource(.energy), reward: AchievementReward(frontierBadges: 0, starShards: 20, permanentProductionBonus: 0.01)),
        AchievementDefinition(id: .industrialHeart, title: "Industrial Heart", description: "Unlock Refined Metal.", condition: .unlockResource(.refinedMetal), reward: AchievementReward(frontierBadges: 2, starShards: 0, permanentProductionBonus: 0.02)),
        AchievementDefinition(id: .claimJumper, title: "Claim Jumper", description: "Reach 50,000 total lifetime resources.", condition: .totalLifetime(50_000), reward: AchievementReward(frontierBadges: 2, starShards: 0, permanentProductionBonus: 0.02)),
        AchievementDefinition(id: .firstExpansion, title: "Frontier Expansion", description: "Complete your first prestige.", condition: .prestigeCount(1), reward: AchievementReward(frontierBadges: 2, starShards: 25, permanentProductionBonus: 0.03)),
        AchievementDefinition(id: .seasonedMarshal, title: "Seasoned Marshal", description: "Complete 3 Frontier Expansions.", condition: .prestigeCount(3), reward: AchievementReward(frontierBadges: 3, starShards: 0, permanentProductionBonus: 0.03)),
        AchievementDefinition(id: .longRideHome, title: "Long Ride Home", description: "Claim at least 6 hours of offline rewards.", condition: .offlineClaimHours(6), reward: AchievementReward(frontierBadges: 1, starShards: 30, permanentProductionBonus: 0.00)),
        AchievementDefinition(id: .frontierLegend, title: "Frontier Legend", description: "Reach a 4x permanent multiplier.", condition: .permanentMultiplier(4), reward: AchievementReward(frontierBadges: 4, starShards: 0, permanentProductionBonus: 0.03)),
        AchievementDefinition(id: .millionMined, title: "Million-Mile Ledger", description: "Reach 1,000,000 total lifetime resources.", condition: .totalLifetime(1_000_000), reward: AchievementReward(frontierBadges: 4, starShards: 40, permanentProductionBonus: 0.04)),
        AchievementDefinition(id: .coreEmpire, title: "Core of the Empire", description: "Produce 15 Star Cores total.", condition: .lifetimeResource(.starCores, 15), reward: AchievementReward(frontierBadges: 5, starShards: 60, permanentProductionBonus: 0.03))
    ]

    static let metaUpgrades: [MetaUpgradeDefinition] = [
        MetaUpgradeDefinition(id: .longHaulCaravans, name: "Long-Haul Caravans", description: "Offline cap x1.5.", costBadges: 8),
        MetaUpgradeDefinition(id: .guildCharters, name: "Guild Charters", description: "Permanent production +15%.", costBadges: 14),
        MetaUpgradeDefinition(id: .sectorMaps, name: "Sector Maps", description: "Sector bonuses are 50% stronger.", costBadges: 24),
        MetaUpgradeDefinition(id: .relicVault, name: "Relic Vault", description: "Achievement bonuses count 25% more.", costBadges: 36),
        MetaUpgradeDefinition(id: .frontierCouncil, name: "Frontier Council", description: "Daily rewards +25% and +5% prestige rewards.", costBadges: 48)
    ]

    static let sectors: [SectorDefinition] = [
        SectorDefinition(id: .redMesa, name: "Red Mesa", description: "A lone camp and shallow claims.", requiredBadges: 0, bonusLabel: "+0% sector bonus"),
        SectorDefinition(id: .glassDunes, name: "Glass Dunes", description: "Reflective dunes with richer dust seams.", requiredBadges: 12, bonusLabel: "+8% all production"),
        SectorDefinition(id: .emberBelt, name: "Ember Belt", description: "A hot ring of energy wells and plasma storms.", requiredBadges: 35, bonusLabel: "+16% all production"),
        SectorDefinition(id: .haloReach, name: "Halo Reach", description: "Old alien stations hover over prosperous towns.", requiredBadges: 90, bonusLabel: "+24% all production"),
        SectorDefinition(id: .crownFrontier, name: "Crown Frontier", description: "The frontier becomes a self-feeding empire.", requiredBadges: 220, bonusLabel: "+32% all production")
    ]

    static let storeProducts: [StoreProductDefinition] = [
        StoreProductDefinition(id: .starterPack, name: "Starter Pack", subtitle: "A measured head start tuned for the first expansion.", kind: .nonConsumable, group: .featured, badge: "Best Start", highlights: ["350 Star Shards", "4 Frontier Badges", "Modest 15m boost"], fallbackPrice: "$3.99"),
        StoreProductDefinition(id: .frontierBooster, name: "Frontier Booster", subtitle: "Permanent 1.35x global production across every run.", kind: .nonConsumable, group: .featured, badge: "Permanent", highlights: ["Stacks with prestige", "Applies to offline gains", "Strong but not game-breaking"], fallbackPrice: "$6.99"),
        StoreProductDefinition(id: .removeAds, name: "Remove Ads", subtitle: "Skip rewarded gating and claim optional boosts instantly.", kind: .nonConsumable, group: .permanent, badge: nil, highlights: ["Instant rewarded claims", "Future-proof convenience"], fallbackPrice: "$4.99"),
        StoreProductDefinition(id: .extraOfflineTime, name: "Extra Offline Time", subtitle: "+4 hours to your offline earnings cap.", kind: .nonConsumable, group: .permanent, badge: nil, highlights: ["Longer idle windows", "Pairs with offline upgrades"], fallbackPrice: "$2.99"),
        StoreProductDefinition(id: .extraDailyReward, name: "Extra Daily Reward Slot", subtitle: "Daily rewards become 25% richer.", kind: .nonConsumable, group: .permanent, badge: nil, highlights: ["Better streak value", "Useful for light play"], fallbackPrice: "$2.99"),
        StoreProductDefinition(id: .chromeThemePack, name: "Chrome Theme Pack", subtitle: "Unlock a polished alternate visual treatment.", kind: .nonConsumable, group: .permanent, badge: "Cosmetic", highlights: ["Cosmetic only", "No gameplay power"], fallbackPrice: "$1.99"),
        StoreProductDefinition(id: .shardsSmall, name: "Star Shards Cache", subtitle: "180 Star Shards.", kind: .consumable, group: .starShards, badge: nil, highlights: ["Quick convenience spend"], fallbackPrice: "$1.99"),
        StoreProductDefinition(id: .shardsMedium, name: "Star Shards Caravan", subtitle: "500 Star Shards.", kind: .consumable, group: .starShards, badge: "Popular", highlights: ["Best general refill"], fallbackPrice: "$4.99"),
        StoreProductDefinition(id: .shardsLarge, name: "Star Shards Vault", subtitle: "1,200 Star Shards.", kind: .consumable, group: .starShards, badge: "Value", highlights: ["Heavy long-session stock"], fallbackPrice: "$9.99")
    ]

    static let rewardedOffers: [RewardedOfferDefinition] = [
        RewardedOfferDefinition(placement: .productionBoost, title: "Production Rush", subtitle: "Best used when you're settling into an active play stretch.", badge: "Session", rewardDescription: "1.8x output for 12 minutes"),
        RewardedOfferDefinition(placement: .resourceCrate, title: "Supply Crate", subtitle: "A clean early-to-mid game nudge when a new unlock is close.", badge: "Breakthrough", rewardDescription: "Instant scaled resource bundle"),
        RewardedOfferDefinition(placement: .frontierPush, title: "Emergency Shipment", subtitle: "A controlled push for late-run walls and prestige setup.", badge: "Catch-Up", rewardDescription: "Immediate 3.5 minutes of production")
    ]

    static let dailyRewards: [RewardBundle] = [
        RewardBundle(resources: [.ore: 120, .alienDust: 30], frontierBadges: 0, starShards: 12, boost: nil),
        RewardBundle(resources: [.ore: 180, .alienDust: 70, .energy: 20], frontierBadges: 0, starShards: 15, boost: nil),
        RewardBundle(resources: [.energy: 75, .refinedMetal: 8], frontierBadges: 1, starShards: 18, boost: nil),
        RewardBundle(resources: [.refinedMetal: 16, .plasmaCells: 4], frontierBadges: 1, starShards: 22, boost: BoostTemplate(kind: .dailyBlessing, title: "Daily Blessing", multiplier: 1.35, duration: 10 * 60)),
        RewardBundle(resources: [.plasmaCells: 8, .exoticCrystals: 2], frontierBadges: 1, starShards: 26, boost: nil),
        RewardBundle(resources: [.exoticCrystals: 5], frontierBadges: 2, starShards: 30, boost: nil),
        RewardBundle(resources: [.refinedMetal: 30, .plasmaCells: 10, .exoticCrystals: 6], frontierBadges: 3, starShards: 40, boost: BoostTemplate(kind: .dailyBlessing, title: "Marshal's Favor", multiplier: 1.75, duration: 18 * 60))
    ]

    static func resourceDefinition(for id: ResourceID) -> ResourceDefinition {
        resources.first(where: { $0.id == id })!
    }

    static func generatorDefinition(for id: GeneratorID) -> GeneratorDefinition {
        generators.first(where: { $0.id == id })!
    }

    static func upgradeDefinition(for id: UpgradeID) -> UpgradeDefinition {
        upgrades.first(where: { $0.id == id })!
    }

    static func achievementDefinition(for id: AchievementID) -> AchievementDefinition {
        achievements.first(where: { $0.id == id })!
    }

    static func metaUpgradeDefinition(for id: MetaUpgradeID) -> MetaUpgradeDefinition {
        metaUpgrades.first(where: { $0.id == id })!
    }
}
