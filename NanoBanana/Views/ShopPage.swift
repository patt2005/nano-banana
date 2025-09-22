import SwiftUI
import RevenueCat

struct ShopPage: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPackage: String = "30"
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccessAlert = false
    @State private var purchasedCredits = 0

    let creditPackages: [(id: String, credits: Int, productId: String, discount: String?)] = [
        ("85", 85, "com.nanobanana.credits10", nil),
        ("500", 500, "com.nanobanana.credits20", "Popular"),
        ("650", 650, "com.nanobanana.credits30", "Great Deal"),
        ("1500", 1500, "com.nanobanana.credits60", "Best Value")
    ]

    var body: some View {
        ZStack {
            // Black background
            Color.black
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("Purchase Credits")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Current balance card with icon
                        VStack(spacing: 12) {
                            Image("icon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)

                            Text("\(subscriptionManager.credits) Credits")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)

                            Text("Available Balance")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "FFD700").opacity(0.3),
                                            Color(hex: "FFA500").opacity(0.2),
                                            Color(hex: "FFD700").opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(hex: "FFD700").opacity(0.4), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)

                        // Package selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Choose a Package")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            VStack(spacing: 12) {
                                ForEach(creditPackages, id: \.id) { package in
                                    CreditPackageRow(
                                        credits: package.credits,
                                        price: getPackagePrice(productId: package.productId) ?? "USD \(package.credits / 2).99",
                                        discount: package.discount,
                                        isSelected: selectedPackage == package.id,
                                        isBestValue: package.id == "60"
                                    ) {
                                        selectedPackage = package.id
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 10)

                        Spacer(minLength: 100)
                    }
                }

                // Bottom purchase section
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(getSelectedCredits()) Credits")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            Text(getSelectedPrice())
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: {
                            handlePurchase()
                        }) {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Purchase")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(.black)
                            .frame(width: 140, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "FFD700"),
                                                Color(hex: "FFA500")
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .disabled(isPurchasing)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Button(action: {
                        handleRestorePurchases()
                    }) {
                        Text("Restore Purchases")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .underline()
                    }
                    .padding(.bottom, 5)
                }
                .background(
                    Color.black
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Purchase Successful!", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("\(purchasedCredits) credits have been added to your account.")
        }
        .onAppear {
            // Refresh offerings when view appears
            subscriptionManager.fetchOfferings()
        }
    }

    private func getSelectedCredits() -> String {
        creditPackages.first { $0.id == selectedPackage }?.credits.description ?? "0"
    }

    private func getSelectedPrice() -> String {
        if let package = creditPackages.first(where: { $0.id == selectedPackage }) {
            return getPackagePrice(productId: package.productId) ?? "USD \(package.credits / 2).99"
        }
        return "USD 0.00"
    }

    private func getPackagePrice(productId: String) -> String? {
        // Get price from RevenueCat if available
        return subscriptionManager.getPackagePrice(for: productId)
    }

    private func handlePurchase() {
        isPurchasing = true

        guard let package = creditPackages.first(where: { $0.id == selectedPackage }) else {
            isPurchasing = false
            return
        }

        // Purchase through RevenueCat
        subscriptionManager.purchaseCreditsPackage(packageId: package.productId) { success, creditsAdded, error in
            if success {
                // Update backend if user ID exists
                if let userId = GeminiAPIService.shared.userId {
                    APIService.shared.updateUserCredits(userId: userId, credits: creditsAdded) { result in
                        DispatchQueue.main.async {
                            self.isPurchasing = false

                            switch result {
                            case .success(let response):
                                if let user = response.user {
                                    print("✅ Credits updated on server: \(user.credits)")
                                    self.subscriptionManager.updateCredits(user.credits)
                                }
                                self.purchasedCredits = creditsAdded
                                self.showSuccessAlert = true
                            case .failure(let error):
                                print("❌ Failed to update credits on server: \(error)")
                                // Still show success since purchase went through
                                self.purchasedCredits = creditsAdded
                                self.showSuccessAlert = true
                            }
                        }
                    }
                } else {
                    // No user ID, but purchase successful
                    DispatchQueue.main.async {
                        self.isPurchasing = false
                        self.purchasedCredits = creditsAdded
                        self.showSuccessAlert = true
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isPurchasing = false
                    self.errorMessage = error?.localizedDescription ?? "Purchase failed. Please try again."
                    self.showError = true
                }
            }
        }
    }

    private func handleRestorePurchases() {
        isPurchasing = true

        subscriptionManager.restorePurchases { success, error in
            DispatchQueue.main.async {
                isPurchasing = false

                if success {
                    dismiss()
                } else {
                    errorMessage = error?.localizedDescription ?? "No previous purchases found to restore."
                    showError = true
                }
            }
        }
    }
}

struct CreditPackageRow: View {
    let credits: Int
    let price: String
    let discount: String?
    let isSelected: Bool
    let isBestValue: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("\(credits) Credits")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        if let discount = discount {
                            Text(discount)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "FFD700"),
                                                    Color(hex: "FFA500")
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }

                    Text(price)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color(hex: "FFD700") : Color.gray.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color(hex: "FFD700"))
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [
                                Color(hex: "FFD700").opacity(0.25),
                                Color(hex: "FFA500").opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ?
                                Color(hex: "FFD700").opacity(0.8) :
                                Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Remove old unused structs
struct PurchaseSheet: View {
    let package: CreditPackage
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false

    var body: some View {
        EmptyView()
    }
}

struct CleanCreditPackageRow: View {
    var body: some View {
        EmptyView()
    }
}

struct CleanPurchaseSheet: View {
    var body: some View {
        EmptyView()
    }
}

// Simple credit package for legacy compatibility
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
