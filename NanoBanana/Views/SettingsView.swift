import SwiftUI

struct SettingsView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var appManager = AppManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isRestoring = false
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        HStack {
                            Text("Settings")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Free Messages Counter (for non-subscribers only)
                        if !subscriptionManager.hasActiveSubscription {
                            VStack(spacing: 12) {
                                HStack {
                                    Image("icon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                    
                                    Text("Free Generations")
                                        .foregroundColor(.white)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(chatViewModel.remainingFreeMessages)")
                                            .foregroundColor(Color(hex: "FFD700"))
                                            .font(.title3)
                                            .fontWeight(.bold)
                                        
                                        Text("remaining")
                                            .foregroundColor(Color(hex: "9e9d99"))
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "2e2e2e"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            Color(hex: "FFD700").opacity(0.4),
                                                            Color(hex: "FFA500").opacity(0.3)
                                                        ],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                                
                                if chatViewModel.remainingFreeMessages == 0 {
                                    HStack {
                                        Text("You've used all your free generations. Upgrade to Pro for unlimited generations.")
                                            .foregroundColor(Color(hex: "9e9d99"))
                                            .font(.caption)
                                            .multilineTextAlignment(.center)
                                    }
                                } else {
                                    HStack {
                                        Text("Start a new chat for more free generations.")
                                            .foregroundColor(Color(hex: "9e9d99"))
                                            .font(.caption)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Premium Upgrade Card (only for non-subscribers)
                        if !subscriptionManager.hasActiveSubscription {
                            VStack(spacing: 0) {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    appManager.showPaywall = true
                                }
                            }) {
                                VStack(spacing: 20) {
                                    // Header with star icon and title
                                    HStack(spacing: 12) {
                                        Image("icon")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40, height: 40)
                                        
                                        Text("AI Pro Plan")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    
                                    // Subtitle
                                    HStack {
                                        Text("Unlock premium editing features:")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                        Spacer()
                                    }
                                    
                                    // Feature list
                                    VStack(spacing: 12) {
                                        FeatureRow(text: "Unlimited edits")
                                        FeatureRow(text: "Fast processing")
                                        FeatureRow(text: "No watermark")
                                    }
                                    
                                    // Upgrade button
                                    HStack(spacing: 8) {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text("Upgrade to Pro")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                       
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "FFD700").opacity(0.4),  // Much softer Gold
                                                Color(hex: "FFA500").opacity(0.3),  // Much softer Orange
                                                Color(hex: "FF8C00").opacity(0.2)   // Much softer Dark orange
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color(hex: "FFD700").opacity(0.4),
                                                        Color(hex: "FFA500").opacity(0.3)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(color: Color(hex: "FFD700").opacity(0.2), radius: 6, x: 0, y: 3)
                                }
                                .padding(24)
                                .background(
                                    Image("pro plan")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .opacity(0.3)
                                        .clipped()
                                )
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "FFD700").opacity(0.4),
                                                    Color(hex: "FFA500").opacity(0.3)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        }

                        // Other Settings
                        VStack(spacing: 20) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                    .frame(width: 24)
                                
                                Text("Version")
                                    .foregroundColor(.white)
                                    .font(.body)
                                
                                Spacer()
                                
                                Text("1.0.0")
                                    .foregroundColor(Color(hex: "9e9d99"))
                                    .font(.body)
                            }
                            .padding(.horizontal, 20)
                            
                            Button(action: {
                                isRestoring = true
                                subscriptionManager.restorePurchases { success, error in
                                    isRestoring = false
                                    if success {
                                        restoreMessage = "Purchases restored successfully!"
                                    } else {
                                        restoreMessage = "No purchases found to restore."
                                    }
                                    showingRestoreAlert = true
                                }
                            }) {
                                HStack {
                                    if isRestoring {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.blue)
                                            .frame(width: 24, height: 24)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                            .frame(width: 24)
                                    }

                                    Text("Restore Purchases")
                                        .foregroundColor(.white)
                                        .font(.body)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "9e9d99"))
                                }
                                .padding(.horizontal, 20)
                            }
                            .disabled(isRestoring)
                            
                            Button(action: {
                                if let url = URL(string: "https://www.termsfeed.com/live/dc1b9371-d8cd-4545-9f6f-823780afa2ee") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "lock.shield")
                                        .foregroundColor(.purple)
                                        .font(.title2)
                                        .frame(width: 24)
                                    
                                    Text("Privacy Policy")
                                        .foregroundColor(.white)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "9e9d99"))
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Terms of Service
                            Button(action: {
                                if let url = URL(string: "https://www.termsfeed.com/live/efa197cb-d472-4b22-9d83-f7f9bf4e3d4b") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                        .frame(width: 24)
                                    
                                    Text("Terms of Service")
                                        .foregroundColor(.white)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "9e9d99"))
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Contact Support
                            Button(action: {
                                if let url = URL(string: "mailto:esmondandersonhaldegallagher@gmail.com?subject=NanoBanana%20Support") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.green)
                                        .font(.title2)
                                        .frame(width: 24)
                                    
                                    Text("Contact Support")
                                        .foregroundColor(.white)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "9e9d99"))
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Footer
                        VStack(spacing: 8) {
                            HStack {
                                Text("Made with")
                                    .foregroundColor(Color(hex: "9e9d99"))
                                Image("icon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                Text("by Navo AI Team")
                                    .foregroundColor(Color(hex: "9e9d99"))
                            }
                            .font(.body)
                            
                            Text("© 2025 Navo AI. All rights reserved.")
                                .foregroundColor(Color(hex: "9e9d99"))
                                .font(.caption)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(Color(hex: "121419"))
            .navigationBarHidden(true)
        }
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("OK") { }
        } message: {
            Text(restoreMessage)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let showChevron: Bool
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title2)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.white)
                    .font(.body)
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(hex: "9e9d99"))
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .bold))
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}
