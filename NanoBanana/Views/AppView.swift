import SwiftUI

struct AppView: View {
    @ObservedObject private var appManager = AppManager.shared
    
    var body: some View {
        Group {
            switch appManager.appState {
            case .loading:
//                SplashView()
                ContentView()

            case .onboarding:
//                VisualOnboardingView()
                ContentView()

            case .main:
                ContentView()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appManager.appState)
    }
}
