import SwiftUI

struct ShopPage: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPackage: CreditPackage?
    @State private var showingPurchase = false
    
    var body: some View {
        ZStack {
            // Black background with banana-themed gradient
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                // Banana-themed linear gradient overlay
                LinearGradient(
                    colors: [
                        Color(hex: "FFD700").opacity(0.15),  // Gold yellow
                        Color(hex: "FFA500").opacity(0.08),  // Orange
                        Color(hex: "FF8C00").opacity(0.05),  // Dark orange
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    Text("Purchase Credits")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Balance placeholder
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // Current balance card with icon
                VStack(spacing: 12) {
                    Image("icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                    
                    Text("0 Credits")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Available Balance")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FFD700").opacity(0.1),  // Gold yellow
                                    Color(hex: "FFA500").opacity(0.05), // Orange fade
                                    Color.black.opacity(0.3)            // Dark base
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "FFD700").opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                
                // Choose a Package section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Choose a Package")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // Package list
                    VStack(spacing: 12) {
                        ForEach(cleanCreditPackages) { package in
                            CleanCreditPackageRow(
                                package: package,
                                isSelected: selectedPackage?.id == package.id,
                                onTap: {
                                    selectedPackage = package
                                    showingPurchase = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingPurchase) {
            if let package = selectedPackage {
                CleanPurchaseSheet(package: package)
            }
        }
    }
}

struct CreditPackage: Identifiable {
    let id = UUID()
    let name: String
    let credits: Int
    let price: String
    let originalPrice: String?
    let badge: String?
    let color: Color
    let isPopular: Bool
}

// Clean credit packages matching reference design
let cleanCreditPackages = [
    CreditPackage(
        name: "Basic",
        credits: 10,
        price: "USD 14.99",
        originalPrice: nil,
        badge: nil,
        color: .clear,
        isPopular: false
    ),
    CreditPackage(
        name: "Popular",
        credits: 20,
        price: "USD 29.99",
        originalPrice: nil,
        badge: "Save 20%",
        color: .purple,
        isPopular: false
    ),
    CreditPackage(
        name: "Best Deal",
        credits: 30,
        price: "USD 34.99",
        originalPrice: nil,
        badge: "Save 30%",
        color: .purple,
        isPopular: true
    ),
    CreditPackage(
        name: "Ultimate",
        credits: 60,
        price: "USD 69.99",
        originalPrice: nil,
        badge: "Best Value",
        color: .purple,
        isPopular: false
    )
]

struct CreditPackageCard: View {
    let package: CreditPackage
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Badge
                if let badge = package.badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(package.color)
                        .cornerRadius(8)
                        .offset(y: -8)
                }
                
                VStack(spacing: 16) {
                    // Icon and credits
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(package.color.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "star.fill")
                                .font(.title2)
                                .foregroundColor(package.color)
                        }
                        
                        Text("\(package.credits)")
                            .font(.circularStdHeadline)
                            .foregroundColor(.white)
                        
                        Text("Credits")
                            .font(.circularStdCaption)
                            .foregroundColor(.gray)
                    }
                    
                    // Pricing
                    VStack(spacing: 4) {
                        if let originalPrice = package.originalPrice {
                            Text(originalPrice)
                                .font(.circularStdCaption)
                                .foregroundColor(.gray)
                                .strikethrough()
                        }
                        
                        Text(package.price)
                            .font(.circularStdHeadline)
                            .foregroundColor(.white)
                        
                        Text(package.name)
                            .font(.circularStdCaption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                package.isPopular ? package.color : Color.white.opacity(0.1),
                                lineWidth: package.isPopular ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PurchaseSheet: View {
    let package: CreditPackage
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("Purchase")
                        .font(.circularStdHeadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 60)
                }
                .padding(.horizontal, 20)
                
                // Package details
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(package.color.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "star.fill")
                            .font(.largeTitle)
                            .foregroundColor(package.color)
                    }
                    
                    VStack(spacing: 8) {
                        Text("\(package.credits) Credits")
                            .font(.circularStdTitle)
                            .foregroundColor(.white)
                        
                        Text(package.name + " Package")
                            .font(.circularStdBody)
                            .foregroundColor(.gray)
                    }
                    
                    Text(package.price)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 12) {
                    Text("✓ Generate unlimited AI images")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    Text("✓ High-quality outputs")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    Text("✓ Priority processing")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    Text("✓ No expiration date")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Purchase button
                Button(action: {
                    isPurchasing = true
                    // Handle purchase logic here
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isPurchasing = false
                        dismiss()
                    }
                }) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Purchase \(package.price) - Static Demo")
                                .font(.circularStdHeadline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(package.color)
                    .cornerRadius(25)
                }
                .disabled(isPurchasing)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

struct CleanCreditPackageRow: View {
    let package: CreditPackage
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("\(package.credits) Credits")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        
                        if let badge = package.badge {
                            Text(badge)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "FFD700"),  // Gold
                                            Color(hex: "FFA500")   // Orange
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(package.price)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(package.isPopular ? Color(hex: "FFD700") : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(package.isPopular ? Color(hex: "FFD700") : Color(hex: "FFD700"))
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: package.isPopular ? [
                                Color(hex: "FFD700").opacity(0.15),  // Gold for popular
                                Color(hex: "FFA500").opacity(0.1),   // Orange fade
                                Color.black.opacity(0.4)             // Dark base
                            ] : [
                                Color(hex: "FFD700").opacity(0.08),  // Subtle gold
                                Color.black.opacity(0.2)             // Dark base
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                package.isPopular ? Color(hex: "FFD700").opacity(0.6) : Color(hex: "FFD700").opacity(0.2),
                                lineWidth: package.isPopular ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CleanPurchaseSheet: View {
    let package: CreditPackage
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    
    var body: some View {
        ZStack {
            // Black background with banana-themed gradient
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                // Banana-themed linear gradient overlay
                LinearGradient(
                    colors: [
                        Color(hex: "FFD700").opacity(0.15),  // Gold yellow
                        Color(hex: "FFA500").opacity(0.08),  // Orange
                        Color(hex: "FF8C00").opacity(0.05),  // Dark orange
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("Confirm Purchase")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 60)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
                
                // Package details
                VStack(spacing: 20) {
                    Text("\(package.credits) Credits")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(package.price)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 40)
                
                Spacer()
                
                // Purchase button at bottom
                VStack(spacing: 16) {
                    Text("\(package.credits) Credits")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(package.price)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        isPurchasing = true
                        // Handle purchase logic here
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isPurchasing = false
                            dismiss()
                        }
                    }) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Demo Purchase (Not Connected)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FFD700"),  // Gold
                                    Color(hex: "FFA500")   // Orange
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal, 20)
                    
                    Button("Restore Purchases") {
                        // Handle restore purchases
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
            }
        }
    }
}
