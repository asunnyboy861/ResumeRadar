import SwiftUI
import SwiftData

struct CandidateDetailView: View {
    let candidate: Candidate
    let job: JobDescription
    @Environment(\.modelContext) private var modelContext
    @State private var notes: String = ""
    @State private var showShareSheet = false
    @State private var pdfData: Data?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                scoreOverview
                radarChartSection
                skillsSection
                if candidate.aiGeneratedProbability > 30 {
                    aiDetectionSection
                }
                if !candidate.redFlags.isEmpty {
                    redFlagsSection
                }
                strengthsWeaknessesSection
                aiSummarySection
                notesSection
                actionButtons
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(candidate.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notes = candidate.notes
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = pdfData {
                ShareSheet(activityItems: [data])
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(candidate.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    if !candidate.email.isEmpty {
                        Button {
                            if let url = URL(string: "mailto:\(candidate.email)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label(candidate.email, systemImage: "envelope")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.primaryBlue)
                        }
                    }
                    if !candidate.phone.isEmpty {
                        Text(candidate.phone)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                ScoreRingView(score: candidate.overallScore, size: 70)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var scoreOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Score Breakdown")
                .font(.headline)

            HStack(spacing: 12) {
                ScoreMiniView(label: "Skills", score: candidate.skillMatchScore, color: AppColors.primaryBlue)
                ScoreMiniView(label: "Experience", score: candidate.experienceMatchScore, color: AppColors.successGreen)
                ScoreMiniView(label: "Education", score: candidate.educationMatchScore, color: AppColors.warningYellow)
                ScoreMiniView(label: "Culture Fit", score: candidate.cultureFitScore, color: AppColors.aiPurple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var radarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Match Profile")
                .font(.headline)
            RadarChartView(
                scores: [
                    candidate.skillMatchScore,
                    candidate.experienceMatchScore,
                    candidate.educationMatchScore,
                    candidate.cultureFitScore
                ],
                labels: ["Skills", "Experience", "Education", "Culture"]
            )
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skills Match")
                .font(.headline)

            if !candidate.matchedSkills.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Matched")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    FlowLayout(spacing: 6) {
                        ForEach(candidate.matchedSkills, id: \.self) { skill in
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
            }

            if !candidate.missingSkills.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Missing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    FlowLayout(spacing: 6) {
                        ForEach(candidate.missingSkills, id: \.self) { skill in
                            Text(skill)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.dangerRed.opacity(0.1))
                                .foregroundStyle(AppColors.dangerRed)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var aiDetectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppColors.aiPurple)
                Text("AI Generation Detection")
                    .font(.headline)
            }

            HStack {
                Text("\(Int(candidate.aiGeneratedProbability))%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.aiPurple)
                Text("AI-generated probability")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: candidate.aiGeneratedProbability / 100)
                .tint(AppColors.aiPurple)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var redFlagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Red Flags")
                .font(.headline)
                .foregroundStyle(AppColors.dangerRed)

            ForEach(candidate.redFlags) { flag in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppColors.dangerRed)
                        .font(.caption)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(flag.type.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(flag.flagDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var strengthsWeaknessesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !candidate.strengths.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Strengths")
                        .font(.headline)
                        .foregroundStyle(AppColors.successGreen)
                    ForEach(candidate.strengths, id: \.self) { strength in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.successGreen)
                                .font(.caption)
                            Text(strength)
                                .font(.subheadline)
                        }
                    }
                }
            }

            if !candidate.weaknesses.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Areas of Concern")
                        .font(.headline)
                        .foregroundStyle(AppColors.warningYellow)
                    ForEach(candidate.weaknesses, id: \.self) { weakness in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(AppColors.warningYellow)
                                .font(.caption)
                            Text(weakness)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var aiSummarySection: some View {
        Group {
            if !candidate.aiSummary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(AppColors.aiPurple)
                        Text("AI Summary")
                            .font(.headline)
                    }
                    Text(candidate.aiSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            TextEditor(text: $notes)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onChange(of: notes) { _, newValue in
            candidate.notes = newValue
            try? modelContext.save()
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    candidate.status = .shortlisted
                    try? modelContext.save()
                } label: {
                    Label("Shortlist", systemImage: "hand.thumbsup.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.successGreen)

                Button {
                    candidate.status = .rejected
                    try? modelContext.save()
                } label: {
                    Label("Reject", systemImage: "hand.thumbsdown.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.dangerRed)
            }

            Button {
                pdfData = ReportGeneratorService.generatePDF(candidate: candidate, job: job)
                if pdfData != nil { showShareSheet = true }
            } label: {
                Label("Share Report", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct ScoreMiniView: View {
    let label: String
    let score: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text("\(Int(score))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
