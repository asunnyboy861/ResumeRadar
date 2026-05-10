import SwiftUI

struct SwipeCardView: View {
    let candidate: Candidate
    var onShortlist: () -> Void
    var onReject: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isDragging = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(candidate.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if !candidate.email.isEmpty {
                        Text(candidate.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                ScoreRingView(score: candidate.overallScore, size: 50, lineWidth: 5)
            }

            HStack(spacing: 8) {
                if candidate.aiGeneratedProbability > 30 {
                    Label("\(Int(candidate.aiGeneratedProbability))% AI", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(AppColors.aiPurple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.aiPurple.opacity(0.1))
                        .clipShape(Capsule())
                }
                StatusBadgeView(status: candidate.status)
            }

            if !candidate.matchedSkills.isEmpty {
                WrappingHStack(items: candidate.matchedSkills.prefix(5).map { $0 }, font: .caption) { skill in
                    Text(skill)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.successGreen.opacity(0.1))
                        .foregroundStyle(AppColors.successGreen)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .offset(x: offset)
        .rotationEffect(.degrees(Double(offset) / 40))
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    offset = value.translation.width
                }
                .onEnded { value in
                    isDragging = false
                    if value.translation.width > 100 {
                        onShortlist()
                        offset = 500
                    } else if value.translation.width < -100 {
                        onReject()
                        offset = -500
                    } else {
                        offset = 0
                    }
                }
        )
        .animation(.spring(duration: 0.4), value: offset)
    }
}

struct StatusBadgeView: View {
    let status: CandidateStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.color.opacity(0.15))
            .foregroundStyle(status.color)
            .clipShape(Capsule())
    }
}

struct WrappingHStack<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let font: Font
    let content: (Item) -> Content

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

extension CandidateStatus: Identifiable {
    public var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .shortlisted: return "Shortlisted"
        case .maybe: return "Maybe"
        case .rejected: return "Rejected"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .gray
        case .shortlisted: return AppColors.successGreen
        case .maybe: return AppColors.warningYellow
        case .rejected: return AppColors.dangerRed
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
