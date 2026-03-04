import StoreKit

/// StoreKit 2 integration for purchasing cosmetics and gem packs.
@Observable
final class StoreService {

    private(set) var products: [Product] = []
    private(set) var purchasedProductIds: Set<String> = []
    private(set) var isLoading = false

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Public API

    /// Fetches available products from the App Store.
    func fetchProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: Self.productIds)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("[StoreService] Failed to fetch products: \(error)")
        }
    }

    /// Initiates a purchase for the given product ID.
    /// - Returns: The purchased product ID if successful, nil otherwise.
    @discardableResult
    func purchase(productId: String) async -> String? {
        guard let product = products.first(where: { $0.id == productId }) else { return nil }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                purchasedProductIds.insert(transaction.productID)
                await transaction.finish()
                return transaction.productID
            case .userCancelled, .pending:
                return nil
            @unknown default:
                return nil
            }
        } catch {
            print("[StoreService] Purchase failed: \(error)")
            return nil
        }
    }

    /// Restores all previously purchased non-consumable products.
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchasedProductIds.insert(transaction.productID)
            }
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? self?.checkVerified(result) {
                    self?.purchasedProductIds.insert(transaction.productID)
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    // MARK: - Product IDs

    static let productIds: Set<String> = [
        "com.geoquest.gems.small",
        "com.geoquest.gems.medium",
        "com.geoquest.gems.large",
        "com.geoquest.skin.knight",
        "com.geoquest.skin.pirate",
        "com.geoquest.skin.space",
    ]
}
