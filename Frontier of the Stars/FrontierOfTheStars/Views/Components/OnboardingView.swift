import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var game: GameViewModel

    private let pages: [(String, String, String)] = [
        ("Claim the Frontier", "Tap early resources, hire machines, and let the town work while you are away.", "sun.max.fill"),
        ("Build the Economy", "Turn Ore, Dust, and Energy into late-game alien industry and automated growth.", "building.2.fill"),
        ("Expand Forever", "Reset with Frontier Expansion to earn permanent Badges, sectors, and meta upgrades.", "sparkles"),
        ("Optional Boosts Only", "Rewarded ads and purchases speed things up, but every system is playable for free.", "cart.fill")
    ]

    var body: some View {
        ZStack {
            FrontierTheme.background
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                TabView {
                    ForEach(pages, id: \.0) { page in
                        VStack(spacing: 20) {
                            Image(systemName: page.2)
                                .font(.system(size: 54, weight: .regular))
                                .foregroundStyle(FrontierTheme.accent)
                            Text(page.0)
                                .font(.largeTitle.weight(.bold))
                                .multilineTextAlignment(.center)
                            Text(page.1)
                                .font(.title3)
                                .foregroundStyle(FrontierTheme.subduedText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                        }
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 420)

                Button(action: game.completeOnboarding) {
                    Text("Start Prospecting")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(FrontierTheme.accent)
                        )
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}
