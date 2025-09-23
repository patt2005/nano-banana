import SwiftUI

enum HomeTab: String, CaseIterable {
    case forYou = "For You"
    case aiFilters = "AI Filters"
}

struct HomePage: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingSettings = false
    @State private var showingShop = false
    @State private var selectedTab: HomeTab = .forYou
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var appManager = AppManager.shared
    
    var body: some View {
        NavigationStack {
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

                    if appManager.isLoadingData {
                        ProgressView("Loading content...")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                    } else if let error = appManager.loadError {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.yellow)

                            Text("Failed to load content")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(error)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button("Retry") {
                                appManager.loadData()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.yellow)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                // Content based on selected tab
                                switch selectedTab {
                            case .forYou:
                                // Lifestyle horizontal list
                                if let lifestyle = appManager.dataModel?.categories["lifestyle"] {
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
                                                    Button(action: {
                                                        viewModel.selectImage(image)
                                                    }) {
                                                        LifestyleCard(
                                                            imageData: image,
                                                            isPremium: false,
                                                            isLocked: false
                                                        )
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                        }
                                    }
                                    .padding(.bottom, 30)
                                }
                                
                                // Explore Pinterest-style grid
                                if let explore = appManager.dataModel?.categories["explore"] {
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
                                                            // Use stored height from viewModel
                                                            let height = viewModel.getExploreImageHeight(for: image.id)
                                                            let columnWidth = (UIScreen.main.bounds.width - 32 - 8) / 2 // Account for padding and spacing
                                                            Button(action: {
                                                                viewModel.selectImage(image)
                                                            }) {
                                                                LifestyleCard(imageData: image, customHeight: height, customWidth: columnWidth)
                                                            }
                                                            .buttonStyle(PlainButtonStyle())
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
                                if let functionality = appManager.dataModel?.categories["functionality"] {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("AI Filters")
                                                .font(.circularStdHeadline)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)

                                            Spacer()
                                        }

                                        LazyVGrid(columns: [
                                            GridItem(.flexible(), spacing: 8),
                                            GridItem(.flexible(), spacing: 8)
                                        ], spacing: 8) {
                                            ForEach(functionality.images, id: \.id) { image in
                                                Button(action: {
                                                    viewModel.selectImage(image)
                                                }) {
                                                    AIFilterCard(imageData: image)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                    .padding(.bottom, 20)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showingSettings) {
            SettingsView()
                .navigationBarBackButtonHidden(false)
        }
        .fullScreenCover(isPresented: $showingShop) {
            ShopPage()
        }
        .sheet(isPresented: $viewModel.showingEditSheet) {
            if let selectedImage = viewModel.selectedImageData {
                EditImageView(imageData: selectedImage, viewModel: viewModel)
            }
        }
        .onAppear {
            // Update viewModel with data from AppManager
            if let model = appManager.dataModel {
                viewModel.dataModel = model
                if let explore = model.categories["explore"] {
                    viewModel.generateExploreHeights(for: explore.images)
                }
            }
        }
        }
    }
    
    private var headerView: some View {
        HStack {
            // Settings button on the left
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .medium))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }

            Spacer()

            // Shop button on the right
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
                    LazyHStack(spacing: 10) {
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
    
    struct AIFilterCard: View {
        let imageData: ImageData

        var body: some View {
            ZStack(alignment: .bottom) {
                // Image
                CachedAsyncImage(
                    url: URL(string: imageData.imagePath),
                    content: { uiImage in
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    },
                    placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    }
                )
                .frame(width: (UIScreen.main.bounds.width - 40) / 2,
                       height: (UIScreen.main.bounds.width - 40) / 2)
                .clipped()

                // Text overlay at bottom
                VStack(spacing: 0) {
                    Spacer()

                    Text(imageData.title ?? "AI Filter")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.8),
                                    Color.black.opacity(0.6)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                }
            }
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
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

