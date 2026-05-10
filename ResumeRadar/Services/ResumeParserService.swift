import Foundation
import NaturalLanguage

struct ResumeParserService {
    static func parse(text: String) -> ParsedResume {
        let name = extractName(from: text)
        let email = extractEmail(from: text)
        let phone = extractPhone(from: text)
        let skills = extractSkills(from: text)
        let experienceYears = extractExperienceYears(from: text)
        let education = extractEducation(from: text)
        return ParsedResume(
            name: name,
            email: email,
            phone: phone,
            skills: skills,
            experienceYears: experienceYears,
            education: education,
            rawText: text
        )
    }

    private static func extractName(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let firstLine = lines.first else { return "Unknown" }
        let cleaned = firstLine.trimmingCharacters(in: .whitespaces)
        if cleaned.count > 60 { return "Unknown" }
        let namePattern = "^[A-Z][a-z]+(?:\\s[A-Z][a-z]+)+$"
        if cleaned.range(of: namePattern, options: .regularExpression) != nil {
            return cleaned
        }
        return cleaned.count <= 40 ? cleaned : "Unknown"
    }

    private static func extractEmail(from text: String) -> String {
        let pattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        guard let range = text.range(of: pattern, options: .regularExpression) else { return "" }
        return String(text[range])
    }

    private static func extractPhone(from text: String) -> String {
        let pattern = "(?:\\+1[-.\\s]?)?\\(?\\d{3}\\)?[-.\\s]?\\d{3}[-.\\s]?\\d{4}"
        guard let range = text.range(of: pattern, options: .regularExpression) else { return "" }
        return String(text[range])
    }

    private static func extractSkills(from text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        let lowercased = text.lowercased()
        let commonSkills = [
            "python", "java", "javascript", "typescript", "swift", "kotlin", "c++", "c#", "ruby", "go", "rust",
            "react", "angular", "vue", "node.js", "django", "flask", "spring", "docker", "kubernetes",
            "aws", "azure", "gcp", "sql", "mongodb", "postgresql", "redis", "git", "ci/cd",
            "machine learning", "deep learning", "nlp", "data analysis", "project management",
            "agile", "scrum", "leadership", "communication", "problem solving",
            "html", "css", "rest api", "graphql", "figma", "photoshop", "excel",
            "salesforce", "sap", "tableau", "power bi", "jira", "confluence"
        ]
        var found: [String] = []
        for skill in commonSkills {
            if lowercased.contains(skill) {
                found.append(skill)
            }
        }
        return found
    }

    private static func extractExperienceYears(from text: String) -> Int {
        let patterns = [
            "(\\d+)\\+?\\s+years?\\s+(?:of\\s+)?experience",
            "experience[:\\s]+(\\d+)\\+?\\s+years?",
            "(\\d+)\\+?\\s+yrs?\\s+(?:of\\s+)?exp"
        ]
        for pattern in patterns {
            if let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let match = String(text[range])
                if let years = match.components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .compactMap({ Int($0) }).first {
                    return years
                }
            }
        }
        return 0
    }

    private static func extractEducation(from text: String) -> String {
        let degrees = ["PhD", "Ph.D", "Doctorate", "MBA", "Master", "M.S.", "M.A.", "MSc", "Bachelor", "B.S.", "B.A.", "BSc", "Associate"]
        let lowercased = text.lowercased()
        for degree in degrees {
            if lowercased.contains(degree.lowercased()) {
                return degree
            }
        }
        return ""
    }
}

struct ParsedResume {
    let name: String
    let email: String
    let phone: String
    let skills: [String]
    let experienceYears: Int
    let education: String
    let rawText: String
}
