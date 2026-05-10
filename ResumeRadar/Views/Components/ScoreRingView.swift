import SwiftUI

struct ScoreRingView: View {
    let score: Double
    let size: CGFloat
    let lineWidth: CGFloat

    init(score: Double, size: CGFloat = 60, lineWidth: CGFloat = 6) {
        self.score = score
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: score / 100)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.6), value: score)
            Text("\(Int(score))")
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(width: size, height: size)
    }

    private var scoreColor: Color {
        switch score {
        case 80...100: return AppColors.successGreen
        case 40..<80: return AppColors.warningYellow
        default: return AppColors.dangerRed
        }
    }
}
