# Integration Notes

## Rewarded Ads

Current implementation:

- Protocol: `Monetization/AdManager.swift`
- Mock implementation: `MockAdManager`
- Entry points used by UI:
  - `RewardedAdPlacement.productionBoost`
  - `RewardedAdPlacement.offlineMultiplier`
  - `RewardedAdPlacement.resourceCrate`
  - `RewardedAdPlacement.frontierPush`

To integrate a real SDK such as AdMob rewarded ads:

1. Replace `MockAdManager` with a concrete SDK-backed class.
2. Keep the `AdManager` protocol unchanged if possible so the UI and view model do not need rewrites.
3. Map placement enums to actual ad unit IDs.
4. Preserve cooldown / readiness behavior at the manager layer.
5. Return `true` only after the SDK confirms a reward grant.

## StoreKit Product IDs

Use these identifiers in App Store Connect and in a local StoreKit configuration file:

- `com.frontierofthestars.removeads`
- `com.frontierofthestars.starterpack`
- `com.frontierofthestars.frontierbooster`
- `com.frontierofthestars.shards.small`
- `com.frontierofthestars.shards.medium`
- `com.frontierofthestars.shards.large`
- `com.frontierofthestars.extraoffline`
- `com.frontierofthestars.extradaily`
- `com.frontierofthestars.theme.chrome`

## Purchase Application Logic

Product grants are applied in:

- `ViewModels/GameViewModel.swift`
- Method: `applyPurchasedProduct(_:)`

Update that method if product payloads change.

## Save / Persistence

- SwiftData stores one `PersistedGameState` record containing a JSON-encoded `GameSnapshot`.
- This is intentional for v1 simplicity and future schema-version migrations.
- If you later need granular analytics or direct entity queries, split resources, generators, and achievements into separate SwiftData models.
