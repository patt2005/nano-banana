import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content area
                Group {
                    switch selectedTab {
                    case 0:
                        HomePage()
                    case 1:
                        GalleryPage()
                    case 2:
                        ChatPage()
                    default:
                        HomePage()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom Navigation
                BottomNavigationBar(
                    selectedTab: $selectedTab,
                    onAddTapped: {
                        selectedTab = 2 // Switch to ChatPage when add button is pressed
                    }
                )
                .ignoresSafeArea(.all, edges: .bottom)
            }
        }
    }
}
