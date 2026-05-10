import Foundation

struct AIMatchingService {
    let apiKey: String
    let baseURL: String

    init(apiKey: String, baseURL: String = "https://api.openai.com/v1") {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    func screenCandidate(resume: ParsedResume, jobDescription: JobDescription) async throws -> ScreeningResult {
        let prompt = buildPrompt(resume: resume, jobDescription: jobDescription)
        let response = try await callOpenAI(prompt: prompt)
        return try parseResponse(response, resume: resume)
    }

    func parseJobDescription(text: String) async throws -> ParsedJobDescription {
        let prompt = """
        Parse this job description and extract structured information. Return ONLY valid JSON:
        {
          "title": "Job Title",
          "required_skills": ["skill1", "skill2"],
          "preferred_skills": ["skill1", "skill2"],
          "min_experience_years": 3,
          "education_level": "Bachelor"
        }

        Job Description:
        \(text)
        """
        let response = try await callOpenAI(prompt: prompt)
        return try parseJobResponse(response)
    }

    private func buildPrompt(resume: ParsedResume, jobDescription: JobDescription) -> String {
        return """
        You are an expert recruiter. Screen this resume against the job description.

        Return ONLY valid JSON:
        {
          "overall_score": 85,
          "skill_match_score": 90,
          "experience_match_score": 80,
          "education_match_score": 75,
          "culture_fit_score": 85,
          "matched_skills": ["skill1", "skill2"],
          "missing_skills": ["skill3"],
          "strengths": ["strength1", "strength2"],
          "weaknesses": ["weakness1"],
          "summary": "Brief assessment of candidate fit",
          "ai_generated_probability": 20
        }

        Job Title: \(jobDescription.title)
        Required Skills: \(jobDescription.requiredSkills.joined(separator: ", "))
        Preferred Skills: \(jobDescription.preferredSkills.joined(separator: ", "))
        Min Experience: \(jobDescription.minExperienceYears) years
        Education Level: \(jobDescription.educationLevel)

        Candidate Name: \(resume.name)
        Skills: \(resume.skills.joined(separator: ", "))
        Experience: \(resume.experienceYears) years
        Education: \(resume.education)

        Resume Text:
        \(resume.rawText.prefix(3000))
        """
    }

    private func callOpenAI(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIMatchingError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [["role": "user", "content": prompt]],
            "temperature": 0.3,
            "max_tokens": 1000
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw AIMatchingError.apiError("HTTP \(statusCode)")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = message?["content"] as? String ?? ""
        return content
    }

    private func parseResponse(_ response: String, resume: ParsedResume) throws -> ScreeningResult {
        let cleaned = response.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleaned.data(using: .utf8) else {
            throw AIMatchingError.parseError
        }
        let decoded = try JSONDecoder().decode(ScreeningResponseJSON.self, from: data)
        return ScreeningResult(
            overallScore: decoded.overall_score,
            skillMatchScore: decoded.skill_match_score,
            experienceMatchScore: decoded.experience_match_score,
            educationMatchScore: decoded.education_match_score,
            cultureFitScore: decoded.culture_fit_score,
            matchedSkills: decoded.matched_skills,
            missingSkills: decoded.missing_skills,
            strengths: decoded.strengths,
            weaknesses: decoded.weaknesses,
            aiSummary: decoded.summary,
            aiGeneratedProbability: decoded.ai_generated_probability
        )
    }

    private func parseJobResponse(_ response: String) throws -> ParsedJobDescription {
        let cleaned = response.replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleaned.data(using: .utf8) else {
            throw AIMatchingError.parseError
        }
        return try JSONDecoder().decode(ParsedJobDescription.self, from: data)
    }
}

struct ScreeningResult {
    let overallScore: Double
    let skillMatchScore: Double
    let experienceMatchScore: Double
    let educationMatchScore: Double
    let cultureFitScore: Double
    let matchedSkills: [String]
    let missingSkills: [String]
    let strengths: [String]
    let weaknesses: [String]
    let aiSummary: String
    let aiGeneratedProbability: Double
}

struct ParsedJobDescription: Codable {
    let title: String
    let required_skills: [String]
    let preferred_skills: [String]
    let min_experience_years: Int
    let education_level: String
}

private struct ScreeningResponseJSON: Codable {
    let overall_score: Double
    let skill_match_score: Double
    let experience_match_score: Double
    let education_match_score: Double
    let culture_fit_score: Double
    let matched_skills: [String]
    let missing_skills: [String]
    let strengths: [String]
    let weaknesses: [String]
    let summary: String
    let ai_generated_probability: Double
}

enum AIMatchingError: LocalizedError {
    case invalidURL
    case parseError
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .parseError: return "Failed to parse AI response"
        case .apiError(let msg): return "API error: \(msg)"
        }
    }
}
