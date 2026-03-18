import Foundation

enum ResourceID: String, CaseIterable, Codable, Identifiable {
    case ore
    case alienDust
    case energy
    case refinedMetal
    case plasmaCells
    case exoticCrystals
    case terraformUnits
    case alienTech
    case starCores

    var id: String { rawValue }
}

enum ResourceTier: Int, Codable, CaseIterable {
    case tier1 = 1
    case tier2 = 2
    case tier3 = 3
}

enum GeneratorID: String, CaseIterable, Codable, Identifiable {
    case oreDrill
    case dustHarvester
    case fusionPump
    case refinery
    case plasmaCondenser
    case crystalExtractor
    case terraformPress
    case ruinDecoder
    case starForge

    var id: String { rawValue }
}

enum UpgradeID: String, CaseIterable, Codable, Identifiable {
    case oreRigCalibration
    case dustSeparatorNozzles
    case fusionCoupons
    case campLogistics
    case claimJumpersGuild
    case badgeMinting
    case refineryAutomation
    case crystalResonance
    case frontierLedger
    case ruinScanners
    case starCoreCompression
    case silverTonguedBroker

    var id: String { rawValue }
}

enum MetaUpgradeID: String, CaseIterable, Codable, Identifiable {
    case longHaulCaravans
    case guildCharters
    case sectorMaps
    case relicVault
    case frontierCouncil

    var id: String { rawValue }
}

enum AchievementID: String, CaseIterable, Codable, Identifiable {
    case firstClaim
    case firstRig
    case tenDrills
    case oreTown
    case dustUnlocked
    case powerRails
    case industrialHeart
    case claimJumper
    case firstExpansion
    case seasonedMarshal
    case longRideHome
    case frontierLegend
    case millionMined
    case coreEmpire

    var id: String { rawValue }
}

enum SectorID: String, CaseIterable, Codable, Identifiable {
    case redMesa
    case glassDunes
    case emberBelt
    case haloReach
    case crownFrontier

    var id: String { rawValue }
}

enum BoostKind: String, Codable, CaseIterable, Identifiable {
    case productionRush
    case dailyBlessing
    case premiumMomentum

    var id: String { rawValue }
}
