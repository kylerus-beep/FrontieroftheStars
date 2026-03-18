import Foundation

protocol AdManager {
    func canPresentAd(for placement: RewardedAdPlacement, removeAdsEntitlement: Bool) -> Bool
    func cooldownRemaining(for placement: RewardedAdPlacement, now: Date) -> TimeInterval
    func presentRewardedAd(for placement: RewardedAdPlacement, removeAdsEntitlement: Bool) async -> Bool
}

@MainActor
final class MockAdManager: AdManager {
    private var lastShownAt: [RewardedAdPlacement: Date] = [:]

    func canPresentAd(for placement: RewardedAdPlacement, removeAdsEntitlement: Bool) -> Bool {
        if removeAdsEntitlement { return true }
        return cooldownRemaining(for: placement, now: .now) <= 0
    }

    func cooldownRemaining(for placement: RewardedAdPlacement, now: Date) -> TimeInterval {
        guard let last = lastShownAt[placement] else { return 0 }
        return max(0, GameBalance.adCooldown(for: placement) - now.timeIntervalSince(last))
    }

    func presentRewardedAd(for placement: RewardedAdPlacement, removeAdsEntitlement: Bool) async -> Bool {
        guard canPresentAd(for: placement, removeAdsEntitlement: removeAdsEntitlement) else { return false }
        if !removeAdsEntitlement {
            try? await Task.sleep(nanoseconds: 900_000_000)
        }
        lastShownAt[placement] = .now
        return true
    }
}
