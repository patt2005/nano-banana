import SwiftUI

struct PinterestGrid: View {
    let columns = [
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0)
    ]
    
    // Symmetric pattern: tall-short alternating
    let sampleItems = [
        PinterestItem(id: 1, height: 280, color: .blue),     // Left: Tall
        PinterestItem(id: 2, height: 180, color: .green),    // Right: Short
        PinterestItem(id: 3, height: 160, color: .purple),   // Left: Short  
        PinterestItem(id: 4, height: 260, color: .orange),   // Right: Tall
        PinterestItem(id: 5, height: 290, color: .red),      // Left: Tall
        PinterestItem(id: 6, height: 170, color: .pink),     // Right: Short
        PinterestItem(id: 7, height: 150, color: .blue),     // Left: Short
        PinterestItem(id: 8, height: 270, color: .cyan),     // Right: Tall
        PinterestItem(id: 9, height: 300, color: .yellow),   // Left: Tall
        PinterestItem(id: 10, height: 160, color: .indigo),  // Right: Short
        PinterestItem(id: 11, height: 140, color: .mint),    // Left: Short
        PinterestItem(id: 12, height: 280, color: .teal)     // Right: Tall
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(sampleItems) { item in
                PinterestCard(item: item)
            }
        }
        .padding(.bottom, 100) // Space for bottom navigation
    }
}

struct PinterestItem: Identifiable {
    let id: Int
    let height: CGFloat
    let color: Color
}

struct PinterestCard: View {
    let item: PinterestItem
    
    var body: some View {
        // Image placeholder - full width, no padding
        Rectangle()
            .fill(item.color.opacity(0.3))
            .frame(height: item.height)
            .overlay(
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Image \(item.id)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            )
            .clipped() // No rounded corners - images are edge to edge
    }
}

// Alternative Masonry Layout (more Pinterest-like)
struct MasonryGrid: View {
    let sampleItems = [
        PinterestItem(id: 1, height: 180, color: .blue),
        PinterestItem(id: 2, height: 240, color: .green),
        PinterestItem(id: 3, height: 160, color: .purple),
        PinterestItem(id: 4, height: 200, color: .orange),
        PinterestItem(id: 5, height: 220, color: .red),
        PinterestItem(id: 6, height: 180, color: .pink),
        PinterestItem(id: 7, height: 260, color: .blue),
        PinterestItem(id: 8, height: 140, color: .cyan)
    ]
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left column
            LazyVStack(spacing: 0) {
                ForEach(leftColumnItems) { item in
                    PinterestCard(item: item)
                }
            }
            
            // Right column  
            LazyVStack(spacing: 0) {
                ForEach(rightColumnItems) { item in
                    PinterestCard(item: item)
                }
            }
        }
        .padding(.bottom, 100)
    }
    
    private var leftColumnItems: [PinterestItem] {
        sampleItems.enumerated().compactMap { index, item in
            index % 2 == 0 ? item : nil
        }
    }
    
    private var rightColumnItems: [PinterestItem] {
        sampleItems.enumerated().compactMap { index, item in
            index % 2 == 1 ? item : nil
        }
    }
}