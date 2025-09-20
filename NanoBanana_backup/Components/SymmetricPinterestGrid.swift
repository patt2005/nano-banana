import SwiftUI

struct SymmetricPinterestGrid: View {
    let images: [ImageData]
    
    // Perfect symmetric pattern
    private let tallHeight: CGFloat = 300
    private let shortHeight: CGFloat = 160
    
    init(images: [ImageData] = []) {
        self.images = images
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left column
            VStack(spacing: 0) {
                ForEach(leftColumnItems.indices, id: \.self) { index in
                    SymmetricCard(
                        item: leftColumnItems[index],
                        isLeft: true
                    )
                }
            }
            
            // Right column
            VStack(spacing: 0) {
                ForEach(rightColumnItems.indices, id: \.self) { index in
                    SymmetricCard(
                        item: rightColumnItems[index],
                        isLeft: false
                    )
                }
            }
        }
        .onAppear {
            print("🔍 [SymmetricPinterestGrid] Grid appeared")
            print("🖼️ [SymmetricPinterestGrid] Images count: \(images.count)")
            print("📏 [SymmetricPinterestGrid] Tall height: \(tallHeight)")
            print("📏 [SymmetricPinterestGrid] Short height: \(shortHeight)")
            print("📋 [SymmetricPinterestGrid] Left column items: \(leftColumnItems.count)")
            print("📋 [SymmetricPinterestGrid] Right column items: \(rightColumnItems.count)")
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 120)
    }
    
    // Left column: Tall-Short-Tall-Short pattern
    private var leftColumnItems: [SymmetricItem] {
        let pattern = [tallHeight, shortHeight, tallHeight, shortHeight, tallHeight, shortHeight]
        var items: [SymmetricItem] = []
        
        for i in 0..<min(6, (images.count + 1) / 2) {
            let imageIndex = i * 2
            if imageIndex < images.count {
                items.append(SymmetricItem(
                    id: imageIndex,
                    height: pattern[i],
                    imageData: images[imageIndex]
                ))
            }
        }
        return items
    }
    
    // Right column: Short-Tall-Short-Tall pattern (opposite of left)
    private var rightColumnItems: [SymmetricItem] {
        let pattern = [shortHeight, tallHeight, shortHeight, tallHeight, shortHeight, tallHeight]
        var items: [SymmetricItem] = []
        
        for i in 0..<min(6, images.count / 2) {
            let imageIndex = i * 2 + 1
            if imageIndex < images.count {
                items.append(SymmetricItem(
                    id: imageIndex,
                    height: pattern[i],
                    imageData: images[imageIndex]
                ))
            }
        }
        return items
    }
}

struct SymmetricItem: Identifiable {
    let id: Int
    let height: CGFloat
    let imageData: ImageData
}

struct SymmetricCard: View {
    let item: SymmetricItem
    let isLeft: Bool
    
    var body: some View {
        AsyncImage(url: URL(string: item.imageData.imagePath)) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: item.height)
                    .overlay(
                        VStack {
                            ProgressView()
                                .tint(.white)
                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
                    .onAppear {
                        print("🔄 [SymmetricCard] Loading image: \(item.imageData.id)")
                        print("🔗 [SymmetricCard] URL: \(item.imageData.imagePath)")
                        print("📏 [SymmetricCard] Expected height: \(item.height)")
                    }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: item.height)
                    .clipped()
                    .onAppear {
                        print("✅ [SymmetricCard] Successfully loaded: \(item.imageData.id)")
                        print("📐 [SymmetricCard] Final frame height: \(item.height)")
                        print("🎯 [SymmetricCard] Position: \(isLeft ? "Left" : "Right") column")
                    }
            case .failure(let error):
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.red.opacity(0.2))
                    .frame(height: item.height)
                    .overlay(
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                            Text("Failed")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    )
                    .onAppear {
                        print("❌ [SymmetricCard] Failed to load: \(item.imageData.id)")
                        print("🚫 [SymmetricCard] Error: \(error.localizedDescription)")
                        print("🔗 [SymmetricCard] Failed URL: \(item.imageData.imagePath)")
                    }
            @unknown default:
                EmptyView()
            }
        }
    }
}