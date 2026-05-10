import Foundation
import SwiftData

@MainActor
@Observable
final class ScreeningViewModel {
    var candidates: [Candidate] = []
    var screeningProgress: [UUID: ScreeningStep] = [:]
    var isScreening = false
    var currentScreeningIndex = 0
    var totalResumes = 0
    var errorMessage: String?

    private let aiService: AIMatchingService
    let subscriptionService: SubscriptionService

    init(aiService: AIMatchingService, subscriptionService: SubscriptionService) {
        self.aiService = aiService
        self.subscriptionService = subscriptionService
    }

    func uploadResumes(from urls: [URL], for job: JobDescription, modelContext: ModelContext) {
        for url in urls {
            guard let text = PDFExtractor.extractText(from: url) else { continue }
            let parsed = ResumeParserService.parse(text: text)
            let candidate = Candidate(
                name: parsed.name,
                email: parsed.email,
                phone: parsed.phone,
                rawText: parsed.rawText,
                parsedSkills: parsed.skills,
                experienceYears: parsed.experienceYears,
                education: parsed.education,
                job: job
            )
            modelContext.insert(candidate)
            candidates.append(candidate)
            screeningProgress[candidate.id] = .uploaded
        }
        try? modelContext.save()
        totalResumes = candidates.count
    }

    func startScreening(job: JobDescription, modelContext: ModelContext) async {
        guard subscriptionService.canScreen else {
            errorMessage = "Monthly screening limit reached. Upgrade to Pro for more."
            return
        }
        isScreening = true
        errorMessage = nil
        currentScreeningIndex = 0

        for (index, candidate) in candidates.enumerated() {
            currentScreeningIndex = index
            screeningProgress[candidate.id] = .analyzing

            let parsed = ParsedResume(
                name: candidate.name,
                email: candidate.email,
                phone: candidate.phone,
                skills: candidate.parsedSkills,
                experienceYears: candidate.experienceYears,
                education: candidate.education,
                rawText: candidate.rawText
            )

            do {
                let result = try await aiService.screenCandidate(resume: parsed, jobDescription: job)

                let detection = AIDetectionService.analyze(text: candidate.rawText)

                candidate.overallScore = result.overallScore
                candidate.skillMatchScore = result.skillMatchScore
                candidate.experienceMatchScore = result.experienceMatchScore
                candidate.educationMatchScore = result.educationMatchScore
                candidate.cultureFitScore = result.cultureFitScore
                candidate.matchedSkills = result.matchedSkills
                candidate.missingSkills = result.missingSkills
                candidate.strengths = result.strengths
                candidate.weaknesses = result.weaknesses
                candidate.aiSummary = result.aiSummary
                candidate.aiGeneratedProbability = max(result.aiGeneratedProbability, detection.probability)

                for indicator in detection.indicators {
                    let flag = RedFlag(
                        type: indicator.type.rawValue,
                        flagDescription: indicator.detail,
                        confidence: indicator.score,
                        candidate: candidate
                    )
                    modelContext.insert(flag)
                    candidate.redFlags.append(flag)
                }

                screeningProgress[candidate.id] = .completed
            } catch {
                screeningProgress[candidate.id] = .failed
                candidate.overallScore = 0
            }

            try? modelContext.save()

            if index < candidates.count - 1 {
                try? await Task.sleep(nanoseconds: AppConstants.apiDelayBetweenCalls)
            }
        }

        subscriptionService.incrementScreeningUsage()
        isScreening = false
    }

    func sortedCandidates() -> [Candidate] {
        candidates.sorted { $0.overallScore > $1.overallScore }
    }
}

enum ScreeningStep: String {
    case uploaded = "uploaded"
    case analyzing = "analyzing"
    case completed = "completed"
    case failed = "failed"
}
