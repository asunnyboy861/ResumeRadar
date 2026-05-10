import SwiftUI

struct ContactSupportView: View {
    @State private var selectedSubject: SupportSubject = .general
    @State private var customSubject: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var isSubmitting = false
    @State private var submitResult: SubmitResult?

    private let backendURL = "https://feedback-board.iocompile67692.workers.dev"

    var body: some View {
        Form {
            Section {
                subjectGrid
                if selectedSubject == .other {
                    TextField("Custom subject...", text: $customSubject)
                        .autocorrectionDisabled()
                }
            } header: {
                Text("Subject")
            }

            Section {
                TextField("Your Name", text: $name)
                TextField("Email Address", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section {
                TextEditor(text: $message)
                    .frame(minHeight: 120)
            } header: {
                Text("Message")
            }

            Section {
                Button {
                    Task { await submitFeedback() }
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Submit")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting || name.isEmpty || email.isEmpty || message.isEmpty)
            }

            if let result = submitResult {
                Section {
                    switch result {
                    case .success:
                        Label("Feedback submitted successfully!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.successGreen)
                    case .failure(let error):
                        Label(error, systemImage: "xmark.circle.fill")
                            .foregroundStyle(AppColors.dangerRed)
                    }
                }
            }
        }
        .navigationTitle("Contact Support")
    }

    private var subjectGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            ForEach(SupportSubject.allCases) { subject in
                Button {
                    selectedSubject = subject
                } label: {
                    Text(subject.displayName)
                        .font(.caption)
                        .fontWeight(selectedSubject == subject ? .semibold : .regular)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(selectedSubject == subject ? AppColors.primaryBlue : Color(.systemBackground))
                        .foregroundStyle(selectedSubject == subject ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: selectedSubject == subject ? 0 : 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func submitFeedback() async {
        isSubmitting = true
        submitResult = nil

        let subjectText = selectedSubject == .other ? customSubject : selectedSubject.displayName
        let request = FeedbackRequest(
            name: name,
            email: email,
            subject: subjectText,
            message: message,
            app_name: "ResumeRadar"
        )

        do {
            guard let url = URL(string: "\(backendURL)/api/feedback") else {
                submitResult = .failure("Invalid URL")
                isSubmitting = false
                return
            }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            let (_, response) = try await URLSession.shared.data(for: urlRequest)
            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                submitResult = .success
                name = ""
                email = ""
                message = ""
                customSubject = ""
                selectedSubject = .general
            } else {
                submitResult = .failure("Server error. Please try again.")
            }
        } catch {
            submitResult = .failure("Network error. Please check your connection.")
        }
        isSubmitting = false
    }
}

enum SupportSubject: String, CaseIterable, Identifiable {
    case general = "general"
    case featureSuggestion = "feature_suggestion"
    case bugReport = "bug_report"
    case usageQuestion = "usage_question"
    case performanceIssue = "performance_issue"
    case uiImprovement = "ui_improvement"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .general: return "General"
        case .featureSuggestion: return "Feature Suggestion"
        case .bugReport: return "Bug Report"
        case .usageQuestion: return "Usage Question"
        case .performanceIssue: return "Performance Issue"
        case .uiImprovement: return "UI Improvement"
        case .other: return "Other"
        }
    }
}

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}

enum SubmitResult {
    case success
    case failure(String)
}
