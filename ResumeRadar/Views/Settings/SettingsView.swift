import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var subscriptionService = SubscriptionService()
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                subscriptionSection
                screeningUsageSection
                aiConfigurationSection
                supportSection
                legalSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    private var subscriptionSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscriptionService.subscriptionStatus.displayName)
                        .font(.headline)
                    Text(subscriptionService.subscriptionStatus.price)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if subscriptionService.subscriptionStatus == .free {
                    Button("Upgrade") {
                        showPaywall = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            if subscriptionService.subscriptionStatus != .free {
                Button("Manage Subscription") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }

                Button("Restore Purchases") {
                    Task { await subscriptionService.restorePurchases() }
                }
            }
        } header: {
            Text("Subscription")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var screeningUsageSection: some View {
        Section {
            HStack {
                Text("Screenings Used")
                Spacer()
                Text("\(subscriptionService.screeningsUsedThisMonth) / \(subscriptionService.subscriptionStatus == .free ? AppConstants.freeMonthlyScreenings : AppConstants.proMonthlyScreenings)")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Usage This Month")
        }
    }

    private var aiConfigurationSection: some View {
        Section {
            NavigationLink {
                AIConfigView()
            } label: {
                Label("AI Configuration", systemImage: "gearshape")
            }
        } header: {
            Text("AI Settings")
        }
    }

    private var supportSection: some View {
        Section {
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }
        } header: {
            Text("Support")
        }
    }

    private var legalSection: some View {
        Section {
            Link("Privacy Policy", destination: URL(string: "https://asunnyboy861.github.io/ResumeRadar/privacy.html")!)
            Link("Terms of Use", destination: URL(string: "https://asunnyboy861.github.io/ResumeRadar/terms.html")!)
            Link("Support Page", destination: URL(string: "https://asunnyboy861.github.io/ResumeRadar/support.html")!)
        } header: {
            Text("Legal")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("About")
        }
    }
}

struct AIConfigView: View {
    @AppStorage("ai_api_key") private var apiKey: String = ""
    @AppStorage("ai_base_url") private var baseURL: String = "https://api.openai.com/v1"
    @AppStorage("ai_model") private var model: String = "gpt-4o-mini"

    var body: some View {
        Form {
            Section {
                TextField("API Key", text: $apiKey)
                    .textContentType(.password)
                TextField("Base URL", text: $baseURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("Model", text: $model)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("OpenAI Configuration")
            } footer: {
                Text("Your API key is stored locally on this device only.")
                    .font(.caption2)
            }
        }
        .navigationTitle("AI Configuration")
    }
}
