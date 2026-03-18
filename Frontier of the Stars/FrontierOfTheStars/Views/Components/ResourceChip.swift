import SwiftUI

struct ResourceChip: View {
    let resource: ResourceDefinition
    let amount: Double
    let rate: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(resource.name, systemImage: resource.icon)
                .font(.subheadline.weight(.semibold))
            Text(LargeNumberFormatter.format(amount))
                .font(.title3.weight(.bold))
            Text(LargeNumberFormatter.rate(rate))
                .font(.caption)
                .foregroundStyle(FrontierTheme.subduedText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.64))
        )
    }
}
