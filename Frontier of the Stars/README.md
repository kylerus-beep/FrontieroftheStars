# Frontier of the Stars

`Frontier of the Stars` is an iPhone-first incremental / idle game MVP built with SwiftUI, SwiftData, StoreKit 2 abstractions, and a swap-ready rewarded ad layer.

## Folder Structure

```text
FrontierOfTheStars/
  App/
    FrontierOfTheStarsApp.swift
    RootTabView.swift
  Models/
    GameSnapshot.swift
    MonetizationModels.swift
    ProgressionModels.swift
  GameEngine/
    GameBalance.swift
    GameContent.swift
    GameEconomyMath.swift
    GameEngine.swift
  ViewModels/
    GameViewModel.swift
  Views/
    Home/
      HomeView.swift
    Generators/
      GeneratorsView.swift
    Upgrades/
      UpgradesView.swift
    Achievements/
      AchievementsView.swift
    Prestige/
      PrestigeView.swift
    Store/
      RewardedOfferCard.swift
      StoreProductCard.swift
      StoreView.swift
    Settings/
      SettingsView.swift
    Components/
      AchievementRow.swift
      BoostBanner.swift
      DailyRewardSheet.swift
      FrontierActionButton.swift
      GeneratorRow.swift
      MetricRow.swift
      OfflineEarningsSheet.swift
      OnboardingView.swift
      RewardSummaryCard.swift
      ResourceChip.swift
      SectionCard.swift
      TargetCard.swift
      UpgradeRow.swift
  Services/
    PersistenceService.swift
  Monetization/
    AdManager.swift
    PurchaseManager.swift
  Utilities/
    FrontierFormatters.swift
    LargeNumberFormatter.swift
    PreviewSnapshots.swift
    Theme.swift
  Resources/
    IntegrationNotes.md
```

## System Overview

- `GameSnapshot` is the full persistent save payload. SwiftData stores it as a single versioned blob in `PersistedGameState`, which keeps migration scope small for a v1 MVP.
- `GameContent` contains all balancing content: resources, generators, upgrades, achievements, meta upgrades, sectors, rewarded offers, daily rewards, and product definitions.
- `GameEngine` is the gameplay core:
  - production tick simulation
  - generator cost scaling
  - upgrade effects
  - unlock progression
  - prestige preview and reset
  - achievement completion and reward grants
  - offline earnings
  - boost handling
- `GameEconomyMath` centralizes production, multiplier, and prestige formulas so balancing changes do not leak across the UI or persistence code.
- `GameViewModel` is the app coordinator:
  - loads and saves SwiftData state
  - drives the timer loop
  - handles app lifecycle / offline resume
  - bridges StoreKit purchases into entitlements and rewards
  - bridges rewarded-ad placements into optional game boosts
- `PreviewSnapshots` and screen previews provide a reliable sample frontier state for design iteration.
- SwiftUI views stay thin and read mostly from the view model and shared components.

## Core Progression Loop

1. Manually prospect Ore, then unlock Dust and Energy.
2. Buy generators with escalating costs using `baseCost * pow(1.15, owned)`.
3. Reach milestone upgrades that meaningfully alter production, costs, prestige rewards, and offline caps.
4. Push into Tier 2 and Tier 3 resources.
5. Trigger `Frontier Expansion` to reset run progress for permanent `Frontier Badges`.
6. Spend badges on meta upgrades and unlock deeper frontier sectors.
7. Repeat with stronger permanent output and better long-term targets.

## Monetization Design

- Rewarded ads are optional:
  - temporary 2x production boost
  - 3x offline claim
  - instant crate
  - emergency progress shipment
- IAPs sell convenience and acceleration:
  - remove rewarded gating
  - starter pack
  - permanent 1.35x booster
  - Star Shard consumables
  - QoL upgrades like extra offline time and richer daily rewards
- The base loop remains fully playable without paying.

## Opening In Xcode

This workspace contains the full source tree, but not a generated `.xcodeproj`.

To run it in Xcode:

1. Create a new iOS App project named `FrontierOfTheStars`.
2. Set Interface to `SwiftUI`, Language to `Swift`, and enable `Use SwiftData`.
3. Delete the default generated source files.
4. Drag the `FrontierOfTheStars` folder from this workspace into the Xcode project navigator.
5. Make sure all Swift files are added to the app target.
6. In Signing & Capabilities, enable In-App Purchase.
7. Add a StoreKit configuration file in Xcode and mirror the product IDs listed in `Resources/IntegrationNotes.md`.
8. Build and run on an iPhone simulator or device targeting iOS 17+.

## Future Expansion

- Add a second prestige layer above `Frontier Badges`.
- Add map-based sectors with sector-specific modifiers and events.
- Add relic inventory, ruin expeditions, and rotating contracts.
- Add charts for production history and milestone pacing.
- Add cosmetic themes, town customization, and premium badge frames.
- Break the save blob into multiple SwiftData entities if live-ops tooling ever needs direct querying.
