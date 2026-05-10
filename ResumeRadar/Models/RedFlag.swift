import Foundation
import SwiftData

@Model
final class RedFlag {
    var id: UUID
    var type: String
    var flagDescription: String
    var confidence: Double
    var candidate: Candidate?

    init(
        id: UUID = UUID(),
        type: String = "",
        flagDescription: String = "",
        confidence: Double = 0,
        candidate: Candidate? = nil
    ) {
        self.id = id
        self.type = type
        self.flagDescription = flagDescription
        self.confidence = confidence
        self.candidate = candidate
    }
}

enum RedFlagType: String, CaseIterable {
    case aiGenerated = "ai_generated"
    case buzzword = "buzzword"
    case lowVariance = "low_variance"
    case lowDiversity = "low_diversity"
    case perfectFormatting = "perfect_formatting"
    case experienceGap = "experience_gap"
    case skillMismatch = "skill_mismatch"
}
