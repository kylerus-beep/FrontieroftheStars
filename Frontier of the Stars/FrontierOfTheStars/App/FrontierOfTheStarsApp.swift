import SwiftData
import SwiftUI

@main
struct FrontierOfTheStarsApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [PersistedGameState.self])
    }
}
