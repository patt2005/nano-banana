import SwiftUI
import Combine

final class AppManager: ObservableObject {
    static let shared = AppManager()
    
    @Published var appState: AppState = .loading
    @Published var isFirstLaunch: Bool = true
    @Published var showPaywall: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let onboardingKey = "hasCompletedOnboarding"
    
    enum AppState {
        case loading
        case onboarding
        case main
    }
    
    private init() {
        checkAppState()
    }
    
    func checkAppState() {
        isFirstLaunch = !userDefaults.bool(forKey: onboardingKey)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.isFirstLaunch {
                self.appState = .onboarding
            } else {
                self.appState = .main
            }
        }
    }
    
    func completeOnboarding() {
        userDefaults.set(true, forKey: onboardingKey)
        isFirstLaunch = false
        appState = .main
    }
    
    func resetOnboarding() {
        userDefaults.set(false, forKey: onboardingKey)
        isFirstLaunch = true
        appState = .onboarding
    }
    
    func showSplash() {
        appState = .loading
        checkAppState()
    }
}
