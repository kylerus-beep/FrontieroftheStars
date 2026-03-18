import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var game: GameViewModel
    @State private var showingResetAlert = false

    var body: some View {
        Form {
            Section("Audio") {
                Toggle("Sound", isOn: Binding(
                    get: { game.snapshot.soundEnabled },
                    set: { game.setSoundEnabled($0) }
                ))
            }

            Section("Support") {
                Button("Restore Purchases") {
                    Task {
                        await game.restorePurchases()
                    }
                }
                LabeledContent("Version", value: "1.0 MVP")
                LabeledContent("About", value: "Wild West idle empire on the alien frontier.")
            }

            Section("Danger Zone") {
                Button("Reset Save Data", role: .destructive) {
                    showingResetAlert = true
                }
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Reset all local progress?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {
            }
            Button("Reset", role: .destructive) {
                game.resetSaveData()
                dismiss()
            }
        } message: {
            Text("This clears your local save. Store purchases can still be restored.")
        }
    }
}
