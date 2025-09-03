import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showMainApp = false
    @State private var showOnboarding = false
    
    var body: some View {
        if showMainApp {
            ContentView()
        } else if showOnboarding {
            OnboardingView()
        } else {
            ZStack {
                // Background Image
                Image("7")
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .clipped()
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 4) {
                    // NANO text
                    Text("NANO")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    // BANANA text
                    Text("BANANA")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 65)
            }
            .onAppear {
                isAnimating = true
                
           
                 DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                     withAnimation(.easeInOut(duration: 0.5)) {
                         showOnboarding = true
                     }
                 }
            }
        }
    }
}
