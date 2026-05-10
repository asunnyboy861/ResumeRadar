import SwiftUI

enum AppColors {
    static let primaryBlue = Color(hex: "007AFF")
    static let successGreen = Color(hex: "34C759")
    static let warningYellow = Color(hex: "FF9500")
    static let dangerRed = Color(hex: "FF3B30")
    static let aiPurple = Color(hex: "AF52DE")
    static let backgroundLight = Color(hex: "F2F2F7")
    static let backgroundDark = Color(hex: "000000")
    static let cardLight = Color(hex: "FFFFFF")
    static let cardDark = Color(hex: "1C1C1E")
    static let textPrimaryLight = Color(hex: "1C1C1E")
    static let textPrimaryDark = Color(hex: "FFFFFF")
    static let textSecondary = Color(hex: "8E8E93")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum AppConstants {
    static let freeMonthlyScreenings = 3
    static let freeMaxResumesPerScreening = 10
    static let proMonthlyScreenings = 100
    static let proAnnualScreenings = 150
    static let proMaxResumesPerScreening = 50
    static let freeMaxActiveJobs = 1
    static let monthlyProductID = "com.zzoutuo.ResumeRadar.proMonthly"
    static let annualProductID = "com.zzoutuo.ResumeRadar.proAnnual"
    static let apiDelayBetweenCalls: UInt64 = 500_000_000
}
