import SwiftUI

enum FrontierTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.97, green: 0.95, blue: 0.92),
            Color(red: 0.89, green: 0.86, blue: 0.81)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let card = Color.white.opacity(0.76)
    static let cardBorder = Color.black.opacity(0.07)
    static let accent = Color(red: 0.76, green: 0.43, blue: 0.19)
    static let secondaryAccent = Color(red: 0.22, green: 0.41, blue: 0.47)
    static let positive = Color(red: 0.17, green: 0.51, blue: 0.35)
    static let shadow = Color.black.opacity(0.08)
    static let subduedText = Color.black.opacity(0.58)
    static let premiumGradient = LinearGradient(
        colors: [
            Color(red: 0.18, green: 0.22, blue: 0.28),
            Color(red: 0.33, green: 0.24, blue: 0.17)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.83, green: 0.52, blue: 0.24),
            Color(red: 0.65, green: 0.32, blue: 0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct FrontierCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(FrontierTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(FrontierTheme.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: FrontierTheme.shadow, radius: 16, x: 0, y: 10)
            )
    }
}

extension View {
    func frontierCard() -> some View {
        modifier(FrontierCardModifier())
    }
}
