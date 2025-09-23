import SwiftUI
import RevenueCat
import RevenueCatUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingChat = false
    @ObservedObject private var appManager = AppManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Group {
                        switch selectedTab {
                        case 0:
                            HomePage()
                        case 1:
                            GalleryPage()
                        default:
                            HomePage()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Bottom Navigation
                    BottomNavigationBar(
                        selectedTab: $selectedTab,
                        onAddTapped: {
                            // No longer used
                        }
                    )
                    .ignoresSafeArea(.all, edges: .bottom)
                }

                // Floating Action Button
                VStack {
                    Spacer()

                    Button(action: {
                        showingChat = true
                    }) {
                        ZStack {
                            // Shadow layer
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.yellow,
                                            Color.yellow.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: .yellow.opacity(0.4), radius: 10, x: 0, y: 5)
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)

                            // Icon
                            Image("bubble-chat")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .foregroundColor(.black)
                        }
                    }
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showingChat)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showingChat) {
                ChatPage()
            }
            .fullScreenCover(isPresented: $appManager.showPaywall) {
                PaywallView()
                    .onPurchaseCompleted { customerInfo in
                        // Update subscription status
                        subscriptionManager.updateSubscriptionStatus(customerInfo)

                        // Add credits based on subscription type
                        handleSubscriptionCredits(customerInfo)

                        // Fetch offerings and dismiss
                        subscriptionManager.fetchOfferings()
                        appManager.dismissPaywall()
                    }
                    .onRestoreCompleted { customerInfo in
                        // Update subscription status
                        subscriptionManager.updateSubscriptionStatus(customerInfo)

                        // Check and add credits if needed
                        handleSubscriptionCredits(customerInfo)

                        // Fetch offerings and dismiss
                        subscriptionManager.fetchOfferings()
                        appManager.dismissPaywall()
                    }
            }
        }
    }

    private func handleSubscriptionCredits(_ customerInfo: CustomerInfo) {
        // Check active subscriptions and add credits based on the package type
        for (_, entitlement) in customerInfo.entitlements.active {
            let productIdentifier = entitlement.productIdentifier
            switch productIdentifier {
            case "com.nano.ai.weekly":
                // Weekly subscription - add 125 credits
                if !hasReceivedCreditsForPurchase(productIdentifier, date: entitlement.latestPurchaseDate) {
                    subscriptionManager.addCredits(125)
                    markCreditsReceived(productIdentifier, date: entitlement.latestPurchaseDate)
                    print("✅ Added 125 credits for weekly subscription")
                }

            case "com.nano.ai.yearly":
                // Yearly subscription - add 1000 credits
                if !hasReceivedCreditsForPurchase(productIdentifier, date: entitlement.latestPurchaseDate) {
                    subscriptionManager.addCredits(1000)
                    markCreditsReceived(productIdentifier, date: entitlement.latestPurchaseDate)
                    print("✅ Added 1000 credits for yearly subscription")
                }

            default:
                // Handle any other subscription types if needed
                print("📦 Unknown subscription type: \(productIdentifier)")
            }
        }
    }

    private func hasReceivedCreditsForPurchase(_ productId: String, date: Date?) -> Bool {
        // Check if we've already given credits for this specific purchase
        guard let date = date else { return false }
        let key = "credits_received_\(productId)_\(date.timeIntervalSince1970)"
        return UserDefaults.standard.bool(forKey: key)
    }

    private func markCreditsReceived(_ productId: String, date: Date?) {
        // Mark that we've given credits for this purchase
        guard let date = date else { return }
        let key = "credits_received_\(productId)_\(date.timeIntervalSince1970)"
        UserDefaults.standard.set(true, forKey: key)
    }
}
