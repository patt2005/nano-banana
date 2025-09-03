import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showTitle = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .opacity(isAnimating ? 0.8 : 1.0)
                    
                    Text("🍌")
                        .font(.system(size: 70))
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                }
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                
                if showTitle {
                    VStack(spacing: 8) {
                        Text("NanoBanana")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(showTitle ? 1.0 : 0.0)
                        
                        Text("AI-Powered Photo Editor")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                            .opacity(showTitle ? 1.0 : 0.0)
                    }
                    .animation(.easeInOut(duration: 0.8), value: showTitle)
                }
            }
        }
        .onAppear {
            isAnimating = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showTitle = true
                }
            }
        }
    }
}
