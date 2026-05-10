import Foundation
import StoreKit

@MainActor
@Observable
final class SubscriptionViewModel {
    var monthlyProduct: Product?
    var annualProduct: Product?
    var isLoading = false
    var purchaseError: String?

    private let subscriptionService: SubscriptionService

    init(subscriptionService: SubscriptionService) {
        self.subscriptionService = subscriptionService
    }

    var currentTier: SubscriptionTier {
        subscriptionService.subscriptionStatus
    }

    func loadProducts() async {
        isLoading = true
        do {
            let productIDs = [AppConstants.monthlyProductID, AppConstants.annualProductID]
            let products = try await Product.products(for: productIDs)
            for product in products {
                if product.id == AppConstants.monthlyProductID {
                    monthlyProduct = product
                } else if product.id == AppConstants.annualProductID {
                    annualProduct = product
                }
            }
        } catch {
            purchaseError = error.localizedDescription
        }
        isLoading = false
    }

    func purchaseMonthly() async {
        purchaseError = nil
        do {
            try await subscriptionService.purchase(AppConstants.monthlyProductID)
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func purchaseAnnual() async {
        purchaseError = nil
        do {
            try await subscriptionService.purchase(AppConstants.annualProductID)
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        await subscriptionService.restorePurchases()
    }
}
