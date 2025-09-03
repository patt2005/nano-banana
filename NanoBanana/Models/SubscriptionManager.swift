import Foundation
import RevenueCat
import SwiftUI
import Combine

final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isSubscribed: Bool = false
    @Published var customerInfo: CustomerInfo?
    @Published var offerings: Offerings?
    
    private init() {
        checkSubscriptionStatus()
    }
    
    // MARK: - Subscription Status
    func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { customerInfo, error in
            DispatchQueue.main.async {
                if let customerInfo = customerInfo {
                    self.updateSubscriptionStatus(customerInfo)
                }
            }
        }
    }
    
    func updateSubscriptionStatus(_ customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
        self.isSubscribed = customerInfo.entitlements.active["pro"]?.isActive == true
    }
    
    // MARK: - Purchase Methods
    func purchase(_ package: Package, completion: @escaping (Bool, Error?) -> Void) {
        Purchases.shared.purchase(package: package) { transaction, customerInfo, error, userCancelled in
            DispatchQueue.main.async {
                if let customerInfo = customerInfo {
                    self.updateSubscriptionStatus(customerInfo)
                    completion(true, nil)
                } else if let error = error {
                    completion(false, error)
                } else if userCancelled {
                    completion(false, nil)
                }
            }
        }
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
    
    // MARK: - Offerings
    func loadOfferings() {
        Purchases.shared.getOfferings { offerings, error in
            DispatchQueue.main.async {
                if let offerings = offerings {
                    self.offerings = offerings
                }
            }
        }
    }
    
    // MARK: - Convenience Methods
    var hasActiveSubscription: Bool {
        return isSubscribed
    }
    
    var proEntitlement: EntitlementInfo? {
        return customerInfo?.entitlements.active["pro"]
    }
}