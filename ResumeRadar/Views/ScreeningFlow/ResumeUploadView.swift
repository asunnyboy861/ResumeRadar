import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ResumeUploadView: View {
    let job: JobDescription
    @Environment(\.modelContext) private var modelContext
    @State private var screeningViewModel: ScreeningViewModel
    @State private var showFilePicker = false
    @State private var showScreening = false
    @State private var uploadedCount = 0

    init(job: JobDescription) {
        self.job = job
        let aiService = AIMatchingService(apiKey: "")
        let subService = SubscriptionService()
        _screeningViewModel = State(wrappedValue: ScreeningViewModel(aiService: aiService, subscriptionService: subService))
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Upload Resumes")
                .font(.title2)
                .fontWeight(.bold)

            Text("Select PDF resumes to screen against \(job.title)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            uploadZone

            if !screeningViewModel.candidates.isEmpty {
                uploadedList
            }

            Spacer()

            if !screeningViewModel.candidates.isEmpty {
                Button {
                    showScreening = true
                } label: {
                    Text("Start Screening (\(screeningViewModel.candidates.count) resumes)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
        }
        .padding()
        .navigationTitle("Upload Resumes")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .navigationDestination(isPresented: $showScreening) {
            ScreeningProgressView(
                screeningViewModel: screeningViewModel,
                job: job
            )
        }
    }

    private var uploadZone: some View {
        Button {
            showFilePicker = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "arrow.up.doc")
                    .font(.system(size: 40))
                    .foregroundStyle(AppColors.primaryBlue)
                Text("Tap to select PDF files")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Up to \(screeningViewModel.subscriptionService.maxResumesPerScreening) resumes per screening")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(AppColors.primaryBlue.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.primaryBlue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8])
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var uploadedList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Uploaded (\(screeningViewModel.candidates.count))")
                .font(.headline)

            ForEach(screeningViewModel.candidates) { candidate in
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(AppColors.primaryBlue)
                    VStack(alignment: .leading) {
                        Text(candidate.name)
                            .font(.subheadline)
                        if !candidate.email.isEmpty {
                            Text(candidate.email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.successGreen)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            let maxResumes = screeningViewModel.subscriptionService.maxResumesPerScreening
            let limitedURLs = Array(urls.prefix(maxResumes))
            screeningViewModel.uploadResumes(from: limitedURLs, for: job, modelContext: modelContext)
        case .failure:
            break
        }
    }
}
