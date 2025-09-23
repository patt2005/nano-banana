import SwiftUI

struct SplashView: View {
    @ObservedObject private var appManager = AppManager.shared
    @State private var isDataLoaded = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)

            VStack(spacing: 30) {
                Image("icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 225, height: 225)
            }
            .padding(.bottom, 25)
        }
        .onAppear {
            loadInitialData()
        }
    }

    private func loadInitialData() {
        // Load data only once during splash
        if !isDataLoaded && appManager.dataModel == nil {
            isDataLoaded = true
            appManager.loadData {
                // Data loading complete, AppManager will handle state transition
                appManager.checkAppState()
            }
        } else {
            // If data already loaded, just check app state
            appManager.checkAppState()
        }
    }
}
