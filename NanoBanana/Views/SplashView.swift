import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showTitle = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)
            
            Image("7")
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .clipped()
                .ignoresSafeArea(.all)
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 1.0), value: isAnimating)
            
            VStack(spacing: 4) {
                Text("NANO")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).delay(0.5), value: isAnimating)
                
                Text("BANANA")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.8).delay(0.8), value: isAnimating)
            }
            .padding(.bottom, 65)
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
