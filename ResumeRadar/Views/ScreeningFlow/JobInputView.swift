import SwiftUI
import SwiftData

struct JobInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ai_api_key") private var apiKey: String = ""
    @AppStorage("ai_base_url") private var baseURL: String = "https://api.openai.com/v1"
    @AppStorage("ai_model") private var aiModel: String = "gpt-4o-mini"
    @State private var jobTitle: String = ""
    @State private var jobDescriptionText: String = ""
    @State private var requiredSkills: [String] = []
    @State private var preferredSkills: [String] = []
    @State private var minExperienceYears: Int = 0
    @State private var educationLevel: String = ""
    @State private var isParsing = false
    @State private var parseError: String?
    @State private var savedJob: JobDescription?
    @State private var navigateToUpload = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Job Title", text: $jobTitle)
                    TextField("Paste Job Description...", text: $jobDescriptionText, axis: .vertical)
                        .lineLimit(5...12)
                } header: {
                    HStack {
                        Text("Job Description")
                        Spacer()
                        if isParsing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Button("AI Parse") {
                                Task { await parseJobDescription() }
                            }
                            .disabled(jobDescriptionText.trimmingCharacters(in: .whitespaces).isEmpty || apiKey.isEmpty)
                        }
                    }
                }

                if !requiredSkills.isEmpty || !preferredSkills.isEmpty {
                    Section("Extracted Requirements") {
                        if !requiredSkills.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Required Skills")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                FlowLayout(spacing: 6) {
                                    ForEach(requiredSkills, id: \.self) { skill in
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
                        if !preferredSkills.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Preferred Skills")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                FlowLayout(spacing: 6) {
                                    ForEach(preferredSkills, id: \.self) { skill in
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
                            Stepper("\(minExperienceYears) years", value: $minExperienceYears, in: 0...30)
                        }
                        TextField("Education Level", text: $educationLevel)
                    }
                }

                if let error = parseError {
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
                        let job = JobDescription(
                            title: jobTitle,
                            rawText: jobDescriptionText,
                            requiredSkills: requiredSkills,
                            preferredSkills: preferredSkills,
                            minExperienceYears: minExperienceYears,
                            educationLevel: educationLevel
                        )
                        modelContext.insert(job)
                        try? modelContext.save()
                        savedJob = job
                        navigateToUpload = true
                    }
                    .disabled(jobTitle.isEmpty && jobDescriptionText.isEmpty)
                }
            }
            .navigationDestination(isPresented: $navigateToUpload) {
                if let job = savedJob {
                    ResumeUploadView(job: job)
                }
            }
        }
    }

    private func parseJobDescription() async {
        guard !apiKey.isEmpty else {
            parseError = "Please configure your API key in Settings > AI Configuration"
            return
        }
        guard !jobDescriptionText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isParsing = true
        parseError = nil
        do {
            let aiService = AIMatchingService(apiKey: apiKey, baseURL: baseURL)
            let parsed = try await aiService.parseJobDescription(text: jobDescriptionText)
            jobTitle = parsed.title
            requiredSkills = parsed.required_skills
            preferredSkills = parsed.preferred_skills
            minExperienceYears = parsed.min_experience_years
            educationLevel = parsed.education_level
        } catch {
            parseError = error.localizedDescription
        }
        isParsing = false
    }
}
