import SwiftUI

struct FrontierActionButton: View {
    enum Variant {
        case primary
        case secondary
        case ghost

        var foreground: Color {
            switch self {
            case .primary:
                return .white
            case .secondary, .ghost:
                return Color.primary
            }
        }
    }

    let title: String
    let variant: Variant
    let isDisabled: Bool
    let action: () -> Void

    init(_ title: String, variant: Variant = .primary, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(isDisabled ? Color.black.opacity(0.35) : variant.foreground)
                .background(background)
        }
        .disabled(isDisabled)
    }

    @ViewBuilder
    private var background: some View {
        switch variant {
        case .primary:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isDisabled ? Color.black.opacity(0.08) : FrontierTheme.accentGradient)
        case .secondary:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(isDisabled ? 0.04 : 0.08))
        case .ghost:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(isDisabled ? 0.05 : 0.12), lineWidth: 1)
        }
    }
}
