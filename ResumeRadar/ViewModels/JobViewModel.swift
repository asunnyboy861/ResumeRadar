import Foundation
import SwiftData

@MainActor
@Observable
final class JobViewModel {
    var jobTitle: String = ""
    var jobDescriptionText: String = ""
    var requiredSkills: [String] = []
    var preferredSkills: [String] = []
    var minExperienceYears: Int = 0
    var educationLevel: String = ""
    var isParsing = false
    var parseError: String?

    private let aiService: AIMatchingService

    init(aiService: AIMatchingService) {
        self.aiService = aiService
    }

    func parseJobDescription() async {
        guard !jobDescriptionText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isParsing = true
        parseError = nil
        do {
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

    func saveJob(modelContext: ModelContext) -> JobDescription {
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
        return job
    }
}
