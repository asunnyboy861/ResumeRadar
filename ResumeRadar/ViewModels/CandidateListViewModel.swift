import Foundation
import SwiftData

@MainActor
@Observable
final class CandidateListViewModel {
    var filterStatus: CandidateStatus? = nil
    var searchText: String = ""

    func filteredCandidates(from candidates: [Candidate]) -> [Candidate] {
        var result = candidates.sorted { $0.overallScore > $1.overallScore }
        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    func updateStatus(_ candidate: Candidate, to status: CandidateStatus, modelContext: ModelContext) {
        candidate.status = status
        try? modelContext.save()
    }

    func generateReport(candidate: Candidate, job: JobDescription) -> Data? {
        ReportGeneratorService.generatePDF(candidate: candidate, job: job)
    }
}
