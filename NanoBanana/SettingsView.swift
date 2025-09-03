import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    Text("Done")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(hex: "121419"))
                
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
                        
                        // Subscription Section
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "crown")
                                    .foregroundColor(.white)
                                    .font(.title2)
                                Text("Subscription")
                                    .foregroundColor(.white)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            // Upgrade to Premium
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Upgrade to Premium")
                                            .foregroundColor(.white)
                                            .fontWeight(.medium)
                                        Text("Unlock all features")
                                            .foregroundColor(Color(hex: "9e9d99"))
                                            .font(.caption)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "9e9d99"))
                                }
                                .padding(20)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Other Settings
                        VStack(spacing: 20) {
                            // Restore Purchases
                            SettingsRow(
                                icon: "arrow.clockwise",
                                iconColor: .blue,
                                title: "Restore Purchases",
                                showChevron: false
                            )
                            
                            // About
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.white)
                                    .font(.title)
                                Text("About")
                                    .foregroundColor(.white)
                                    .font(.title2)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            
                            // Version
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
                            
                            // Privacy Policy
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
                                if let url = URL(string: "https://www.termsfeed.com/live/dc1b9371-d8cd-4545-9f6f-823780afa2ee") {
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
                                if let url = URL(string: "https://www.termsfeed.com/live/dc1b9371-d8cd-4545-9f6f-823780afa2ee") {
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
                                Text("🍌")
                                Text("by Nano Banana Team")
                                    .foregroundColor(Color(hex: "9e9d99"))
                            }
                            .font(.body)
                            
                            Text("© 2025 Nano Banana. All rights reserved.")
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
