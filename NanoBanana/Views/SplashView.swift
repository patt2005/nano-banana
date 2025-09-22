import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)

            Image("icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 220, height: 220)
        }
    }
}
