import SwiftUI
import Combine

final class AppManager: ObservableObject {
    static let shared = AppManager()

    @Published var appState: AppState = .loading
    @Published var isFirstLaunch: Bool = true
    @Published var showPaywall: Bool = false
    @Published var dataModel: DataModel?
    @Published var isLoadingData: Bool = false
    @Published var loadError: String?

    private let userDefaults = UserDefaults.standard
    private let onboardingKey = "hasCompletedOnboarding"

    enum AppState {
        case loading
        case onboarding
        case main
    }

    private init() {
        // Don't check app state here, let SplashView handle it after loading data
    }

    func checkAppState() {
        let hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
        isFirstLaunch = !hasCompletedOnboarding

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if hasCompletedOnboarding {
                self.appState = .main
            } else {
                self.appState = .onboarding
            }
        }
    }

    func completeOnboarding() {
        userDefaults.set(true, forKey: onboardingKey)
        isFirstLaunch = false
        showPaywall = true
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

    func presentPaywall() {
        showPaywall = true
    }

    func dismissPaywall() {
        showPaywall = false
    }

    func loadData(completion: @escaping () -> Void = {}) {
        print("📂 [AppManager] Starting to load data from remote server...")

        isLoadingData = true
        loadError = nil

        APIService.shared.loadData { [weak self] result in
            guard let self = self else { return }

            self.isLoadingData = false

            switch result {
            case .success(let model):
                print("✅ [AppManager] Successfully loaded data from remote server")
                self.dataModel = model

                if let lifestyle = model.categories["lifestyle"] {
                    print("✅ [AppManager] Lifestyle category: \(lifestyle.images.count) images")
                }

                if let explore = model.categories["explore"] {
                    print("✅ [AppManager] Explore category: \(explore.images.count) images")
                }

                if let functionality = model.categories["functionality"] {
                    print("✅ [AppManager] Functionality category: \(functionality.images.count) images")
                }

            case .failure(let error):
                print("❌ [AppManager] Failed to load data: \(error)")
                self.loadError = error.localizedDescription
            }

            completion()
        }
    }
}
