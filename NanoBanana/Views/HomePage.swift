import SwiftUI

struct ImageData: Codable {
    let id: String
    let imagePath: String
    let prompt: String
    let tags: [String]
}

struct Category: Codable {
    let name: String
    let description: String
    let maxItems: Int
    let images: [ImageData]
}

struct DataModel: Codable {
    let version: String
    let categories: [String: Category]
}

enum HomeTab: String, CaseIterable {
    case forYou = "For You"
    case aiFilters = "AI Filters"
}

struct HomePage: View {
    @State private var showingSettings = false
    @State private var showingShop = false
    @State private var dataModel: DataModel?
    @State private var selectedTab: HomeTab = .forYou
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var appManager = AppManager.shared
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Fixed header with shop and settings
                headerView
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    
                    
                    // Fixed tabs section
                    TabsSection(selectedTab: $selectedTab)
                        .padding(.bottom, 20)
                        .background(Color.black)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Content based on selected tab
                            switch selectedTab {
                            case .forYou:
                                // Lifestyle horizontal list
                                if let lifestyle = dataModel?.categories["lifestyle"] {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text(lifestyle.name)
                                                .font(.circularStdHeadline)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                            
                                            Spacer()
                                        }
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            LazyHStack(spacing: 16) {
                                                ForEach(lifestyle.images, id: \.id) { image in
                                                    LifestyleCard(
                                                        imageData: image,
                                                        isPremium: false,
                                                        isLocked: false
                                                    )
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                        }
                                    }
                                    .padding(.bottom, 30)
                                }
                                
                                // Explore Pinterest-style grid
                                if let explore = dataModel?.categories["explore"] {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Text("Explore")
                                                .font(.circularStdHeadline)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                            
                                            Spacer()
                                        }
                                        
