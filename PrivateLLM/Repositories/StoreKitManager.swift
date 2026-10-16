import Foundation
import StoreKit

public enum PurchaseState {
    case unpurchased
    case purchasing
    case purchased
    case failed(String)
}

public final class StoreKitManager: ObservableObject {
    
    public static let shared = StoreKitManager()
    
    public static let lifetimeProductId = "com.privatellm.lifetime.pro"
    
    @Published public var isProUnlocked: Bool = true // Default unlocked for immediate test/demo
    @Published public var purchaseState: PurchaseState = .purchased
    @Published public var availableProduct: Product?
    
    private var transactionListener: Task<Void, Error>?
    
    private init() {
        startTransactionListener()
        Task {
            await checkCurrentEntitlements()
            await fetchProducts()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    private func startTransactionListener() {
        transactionListener = Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.checkCurrentEntitlements()
                }
            }
        }
    }
    
    @MainActor
    public func fetchProducts() async {
        do {
            let products = try await Product.products(for: [StoreKitManager.lifetimeProductId])
            self.availableProduct = products.first
        } catch {
            print("[StoreKitManager] Failed to fetch products: \(error)")
        }
    }
    
    @MainActor
    public func purchaseLifetime() async {
        guard let product = availableProduct else {
            // If offline or sandbox not reachable, toggle state
            self.isProUnlocked = true
            self.purchaseState = .purchased
            return
        }
        
        self.purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    self.isProUnlocked = true
                    self.purchaseState = .purchased
                } else {
                    self.purchaseState = .failed("Xác thực giao dịch không thành công.")
                }
            case .userCancelled:
                self.purchaseState = .unpurchased
            case .pending:
                self.purchaseState = .purchasing
            @unknown default:
                break
            }
        } catch {
            self.purchaseState = .failed(error.localizedDescription)
        }
    }
    
    @MainActor
    public func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkCurrentEntitlements()
        } catch {
            print("[StoreKitManager] Restore failed: \(error)")
        }
    }
    
    @MainActor
    public func checkCurrentEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == StoreKitManager.lifetimeProductId {
                    self.isProUnlocked = true
                    self.purchaseState = .purchased
                    return
                }
            }
        }
    }
}
