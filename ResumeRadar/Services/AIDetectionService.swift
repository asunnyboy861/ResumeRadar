import Foundation
import NaturalLanguage

struct AIDetectionService {
    static func analyze(text: String) -> AIDetectionResult {
        let buzzwordScore = detectBuzzwords(in: text)
        let varianceScore = calculateSentenceVariance(in: text)
        let diversityScore = calculateVocabularyDiversity(in: text)
        let formattingScore = detectFormattingConsistency(in: text)

        let weights: [Double] = [0.30, 0.25, 0.25, 0.20]
        let weightedScore = buzzwordScore * weights[0]
            + varianceScore * weights[1]
            + diversityScore * weights[2]
            + formattingScore * weights[3]

        let probability = min(max(weightedScore * 100, 0), 100)
        let confidence: AIDetectionConfidence
        switch probability {
        case 0..<25: confidence = .low
        case 25..<55: confidence = .medium
        default: confidence = .high
        }

        var indicators: [AIIndicator] = []
        if buzzwordScore > 0.4 {
            indicators.append(AIIndicator(type: .buzzword, score: buzzwordScore, detail: "High concentration of AI-typical phrases"))
        }
        if varianceScore > 0.4 {
            indicators.append(AIIndicator(type: .lowVariance, score: varianceScore, detail: "Uniform sentence structure detected"))
        }
        if diversityScore > 0.4 {
            indicators.append(AIIndicator(type: .lowDiversity, score: diversityScore, detail: "Limited vocabulary variety"))
        }
        if formattingScore > 0.4 {
            indicators.append(AIIndicator(type: .perfectFormatting, score: formattingScore, detail: "Suspiciously perfect formatting"))
        }

        return AIDetectionResult(
            probability: probability,
            confidence: confidence,
            indicators: indicators
        )
    }

    private static func detectBuzzwords(in text: String) -> Double {
        let aiPhrases = [
            "leverage synergies", "cross-functional teams", "drive innovation",
            "streamline processes", "spearheaded initiatives", "paradigm shift",
            "synergistic approach", "holistic strategy", "transformative leadership",
            "results-driven", "data-driven decision making", "thought leadership",
            "stakeholder engagement", "value proposition", "best-in-class",
            "cutting-edge", "next-generation", "scalable solutions",
            "robust framework", "seamless integration", "dynamic environment",
            "passionate about", "proven track record", "excellent communication skills",
            "detail-oriented", "self-starter", "team player"
        ]
        let lowercased = text.lowercased()
        var count = 0
        for phrase in aiPhrases {
            if lowercased.contains(phrase) { count += 1 }
        }
        return min(Double(count) / 8.0, 1.0)
    }

    private static func calculateSentenceVariance(in text: String) -> Double {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.count > 10 }
        guard sentences.count >= 3 else { return 0.0 }
        let lengths = sentences.map { Double($0.count) }
        let mean = lengths.reduce(0, +) / Double(lengths.count)
        guard mean > 0 else { return 0.0 }
        let variance = lengths.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(lengths.count)
        let cv = sqrt(variance) / mean
        return max(0, 1.0 - cv)
    }

    private static func calculateVocabularyDiversity(in text: String) -> Double {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var words: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let word = String(text[range]).lowercased()
            if word.count > 2 { words.append(word) }
            return true
        }
        guard words.count > 20 else { return 0.0 }
        let uniqueWords = Set(words)
        let ttr = Double(uniqueWords.count) / Double(words.count)
        return max(0, 1.0 - ttr)
    }

    private static func detectFormattingConsistency(in text: String) -> Double {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count >= 5 else { return 0.0 }
        let bulletLines = lines.filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("•") || $0.trimmingCharacters(in: .whitespaces).hasPrefix("-") || $0.trimmingCharacters(in: .whitespaces).hasPrefix("•") }
        let bulletRatio = Double(bulletLines.count) / Double(lines.count)
        if bulletRatio > 0.7 { return 0.6 }
        let lineLengths = lines.map { $0.count }
        let avgLength = Double(lineLengths.reduce(0, +)) / Double(lineLengths.count)
        let consistentLines = lineLengths.filter { abs($0 - Int(avgLength)) < 20 }
        let consistencyRatio = Double(consistentLines.count) / Double(lines.count)
        return consistencyRatio > 0.8 ? 0.5 : 0.0
    }
}

enum AIDetectionConfidence: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

struct AIDetectionResult {
    let probability: Double
    let confidence: AIDetectionConfidence
    let indicators: [AIIndicator]
}

struct AIIndicator {
    let type: RedFlagType
    let score: Double
    let detail: String
}
