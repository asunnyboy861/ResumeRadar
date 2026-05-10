import SwiftUI
import SwiftData

struct ScreeningProgressView: View {
    @Bindable var screeningViewModel: ScreeningViewModel
    let job: JobDescription
    @Environment(\.modelContext) private var modelContext
    @State private var navigateToResults = false

    var body: some View {
        VStack(spacing: 24) {
            if screeningViewModel.isScreening {
                activeScreeningView
            } else {
                completedView
            }
        }
        .padding()
        .navigationTitle("Screening")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToResults) {
            ResultsView(job: job)
        }
        .task {
            if screeningViewModel.isScreening == false && screeningViewModel.candidates.allSatisfy({ screeningViewModel.screeningProgress[$0.id] == .uploaded }) {
                await screeningViewModel.startScreening(job: job, modelContext: modelContext)
            }
        }
    }

    private var activeScreeningView: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(screeningViewModel.currentScreeningIndex + 1), total: Double(screeningViewModel.totalResumes))
                .progressViewStyle(.linear)
                .tint(AppColors.primaryBlue)

            Text("Analyzing resume \(screeningViewModel.currentScreeningIndex + 1) of \(screeningViewModel.totalResumes)")
                .font(.headline)

            if screeningViewModel.currentScreeningIndex >= 0 && screeningViewModel.currentScreeningIndex < screeningViewModel.candidates.count {
                let candidate = screeningViewModel.candidates[screeningViewModel.currentScreeningIndex]
                VStack(spacing: 8) {
                    Text(candidate.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    HStack(spacing: 16) {
                        Label("Parsing", systemImage: screeningViewModel.screeningProgress[candidate.id] == .analyzing ? "hourglass" : "checkmark")
                        Label("Scoring", systemImage: "star")
                        Label("Detecting", systemImage: "sparkles")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var completedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppColors.successGreen)

            Text("Screening Complete")
                .font(.title2)
                .fontWeight(.bold)

            let completed = screeningViewModel.candidates.filter { screeningViewModel.screeningProgress[$0.id] == .completed }.count
            let failed = screeningViewModel.candidates.filter { screeningViewModel.screeningProgress[$0.id] == .failed }.count

            Text("\(completed) analyzed, \(failed) failed")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("View Results") {
                navigateToResults = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
