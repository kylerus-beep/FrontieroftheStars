import Combine
import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoadingProducts = false

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            products = try await Product.products(for: StoreProductID.allCases.map(\.rawValue))
            await syncEntitlements()
        } catch {
            products = []
        }
    }

    @discardableResult
    func syncEntitlements() async -> Set<String> {
        var owned: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            owned.insert(transaction.productID)
        }
        purchasedProductIDs = owned
        return owned
    }

    func purchase(_ productID: StoreProductID) async -> PurchaseOutcome {
        guard let product = products.first(where: { $0.id == productID.rawValue }) else {
            return .failed("Product not loaded. Add it to StoreKit configuration first.")
        }

        do {
            let result = try await product.purchase()
            switch result {
            case let .success(verification):
                guard case let .verified(transaction) = verification else {
                    return .failed("Purchase verification failed.")
                }
                await transaction.finish()
                purchasedProductIDs.insert(productID.rawValue)
                return .success(productID)
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed("Unknown purchase state.")
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func restorePurchases() async -> Set<String> {
        do {
            try await AppStore.sync()
        } catch {
        }
        return await syncEntitlements()
    }

    func priceLabel(for definition: StoreProductDefinition) -> String {
        products.first(where: { $0.id == definition.id.rawValue })?.displayPrice ?? definition.fallbackPrice
    }
}
