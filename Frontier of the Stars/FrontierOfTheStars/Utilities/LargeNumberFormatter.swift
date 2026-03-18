import Foundation

enum LargeNumberFormatter {
    static func format(_ value: Double, precision: Int = 1) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""

        if absValue < 1_000 {
            return sign + integerStyle(absValue)
        }

        let suffixes: [(Double, String)] = [
            (1_000_000_000_000, "T"),
            (1_000_000_000, "B"),
            (1_000_000, "M"),
            (1_000, "K")
        ]

        for (threshold, suffix) in suffixes where absValue >= threshold {
            let scaled = absValue / threshold
            let format = "%.\(precision)f"
            let raw = String(format: format, scaled)
            let trimmed = raw.hasSuffix(".0") ? String(raw.dropLast(2)) : raw
            return sign + trimmed + suffix
        }

        return sign + integerStyle(absValue)
    }

    static func rate(_ value: Double) -> String {
        "\(format(value))/s"
    }

    private static func integerStyle(_ value: Double) -> String {
        value.formatted(.number.grouping(.automatic).precision(.fractionLength(0)))
    }
}
