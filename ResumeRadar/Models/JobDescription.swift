import Foundation
import SwiftData

@Model
final class JobDescription {
    var id: UUID
    var title: String
    var rawText: String
    var requiredSkills: [String]
    var preferredSkills: [String]
    var minExperienceYears: Int
    var educationLevel: String
    var createdAt: Date
    var candidates: [Candidate]

    init(
        id: UUID = UUID(),
        title: String = "",
        rawText: String = "",
        requiredSkills: [String] = [],
        preferredSkills: [String] = [],
        minExperienceYears: Int = 0,
        educationLevel: String = "",
        createdAt: Date = Date(),
        candidates: [Candidate] = []
    ) {
        self.id = id
        self.title = title
        self.rawText = rawText
        self.requiredSkills = requiredSkills
        self.preferredSkills = preferredSkills
        self.minExperienceYears = minExperienceYears
        self.educationLevel = educationLevel
        self.createdAt = createdAt
        self.candidates = candidates
    }
}
