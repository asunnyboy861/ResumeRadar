import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionVM: SubscriptionViewModel
    @State private var selectedPlan: SubscriptionTier = .proAnnual

    init() {
        let subService = SubscriptionService()
        _subscriptionVM = State(wrappedValue: SubscriptionViewModel(subscriptionService: subService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    planSelector
                    featureComparison
                    subscribeButton
                    restoreButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Upgrade to Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await subscriptionVM.loadProducts()
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles.rosette")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.aiPurple)
            Text("Unlock Full Power")
                .font(.title)
                .fontWeight(.bold)
            Text("Screen unlimited resumes with AI precision")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    private var planSelector: some View {
        VStack(spacing: 12) {
            planCard(
                tier: .proAnnual,
                price: subscriptionVM.annualProduct?.displayPrice ?? "$149.99",
                period: "/year",
                savings: "Save 38%",
                badge: "Best Value"
            )
            planCard(
                tier: .proMonthly,
                price: subscriptionVM.monthlyProduct?.displayPrice ?? "$19.99",
                period: "/month",
                savings: nil,
                badge: nil
            )
        }
    }

    private func planCard(tier: SubscriptionTier, price: String, period: String, savings: String?, badge: String?) -> some View {
        Button {
            selectedPlan = tier
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tier == .proAnnual ? "Pro Annual" : "Pro Monthly")
                            .font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.successGreen)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    if let savings {
                        Text(savings)
                            .font(.caption)
                            .foregroundStyle(AppColors.successGreen)
                    }
                }
                Spacer()
                Text(price)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(period)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(selectedPlan == tier ? AppColors.primaryBlue.opacity(0.08) : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedPlan == tier ? AppColors.primaryBlue : Color(.systemGray4), lineWidth: selectedPlan == tier ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var featureComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What you get")
                .font(.headline)

            featureRow("Unlimited AI screenings", icon: "infinity")
            featureRow("Up to 50 resumes per screening", icon: "doc.on.doc")
            featureRow("Full AI generation detection", icon: "sparkles")
            featureRow("Red flag analysis", icon: "exclamationmark.triangle")
            featureRow("PDF report export", icon: "square.and.arrow.up")
            featureRow("Candidate comparison", icon: "person.2")
            featureRow("Priority processing", icon: "bolt")
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func featureRow(_ text: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(AppColors.primaryBlue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }

    private var subscribeButton: some View {
        Button {
            Task {
                if selectedPlan == .proAnnual {
                    await subscriptionVM.purchaseAnnual()
                } else {
                    await subscriptionVM.purchaseMonthly()
                }
                if subscriptionVM.currentTier != .free {
                    dismiss()
                }
            }
        } label: {
            if subscriptionVM.isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Subscribe to \(selectedPlan == .proAnnual ? "Pro Annual" : "Pro Monthly")")
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await subscriptionVM.restorePurchases() }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}
