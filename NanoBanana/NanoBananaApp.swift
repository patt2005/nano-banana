import SwiftUI
import RevenueCat
import RevenueCatUI

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Purchases.configure(withAPIKey: "appl_CYOwnNCHgAIvgkQKOrESStgwXJy", appUserID: GeminiAPIService.shared.userId)
        
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            DispatchQueue.main.async {
                if let customerInfo = customerInfo {
                    SubscriptionManager.shared.updateSubscriptionStatus(customerInfo)
                }
            }
        }

        // Fetch offerings for credit packages
        SubscriptionManager.shared.fetchOfferings()

        return true
    }
}

@main
struct NanoBananaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            AppView()
        }
    }
}
