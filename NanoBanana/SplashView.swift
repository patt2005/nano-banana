import SwiftUI

struct SplashView: View {
    @State private var showMainView = false
    @State private var bananaScale: CGFloat = 0.5
    @State private var titleOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            AppColors.primary
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Google")
                        .font(.system(size: 48, weight: .light, design: .default))
                        .foregroundColor(.white)
                        .opacity(titleOpacity)
                    
                    Text("Nano Banana")
                        .font(.system(size: 52, weight: .light, design: .default))
                        .foregroundColor(.white)
                        .opacity(titleOpacity)
                }
                
                Text("🍌")
                    .font(.system(size: 120))
                    .scaleEffect(bananaScale)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                bananaScale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                titleOpacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showMainView = true
                }
            }
        }
        .fullScreenCover(isPresented: $showMainView) {
            ContentView()
        }
    }
}

#Preview {
    SplashView()
}