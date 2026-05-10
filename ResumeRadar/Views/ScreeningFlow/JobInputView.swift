import SwiftUI
import SwiftData

struct JobInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: JobViewModel
    @State private var savedJob: JobDescription?
    @State private var navigateToUpload = false

    init() {
        let aiService = AIMatchingService(apiKey: "")
        _viewModel = State(wrappedValue: JobViewModel(aiService: aiService))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Job Title", text: $viewModel.jobTitle)
                    TextField("Paste Job Description...", text: $viewModel.jobDescriptionText, axis: .vertical)
                        .lineLimit(5...12)
                } header: {
                    HStack {
                        Text("Job Description")
                        Spacer()
                        if viewModel.isParsing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Button("AI Parse") {
                                Task { await viewModel.parseJobDescription() }
                            }
                            .disabled(viewModel.jobDescriptionText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }

                if !viewModel.requiredSkills.isEmpty || !viewModel.preferredSkills.isEmpty {
                    Section("Extracted Requirements") {
                        if !viewModel.requiredSkills.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Required Skills")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                FlowLayout(spacing: 6) {
                                    ForEach(viewModel.requiredSkills, id: \.self) { skill in
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
                        if !viewModel.preferredSkills.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Preferred Skills")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                FlowLayout(spacing: 6) {
                                    ForEach(viewModel.preferredSkills, id: \.self) { skill in
                                        Text(skill)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(AppColors.warningYellow.opacity(0.1))
                                            .foregroundStyle(AppColors.warningYellow)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        HStack {
                            Text("Min Experience")
                            Spacer()
                            Stepper("\(viewModel.minExperienceYears) years", value: $viewModel.minExperienceYears, in: 0...30)
                        }
                        TextField("Education Level", text: $viewModel.educationLevel)
                    }
                }

                if let error = viewModel.parseError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Screening")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") {
                        let job = viewModel.saveJob(modelContext: modelContext)
                        savedJob = job
                        navigateToUpload = true
                    }
                    .disabled(viewModel.jobTitle.isEmpty && viewModel.jobDescriptionText.isEmpty)
                }
            }
            .navigationDestination(isPresented: $navigateToUpload) {
                if let job = savedJob {
                    ResumeUploadView(job: job)
                }
            }
        }
    }
}
