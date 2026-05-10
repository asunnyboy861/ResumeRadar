import SwiftUI
import SwiftData

struct ResultsView: View {
    let job: JobDescription
    @Environment(\.modelContext) private var modelContext
    @State private var candidateListVM = CandidateListViewModel()
    @State private var selectedCandidate: Candidate?
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            candidateList
        }
        .navigationTitle(job.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedCandidate) { candidate in
            CandidateDetailView(candidate: candidate, job: job)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: candidateListVM.filterStatus == nil) {
                    candidateListVM.filterStatus = nil
                }
                ForEach(CandidateStatus.allCases) { status in
                    FilterChip(title: status.displayName, isSelected: candidateListVM.filterStatus == status) {
                        candidateListVM.filterStatus = status
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var candidateList: some View {
        let filtered = candidateListVM.filteredCandidates(from: job.candidates)
        return List {
            ForEach(filtered) { candidate in
                Button {
                    if candidate.aiGeneratedProbability > 30 || candidate.status == .pending {
                        selectedCandidate = candidate
                    } else {
                        selectedCandidate = candidate
                    }
                } label: {
                    SwipeCardView(
                        candidate: candidate,
                        onShortlist: {
                            candidateListVM.updateStatus(candidate, to: .shortlisted, modelContext: modelContext)
                        },
                        onReject: {
                            candidateListVM.updateStatus(candidate, to: .rejected, modelContext: modelContext)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView("No Candidates", systemImage: "person.crop.circle.badge.questionmark", description: Text("Upload resumes to start screening"))
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? AppColors.primaryBlue : Color(.systemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }
}
