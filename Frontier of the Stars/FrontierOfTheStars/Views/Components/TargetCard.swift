import SwiftUI

struct TargetCard: View {
    let target: ProgressTarget

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(target.title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(FrontierTheme.secondaryAccent)
            Text(target.detail)
                .font(.subheadline)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.6))
        )
    }
}
