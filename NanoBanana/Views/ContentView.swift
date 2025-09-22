import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingChat = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Group {
                        switch selectedTab {
                        case 0:
                            HomePage()
                        case 1:
                            GalleryPage()
                        default:
                            HomePage()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Bottom Navigation
                    BottomNavigationBar(
                        selectedTab: $selectedTab,
                        onAddTapped: {
                            // No longer used
                        }
                    )
                    .ignoresSafeArea(.all, edges: .bottom)
                }

                // Floating Action Button
                VStack {
                    Spacer()

                    Button(action: {
                        showingChat = true
                    }) {
                        ZStack {
                            // Shadow layer
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.yellow,
                                            Color.yellow.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: .yellow.opacity(0.4), radius: 10, x: 0, y: 5)
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)

                            // Icon
                            Image("bubble-chat")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .foregroundColor(.black)
                        }
                    }
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showingChat)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showingChat) {
                ChatPage()
            }
        }
    }
}