                                        // Pinterest-style masonry grid
                                        HStack(alignment: .top, spacing: 8) {
                                            // Create 2 columns
                                            ForEach(0..<2) { columnIndex in
                                                VStack(spacing: 8) {
                                                    ForEach(Array(explore.images.enumerated()), id: \.element.id) { index, image in
                                                        if index % 2 == columnIndex {
                                                            // Generate random height between 160 and 280
                                                            let randomHeight = CGFloat.random(in: 160...280)
                                                            let columnWidth = (UIScreen.main.bounds.width - 32 - 8) / 2 // Account for padding and spacing
                                                            LifestyleCard(imageData: image, customHeight: randomHeight, customWidth: columnWidth)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                    .padding(.bottom, 30)
                                }
                                
                            case .aiFilters:
                                // Functionality category - Grid layout, completely free
                                if let functionality = dataModel?.categories["functionality"] {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Text("AI Filters")
                                                .font(.circularStdHeadline)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                            
                                            Spacer()
                                        }
                                        
                                        LazyVGrid(columns: [
                                            GridItem(.flexible(), spacing: 12),
                                            GridItem(.flexible(), spacing: 12)
                                        ], spacing: 16) {
                                            ForEach(functionality.images, id: \.id) { image in
                                                LifestyleCard(
                                                    imageData: image,
                                                    isPremium: false,
                                                    isLocked: false
                                                )
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                    .padding(.bottom, 30)
                                }
                            }
                        }
                }
            }
        }
        .fullScreenCover(isPresented: $showingShop) {
            ShopPage()
        }
        .onAppear {
            loadData()
        }
    }
    
    private var headerView: some View {
        HStack {
            Spacer()

            Button(action: {
                showingShop = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "bag")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))

                    Text("Shop")
                        .font(.circularStdCaption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.15))
                .cornerRadius(16)
            }
        }
    }
    
    private func loadData() {
        print("📂 [HomePage] Starting to load data.json...")
        
        guard let url = Bundle.main.url(forResource: "data", withExtension: "json") else {
            print("❌ [HomePage] Could not find data.json in bundle")
            return
        }
        
        print("🔍 [HomePage] Found data.json at: \(url.path)")
        
        do {
            let data = try Data(contentsOf: url)
            print("📖 [HomePage] Successfully read data.json (\(data.count) bytes)")
            
            dataModel = try JSONDecoder().decode(DataModel.self, from: data)
            
            if let lifestyle = dataModel?.categories["lifestyle"] {
                print("✅ [HomePage] Successfully loaded lifestyle category with \(lifestyle.images.count) images")
                for (index, image) in lifestyle.images.enumerated() {
                    print("🖼️ [HomePage] Lifestyle image \(index + 1): \(image.id) -> \(image.imagePath.isEmpty ? "EMPTY PATH" : image.imagePath)")
                }
            } else {
                print("⚠️ [HomePage] No lifestyle category found in data")
            }
            
            if let housing = dataModel?.categories["housing"] {
                print("🏠 [HomePage] Also loaded housing category with \(housing.images.count) images")
            }
            
        } catch {
            print("❌ [HomePage] Error loading data: \(error)")
        }
    }
    
    struct CategorySection: View {
        let category: Category
        let isPremium: Bool
        let showUpgrade: Bool
        let onUpgrade: () -> Void
        @ObservedObject private var subscriptionManager = SubscriptionManager.shared
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(category.name)
                                .font(.circularStdHeadline)
                                .foregroundColor(.white)
                            
                            // Premium badge only if isPremium
                            if isPremium {
                                HStack(spacing: 4) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.yellow)
                                    Text("PREMIUM")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.yellow)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                        
                        if showUpgrade {
                            Text(category.description)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    if showUpgrade {
                        Button(action: onUpgrade) {
                            Text("Upgrade")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.yellow)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        let visibleImages = isPremium && !subscriptionManager.isSubscribed ?
                        Array(category.images.prefix(2)) : category.images
                        
                        ForEach(visibleImages, id: \.id) { image in
                            LifestyleCard(
                                imageData: image,
                                isPremium: isPremium,
                                isLocked: isPremium && !subscriptionManager.isSubscribed
                            )
                        }
                        
                        // Show locked cards for premium categories with non-subscribers
                        if isPremium && !subscriptionManager.isSubscribed && category.images.count > 2 {
                            ForEach(category.images.dropFirst(2).prefix(3), id: \.id) { image in
                                LockedLifestyleCard(imageData: image, onTap: onUpgrade)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 30)
        }
    }
    
    struct TabsSection: View {
        @Binding var selectedTab: HomeTab
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    ForEach(HomeTab.allCases, id: \.self) { tab in
                        TabButton(
                            title: tab.rawValue,
                            isSelected: selectedTab == tab,
                            action: { selectedTab = tab }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    struct TabButton: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            VStack(spacing: 8) {
                Button(action: action) {
                    VStack(spacing: 8) {
                        // Add fire emoji for "For You" tab when selected
                        if title == "For You" && isSelected {
                            HStack(spacing: 4) {
                                Text("🔥")
                                    .font(.system(size: 16))
                                Text(title)
                                    .font(.circularStdBody)
                                    .fontWeight(isSelected ? .semibold : .medium)
                            }
                        } else {
                            Text(title)
                                .font(.circularStdBody)
                                .fontWeight(isSelected ? .semibold : .medium)
                        }
                    }
                    .foregroundColor(isSelected ? .white : .gray)
                }
                
                // Underline indicator
                Rectangle()
                    .fill(isSelected ? Color.red : Color.clear)
                    .frame(height: 2)
                    .frame(width: isSelected ? nil : 0)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
            }
            .frame(minWidth: 60)
        }
    }
    
    struct LifestyleCard: View {
        let imageData: ImageData
        let isPremium: Bool
        let isLocked: Bool
        let customHeight: CGFloat?
        let customWidth: CGFloat?
        
        init(imageData: ImageData, isPremium: Bool = false, isLocked: Bool = false, customHeight: CGFloat? = nil, customWidth: CGFloat? = nil) {
            self.imageData = imageData
            self.isPremium = isPremium
            self.isLocked = isLocked
            self.customHeight = customHeight
            self.customWidth = customWidth
        }
        
        var body: some View {
            VStack(spacing: 12) {
                CachedAsyncImage(
                    url: URL(string: imageData.imagePath),
                    content: { uiImage in
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    },
                    placeholder: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                VStack {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Loading...")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                )
                .frame(width: customWidth ?? (customHeight != nil ? UIScreen.main.bounds.width / 2 : 160),
                       height: customHeight ?? 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(width: customWidth ?? (customHeight != nil ? UIScreen.main.bounds.width / 2 : 160))
        }
    }
    
    struct LockedLifestyleCard: View {
        let imageData: ImageData
        let onTap: () -> Void
        
        var body: some View {
            VStack(spacing: 12) {
                Button(action: onTap) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 160, height: 160)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.yellow)
                                
                                VStack(spacing: 4) {
                                    Text("Premium Content")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("Unlock to access")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.yellow)
                                    Text("Upgrade Now")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.yellow)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.yellow.opacity(0.2))
                                .cornerRadius(8)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Text(imageData.id)
                    .font(.circularStdCaption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .frame(width: 160)
        }
    }
    
    struct FeatureCard: View {
        let icon: String
        let title: String
        let description: String
        
        var body: some View {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.1)))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

