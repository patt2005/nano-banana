import SwiftUI
import RevenueCat
import RevenueCatUI

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Purchases.configure(withAPIKey: "appl_CYOwnNCHgAIvgkQKOrESStgwXJy")

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
