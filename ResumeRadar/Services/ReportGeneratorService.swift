import PDFKit

struct ReportGeneratorService {
    static func generatePDF(candidate: Candidate, job: JobDescription) -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            context.beginPage()

            var y: CGFloat = margin

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.systemBlue
            ]
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.darkGray
            ]
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]

            "ResumeRadar Screening Report".draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttributes)
            y += 35

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            "Generated: \(dateFormatter.string(from: Date()))".draw(at: CGPoint(x: margin, y: y), withAttributes: bodyAttributes)
            y += 30

            let separator = CGRect(x: margin, y: y, width: contentWidth, height: 1)
            UIColor.lightGray.setFill()
            UIRectFill(separator)
            y += 15

            "Job Position: \(job.title)".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
            y += 25

            "Candidate: \(candidate.name)".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
            y += 25

            if !candidate.email.isEmpty {
                "Email: \(candidate.email)".draw(at: CGPoint(x: margin, y: y), withAttributes: bodyAttributes)
                y += 20
            }

            y += 10
            "Overall Match Score".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
            y += 22
            "\(Int(candidate.overallScore))/100".draw(at: CGPoint(x: margin, y: y), withAttributes: [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: scoreColor(candidate.overallScore)
            ])
            y += 40

            "Score Breakdown".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
            y += 22
            let scores = [
                ("Skills Match", candidate.skillMatchScore),
                ("Experience Match", candidate.experienceMatchScore),
                ("Education Match", candidate.educationMatchScore),
                ("Culture Fit", candidate.cultureFitScore)
            ]
            for (label, score) in scores {
                "\(label): \(Int(score))/100".draw(at: CGPoint(x: margin, y: y), withAttributes: bodyAttributes)
                y += 18
            }
            y += 10

            if !candidate.matchedSkills.isEmpty {
                "Matched Skills".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
                y += 22
                candidate.matchedSkills.joined(separator: ", ").draw(at: CGPoint(x: margin, y: y), withAttributes: bodyAttributes)
                y += 20
            }

            if !candidate.missingSkills.isEmpty {
                "Missing Skills".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
                y += 22
                candidate.missingSkills.joined(separator: ", ").draw(at: CGPoint(x: margin, y: y), withAttributes: bodyAttributes)
                y += 20
            }

            if !candidate.strengths.isEmpty {
                y += 5
                "Strengths".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
                y += 22
                for strength in candidate.strengths {
                    "• \(strength)".draw(at: CGPoint(x: margin + 10, y: y), withAttributes: bodyAttributes)
                    y += 18
                }
            }

            if !candidate.weaknesses.isEmpty {
                y += 5
                "Areas of Concern".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
                y += 22
                for weakness in candidate.weaknesses {
                    "• \(weakness)".draw(at: CGPoint(x: margin + 10, y: y), withAttributes: bodyAttributes)
                    y += 18
                }
            }

            if candidate.aiGeneratedProbability > 30 {
                y += 5
                "AI Generation Detection".draw(at: CGPoint(x: margin, y: y), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                    .foregroundColor: UIColor.systemPurple
                ])
                y += 22
                "AI Probability: \(Int(candidate.aiGeneratedProbability))%".draw(at: CGPoint(x: margin, y: y), withAttributes: bodyAttributes)
                y += 18
            }

            if !candidate.aiSummary.isEmpty {
                y += 5
                "AI Summary".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
                y += 22
                candidate.aiSummary.draw(at: CGPoint(x: margin, y: y), withAttributes: bodyAttributes)
            }
        }

        return data.count > 0 ? data : nil
    }

    private static func scoreColor(_ score: Double) -> UIColor {
        switch score {
        case 80...100: return UIColor.systemGreen
        case 40..<80: return UIColor.systemOrange
        default: return UIColor.systemRed
        }
    }
}
