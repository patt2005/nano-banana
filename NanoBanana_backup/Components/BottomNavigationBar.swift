import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selectedTab: Int
    let onAddTapped: () -> Void
    
    var body: some View {
        ZStack {
            HStack {
                NavigationItem(
                    icon: "house",
                    title: "Home",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                
                Spacer()
                
                Spacer()
                
                NavigationItem(
                    icon: "photo.on.rectangle",
                    title: "Gallery", 
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
            }
            .padding(.horizontal, 40)
            
            VStack {
                Button(action: onAddTapped) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(.white))
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .offset(y: -12)
                
                Spacer()
            }
        }
        .frame(height: 80)
        .background(Color(hex: "00000"))
    }
}

struct NavigationItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
            }
        }
    }
}
