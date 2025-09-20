import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selectedTab: Int
    let onAddTapped: () -> Void

    var body: some View {
        HStack {
            NavigationItem(
                icon: "house",
                title: "Home",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )

            Spacer()

            NavigationItem(
                icon: "photo.on.rectangle",
                title: "Gallery",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )

            Spacer()

            NavigationItem(
                icon: "message",
                title: "Chat",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )

            Spacer()

            NavigationItem(
                icon: "gearshape",
                title: "Settings",
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 }
            )
        }
        .padding(.horizontal, 20)
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
                    .foregroundColor(isSelected ? .yellow : .gray)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .yellow : .gray)
            }
        }
    }
}
