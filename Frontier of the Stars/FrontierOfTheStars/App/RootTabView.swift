import SwiftData
import SwiftUI

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var game = GameViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            FrontierTheme.background
                .ignoresSafeArea()

            TabView {
                NavigationStack { HomeView() }
                    .tabItem { Label("Frontier", systemImage: "sun.max.fill") }
                NavigationStack { GeneratorsView() }
                    .tabItem { Label("Generators", systemImage: "gearshape.2.fill") }
                NavigationStack { UpgradesView() }
                    .tabItem { Label("Upgrades", systemImage: "bolt.badge.clock.fill") }
                NavigationStack { AchievementsView() }
                    .tabItem { Label("Achievements", systemImage: "rosette") }
                NavigationStack { PrestigeView() }
                    .tabItem { Label("Prestige", systemImage: "arrow.uturn.backward.circle.fill") }
                NavigationStack { StoreView() }
                    .tabItem { Label("Store", systemImage: "cart.fill") }
            }
            .environmentObject(game)
            .tint(FrontierTheme.accent)

            if let toastMessage = game.toastMessage {
                Text(toastMessage)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.black.opacity(0.82))
                    )
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            withAnimation {
                                game.clearToast()
                            }
                        }
                    }
            }
        }
        .task {
            game.attach(context: modelContext)
        }
        .onChange(of: scenePhase) { _, newValue in
            game.handleScenePhase(newValue)
        }
        .sheet(isPresented: $game.showingSettings) {
            NavigationStack { SettingsView().environmentObject(game) }
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: Binding(
            get: { game.showingOfflineSheet && !game.showingOnboarding },
            set: { game.showingOfflineSheet = $0 }
        )) {
            OfflineEarningsSheet()
                .environmentObject(game)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: Binding(
            get: { game.showingDailyRewardSheet && !game.showingOfflineSheet && !game.showingOnboarding },
            set: { game.showingDailyRewardSheet = $0 }
        )) {
            DailyRewardSheet()
                .environmentObject(game)
                .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $game.showingOnboarding) {
            OnboardingView()
                .environmentObject(game)
        }
    }
}
