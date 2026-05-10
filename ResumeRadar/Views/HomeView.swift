import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var selectedTab: Int
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JobDescription.createdAt, order: .reverse) private var jobs: [JobDescription]
    @State private var showNewScreening = false
    @State private var selectedJob: JobDescription?
    @AppStorage("ai_api_key") private var apiKey: String = ""
    @State private var showAPIKeyAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    if apiKey.isEmpty {
                        apiKeyBanner
                    }
                    quickActionsSection
                    if !jobs.isEmpty {
                        recentJobsSection
                    } else {
                        emptyStateSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ResumeRadar")
            .sheet(isPresented: $showNewScreening) {
                JobInputView()
            }
            .navigationDestination(item: $selectedJob) { job in
                ResultsView(job: job)
            }
            .alert("Configure AI Key", isPresented: $showAPIKeyAlert) {
                Button("Settings") {
                    selectedTab = 1
                }
                Button("Later", role: .cancel) {}
            } message: {
                Text("To use AI screening features, add your OpenAI API key in Settings > AI Configuration.")
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Screen Smarter")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("AI-powered resume screening in minutes, not hours")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var apiKeyBanner: some View {
        Button {
            showAPIKeyAlert = true
        } label: {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundStyle(AppColors.warningYellow)
                Text("Add your OpenAI API key to enable AI screening")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(AppColors.warningYellow.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.warningYellow.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            QuickActionCard(
                icon: "doc.text.magnifyingglass",
                title: "New Screening",
                subtitle: "Start AI resume analysis",
                color: AppColors.primaryBlue
            ) { showNewScreening = true }

            QuickActionCard(
                icon: "chart.bar",
                title: "Recent Jobs",
                subtitle: "\(jobs.count) active positions",
                color: AppColors.aiPurple
            ) {
                if let firstJob = jobs.first {
                    selectedJob = firstJob
                }
            }
        }
    }

    private var recentJobsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Screenings")
                .font(.headline)

            ForEach(jobs.prefix(5)) { job in
                Button {
                    selectedJob = job
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(job.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            HStack(spacing: 8) {
                                Text("\(job.candidates.count) candidates")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                let shortlisted = job.candidates.filter { $0.status == .shortlisted }.count
                                if shortlisted > 0 {
                                    Text("\(shortlisted) shortlisted")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.successGreen)
                                }
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.primaryBlue.opacity(0.5))
            Text("No screenings yet")
                .font(.headline)
            Text("Create your first screening job to start analyzing resumes with AI")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Start Screening") {
                showNewScreening = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 40)
    }
}
