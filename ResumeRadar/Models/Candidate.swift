import Foundation
import SwiftData

@Model
final class Candidate {
    var id: UUID
    var name: String
    var email: String
    var phone: String
    var rawText: String
    var parsedSkills: [String]
    var experienceYears: Int
    var education: String
    var overallScore: Double
    var skillMatchScore: Double
    var experienceMatchScore: Double
    var educationMatchScore: Double
    var cultureFitScore: Double
    var matchedSkills: [String]
    var missingSkills: [String]
    var strengths: [String]
    var weaknesses: [String]
    var aiSummary: String
    var aiGeneratedProbability: Double
    @Relationship(deleteRule: .cascade, inverse: \RedFlag.candidate)
    var redFlags: [RedFlag]
    var status: CandidateStatus
    var notes: String
    var createdAt: Date
    var job: JobDescription?

    init(
        id: UUID = UUID(),
        name: String = "",
        email: String = "",
        phone: String = "",
        rawText: String = "",
        parsedSkills: [String] = [],
        experienceYears: Int = 0,
        education: String = "",
        overallScore: Double = 0,
        skillMatchScore: Double = 0,
        experienceMatchScore: Double = 0,
        educationMatchScore: Double = 0,
        cultureFitScore: Double = 0,
        matchedSkills: [String] = [],
        missingSkills: [String] = [],
        strengths: [String] = [],
        weaknesses: [String] = [],
        aiSummary: String = "",
        aiGeneratedProbability: Double = 0,
        redFlags: [RedFlag] = [],
        status: CandidateStatus = .pending,
        notes: String = "",
        createdAt: Date = Date(),
        job: JobDescription? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.rawText = rawText
        self.parsedSkills = parsedSkills
        self.experienceYears = experienceYears
        self.education = education
        self.overallScore = overallScore
        self.skillMatchScore = skillMatchScore
        self.experienceMatchScore = experienceMatchScore
        self.educationMatchScore = educationMatchScore
        self.cultureFitScore = cultureFitScore
        self.matchedSkills = matchedSkills
        self.missingSkills = missingSkills
        self.strengths = strengths
        self.weaknesses = weaknesses
        self.aiSummary = aiSummary
        self.aiGeneratedProbability = aiGeneratedProbability
        self.redFlags = redFlags
        self.status = status
        self.notes = notes
        self.createdAt = createdAt
        self.job = job
    }
}

enum CandidateStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case shortlisted = "shortlisted"
    case maybe = "maybe"
    case rejected = "rejected"
}
