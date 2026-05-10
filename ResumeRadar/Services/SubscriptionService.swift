import Foundation
import StoreKit

@MainActor
@Observable
final class SubscriptionService {
    var subscriptionStatus: SubscriptionTier = .free
    var screeningsUsedThisMonth: Int = 0
    var isLoading = false

    private var _transactionListener: Task<Void, Never>?

    init() {
        _transactionListener = listenForTransactions()
        Task { await checkCurrentSubscription() }
        loadUsageData()
    }

    nonisolated deinit {
        Task { @MainActor in
            _transactionListener?.cancel()
        }
    }

    var canScreen: Bool {
        switch subscriptionStatus {
        case .free: return screeningsUsedThisMonth < AppConstants.freeMonthlyScreenings
        case .proMonthly: return screeningsUsedThisMonth < AppConstants.proMonthlyScreenings
        case .proAnnual: return screeningsUsedThisMonth < AppConstants.proAnnualScreenings
        }
    }

    var maxResumesPerScreening: Int {
        switch subscriptionStatus {
        case .free: return AppConstants.freeMaxResumesPerScreening
        case .proMonthly, .proAnnual: return AppConstants.proMaxResumesPerScreening
        }
    }

    var maxActiveJobs: Int {
        switch subscriptionStatus {
        case .free: return AppConstants.freeMaxActiveJobs
        case .proMonthly, .proAnnual: return .max
        }
    }

    func incrementScreeningUsage() {
        screeningsUsedThisMonth += 1
        saveUsageData()
    }

    func purchase(_ productID: String) async throws {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else { return }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await updateSubscriptionStatus(transaction)
                await transaction.finish()
            }
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkCurrentSubscription()
        } catch {}
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self?.updateSubscriptionStatus(transaction)
                    await transaction.finish()
                }
            }
        }
    }

    private func checkCurrentSubscription() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                await updateSubscriptionStatus(transaction)
            }
        }
    }

    private func updateSubscriptionStatus(_ transaction: Transaction) {
        if transaction.productID == AppConstants.monthlyProductID {
            subscriptionStatus = .proMonthly
        } else if transaction.productID == AppConstants.annualProductID {
            subscriptionStatus = .proAnnual
        }
    }

    private func loadUsageData() {
        let calendar = Calendar.current
        let now = Date()
        let savedMonth = UserDefaults.standard.integer(forKey: "usage_month")
        let savedYear = UserDefaults.standard.integer(forKey: "usage_year")
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        if savedMonth == currentMonth && savedYear == currentYear {
            screeningsUsedThisMonth = UserDefaults.standard.integer(forKey: "screenings_used")
        } else {
            screeningsUsedThisMonth = 0
            UserDefaults.standard.set(currentMonth, forKey: "usage_month")
            UserDefaults.standard.set(currentYear, forKey: "usage_year")
            UserDefaults.standard.set(0, forKey: "screenings_used")
        }
    }

    private func saveUsageData() {
        UserDefaults.standard.set(screeningsUsedThisMonth, forKey: "screenings_used")
    }
}

enum SubscriptionTier: String, CaseIterable {
    case free = "free"
    case proMonthly = "pro_monthly"
    case proAnnual = "pro_annual"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .proMonthly: return "Pro Monthly"
        case .proAnnual: return "Pro Annual"
        }
    }

    var price: String {
        switch self {
        case .free: return "Free"
        case .proMonthly: return "$19.99/mo"
        case .proAnnual: return "$149.99/yr"
        }
    }
}
