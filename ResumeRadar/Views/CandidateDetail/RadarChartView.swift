import SwiftUI

struct RadarChartView: View {
    let scores: [Double]
    let labels: [String]

    private let categories: Int

    init(scores: [Double], labels: [String]) {
        self.scores = scores
        self.labels = labels
        self.categories = min(scores.count, labels.count)
    }

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 30
            let angleStep = 2 * .pi / CGFloat(categories)

            for ring in 1...4 {
                let ringRadius = radius * CGFloat(ring) / 4
                let path = Path { p in
                    for i in 0..<categories {
                        let angle = angleStep * CGFloat(i) - .pi / 2
                        let point = CGPoint(
                            x: center.x + ringRadius * cos(angle),
                            y: center.y + ringRadius * sin(angle)
                        )
                        if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
                    }
                    p.closeSubpath()
                }
                context.stroke(path, with: .color(.gray.opacity(0.2)), lineWidth: 1)
            }

            for i in 0..<categories {
                let angle = angleStep * CGFloat(i) - .pi / 2
                let endPoint = CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
                context.stroke(
                    Path { p in p.move(to: center); p.addLine(to: endPoint) },
                    with: .color(.gray.opacity(0.15)),
                    lineWidth: 1
                )
            }

            let dataPath = Path { p in
                for i in 0..<categories {
                    let angle = angleStep * CGFloat(i) - .pi / 2
                    let value = scores[i] / 100
                    let point = CGPoint(
                        x: center.x + radius * value * cos(angle),
                        y: center.y + radius * value * sin(angle)
                    )
                    if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
                }
                p.closeSubpath()
            }
            context.fill(dataPath, with: .color(AppColors.primaryBlue.opacity(0.2)))
            context.stroke(dataPath, with: .color(AppColors.primaryBlue), lineWidth: 2)

            for i in 0..<categories {
                let angle = angleStep * CGFloat(i) - .pi / 2
                let value = scores[i] / 100
                let point = CGPoint(
                    x: center.x + radius * value * cos(angle),
                    y: center.y + radius * value * sin(angle)
                )
                context.fill(
                    Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)),
                    with: .color(AppColors.primaryBlue)
                )
            }
        }
        .overlay {
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius = min(geo.size.width, geo.size.height) / 2 - 30
                let angleStep = 2 * .pi / CGFloat(categories)

                ForEach(0..<categories, id: \.self) { i in
                    let angle = angleStep * CGFloat(i) - .pi / 2
                    let labelPoint = CGPoint(
                        x: center.x + (radius + 20) * cos(angle),
                        y: center.y + (radius + 20) * sin(angle)
                    )
                    Text(labels[i])
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .position(labelPoint)
                }
            }
        }
    }
}
