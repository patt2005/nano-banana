import SwiftUI
import StoreKit
import RevenueCatUI

struct OnboardingInfo {
    let imageAsset: String
    let title: String
    let subtitle: String
}

struct VisualOnboardingView: View {
    @ObservedObject private var appManager = AppManager.shared
    @ObservedObject private var apiService = GeminiAPIService.shared
    @State private var currentPage = 0
    @State private var showingPaywall = false
    @Environment(\.requestReview) var requestReview

    let onboardingPages = [
        OnboardingInfo(
            imageAsset: "1",
            title: "Express Your Style",
            subtitle: "Transform your photos instantly with AI-powered fashion and style enhancements"
        ),
        OnboardingInfo(
            imageAsset: "2",
            title: "Background Remover",
            subtitle: "Instantly remove and replace photo backgrounds with AI precision"
        ),
        OnboardingInfo(
            imageAsset: "3",
            title: "AI Figure Creator",
            subtitle: "Turn yourself into viral collectible dolls and action figures with trending AI styles perfect for social media"
        ),
        OnboardingInfo(
            imageAsset: "4",
            title: "AI Cartoonify",
            subtitle: "Transform your photos into stunning cartoon and anime-style artwork"
        ),
        OnboardingInfo(
            imageAsset: "5",
            title: "Restore Old Photos",
            subtitle: "Bring memories back to life by restoring damaged and faded photographs"
        )
    ]

    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .ignoresSafeArea(.all)

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        let page = onboardingPages[index]

                        VStack {
                            ZStack(alignment: .bottom) {
                                Image(page.imageAsset)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.6)
                                    .clipped()

                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0),
                                        Color.black.opacity(0.3),
                                        Color.black.opacity(0.7),
                                        Color.black.opacity(0.9),
                                        Color.black
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 150)
                            }
                            .tag(index)
                            .onAppear {
                                // Request review on the last page
                                if index == onboardingPages.count - 1 {
                                    requestReview()
                                }
                            }
                            .padding(.top, UIScreen.main.bounds.height * -0.13)
                            
                            Spacer()
                            
                            Text(page.title)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)

                            Text(page.subtitle)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 50)
                                .padding(.bottom, 80)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea(edges: .top)
                .onAppear(perform: {
                    UIScrollView.appearance().isScrollEnabled = false
                })

                HStack(spacing: 6) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(currentPage == index ? Color.yellow : Color.gray.opacity(0.5))
                            .frame(width: currentPage == index ? 24 : 8, height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 30)

                Button(action: {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()

                    if currentPage < onboardingPages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        // Show paywall on last page
                        showingPaywall = true
                    }
                }) {
                    Text("Continue")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.yellow)
                        .cornerRadius(25)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 35)
            }
        }
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showingPaywall, onDismiss: {
            // Complete onboarding after paywall is dismissed
            appManager.completeOnboarding()
        }) {
            PaywallView()
                .onPurchaseCompleted { customerInfo in
                    // Handle subscription purchase and add credits
                    SubscriptionManager.shared.handleSubscriptionPurchase(customerInfo: customerInfo)

                    // Dismiss paywall after successful purchase
                    showingPaywall = false
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            // Register user when onboarding appears
            if let userId = apiService.userId {
                APIService.shared.registerUser(userId: userId) { result in
                    switch result {
                    case .success(let response):
                        print("✅ [VisualOnboarding] User registered successfully: \(response.message ?? "")")
                        if let user = response.user {
                            print("📊 [VisualOnboarding] User has \(user.credits) credits")
                        }
                    case .failure(let error):
                        print("❌ [VisualOnboarding] Failed to register user: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
