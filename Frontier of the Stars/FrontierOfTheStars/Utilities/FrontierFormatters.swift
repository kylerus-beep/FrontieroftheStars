import Foundation

enum FrontierFormatters {
    static func abbreviatedDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute] : [.minute, .second]
        formatter.maximumUnitCount = seconds >= 3600 ? 2 : 2
        return formatter.string(from: max(seconds, 0)) ?? "0m"
    }

    static func multiplier(_ value: Double) -> String {
        String(format: "%.2fx", value)
    }

    static func percent(_ value: Double) -> String {
        "\(Int((value - 1) * 100))%"
    }
}
