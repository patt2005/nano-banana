import Foundation
import RevenueCat
import SwiftUI
import Combine

final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var isSubscribed: Bool = false
    @Published var customerInfo: CustomerInfo?
    @Published var offerings: Offerings?
    @Published var credits: Int = 0

    private let creditsKey = "userCredits"
    private var isSyncing = false
    private var hasSyncedOnce = false

    private init() {
        checkSubscriptionStatus()
        syncCreditsWithServer()
    }

    private func saveCredits() {
        UserDefaults.standard.set(credits, forKey: creditsKey)
    }

    func updateCredits(_ newCredits: Int) {
        DispatchQueue.main.async {
            self.credits = newCredits
            self.saveCredits()
        }
    }

    func addCredits(_ amount: Int) {
        credits += amount
        saveCredits()
    }

    func useCredits(_ amount: Int) {
        guard credits >= amount else {
            print("⚠️ Not enough credits. Current: \(credits), Required: \(amount)")
            return
        }

        self.credits -= amount
        saveCredits()

        // Update on server
        if let userId = GeminiAPIService.shared.userId {
            APIService.shared.updateUserCredits(userId: userId, credits: -amount) { [weak self] result in
                switch result {
                case .success(let response):
                    if let user = response.user {
                        self?.updateCredits(user.credits)
                    }
                case .failure(let error):
                    print("❌ Failed to update credits on server: \(error)")
                }
            }
        }
    }

    func syncCreditsWithServer() {
        // Prevent multiple simultaneous syncs
        guard !isSyncing else { return }

        // Only sync once per app launch unless forced
        if hasSyncedOnce { return }

        guard let userId = GeminiAPIService.shared.userId else { return }

        isSyncing = true

        APIService.shared.getUserCredits(userId: userId) { [weak self] result in
            guard let self = self else { return }

            self.isSyncing = false
            self.hasSyncedOnce = true

            switch result {
            case .success(let response):
                if let user = response.user {
                    self.updateCredits(user.credits)
                    print("📊 Synced credits from server: \(user.credits)")
                }
            case .failure(let error):
                print("❌ Failed to sync credits: \(error)")
            }
        }
    }

    func forceSyncCredits() {
        hasSyncedOnce = false
        syncCreditsWithServer()
    }
    
    func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { customerInfo, error in
            DispatchQueue.main.async {
                if let customerInfo = customerInfo {
                    self.updateSubscriptionStatus(customerInfo)
                }
            }
        }

        // Also fetch offerings for credit packages
        fetchOfferings()
    }

    func fetchOfferings() {
        Purchases.shared.getOfferings { [weak self] offerings, error in
            DispatchQueue.main.async {
                if let offerings = offerings {
                    self?.offerings = offerings
                }
            }
        }
    }
    
    func updateSubscriptionStatus(_ customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        self.isSubscribed = customerInfo.entitlements.active["Pro"]?.isActive == true
    }
    
    func restorePurchases(completion: @escaping (Bool, Error?) -> Void) {
        Purchases.shared.restorePurchases { customerInfo, error in
            DispatchQueue.main.async {
                if let customerInfo = customerInfo {
                    self.updateSubscriptionStatus(customerInfo)
                    completion(true, nil)
                } else {
                    completion(false, error)
                }
            }
        }
    }
    
    var hasActiveSubscription: Bool {
        return isSubscribed
    }

    func purchaseCreditsPackage(packageId: String, completion: @escaping (Bool, Int, Error?) -> Void) {
        guard let offerings = offerings,
              let currentOffering = offerings.current else {
            completion(false, 0, NSError(domain: "SubscriptionManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No packages available"]))
            return
        }

        // Find the package by identifier
        guard let package = currentOffering.availablePackages.first(where: { pkg in
            pkg.storeProduct.productIdentifier == packageId
        }) else {
            completion(false, 0, NSError(domain: "SubscriptionManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Package not found"]))
            return
        }

        Purchases.shared.purchase(package: package) { [weak self] transaction, customerInfo, error, userCancelled in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, 0, error)
                } else if userCancelled {
                    completion(false, 0, NSError(domain: "SubscriptionManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Purchase cancelled"]))
                } else if transaction != nil {
                    // Extract credits amount from package identifier or metadata
                    let creditsAmount = self?.getCreditsAmountFromPackageId(packageId) ?? 0

                    // Add credits to local storage
                    self?.addCredits(creditsAmount)

                    // Update customer info
                    if let customerInfo = customerInfo {
                        self?.updateSubscriptionStatus(customerInfo)
                    }

                    completion(true, creditsAmount, nil)
                }
            }
        }
    }

    private func getCreditsAmountFromPackageId(_ packageId: String) -> Int {
        // Extract credits amount based on product ID
        switch packageId {
        case "com.nanobanana.credits10":
            return 85  // Starter pack - 85 credits
        case "com.nanobanana.credits20":
            return 500  // Good value - 500 credits
        case "com.nanobanana.credits30":
            return 650  // Great value - 650 credits
        case "com.nanobanana.credits60":
            return 1500  // Best value package - 1500 credits
        default:
            return 0
        }
    }

    func getPackagePrice(for productId: String) -> String? {
        guard let offerings = offerings,
              let currentOffering = offerings.current else {
            return nil
        }

        if let package = currentOffering.availablePackages.first(where: { pkg in
            pkg.storeProduct.productIdentifier == productId
        }) {
            return package.localizedPriceString
        }

        return nil
    }

    func handleSubscriptionPurchase(customerInfo: CustomerInfo) {
        // Update subscription status
        updateSubscriptionStatus(customerInfo)

        // Add credits based on subscription type
        for (_, entitlement) in customerInfo.entitlements.active {
            let productIdentifier = entitlement.productIdentifier
            switch productIdentifier {
                case "com.nano.ai.weekly":
                    // Add 130 credits for weekly subscription
                    addCredits(130)
                    print("✅ Added 130 credits for weekly subscription")

                    // Sync with backend
                    if let userId = GeminiAPIService.shared.userId {
                        APIService.shared.updateUserCredits(userId: userId, credits: 130) { _ in }
                    }

                case "com.nano.ai.yearly":
                    // Add 1200 credits for yearly subscription
                    addCredits(1200)
                    print("✅ Added 1200 credits for yearly subscription")

                    // Sync with backend
                    if let userId = GeminiAPIService.shared.userId {
                        APIService.shared.updateUserCredits(userId: userId, credits: 1200) { _ in }
                    }

                default:
                    break
            }
        }
    }
}
