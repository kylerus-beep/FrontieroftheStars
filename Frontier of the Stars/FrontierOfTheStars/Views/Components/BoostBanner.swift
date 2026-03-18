import SwiftUI

struct BoostBanner: View {
    let boosts: [ActiveBoost]

    var body: some View {
        if !boosts.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(boosts) { boost in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(boost.title)
                                .font(.subheadline.weight(.semibold))
                            Text("\(Int((boost.multiplier - 1) * 100))% boost • \(remainingString(boost.expiresAt)) left")
                                .font(.caption)
                                .foregroundStyle(FrontierTheme.subduedText)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(FrontierTheme.accent.opacity(0.14))
                        )
                    }
                }
            }
        }
    }

    private func remainingString(_ date: Date) -> String {
        let remaining = max(0, Int(date.timeIntervalSinceNow))
        let minutes = remaining / 60
        let seconds = remaining % 60
        return "\(minutes)m \(seconds)s"
    }
}
