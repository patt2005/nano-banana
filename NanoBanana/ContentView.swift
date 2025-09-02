import SwiftUI

struct ContentView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var showingChat = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom App Bar
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                
                Spacer()
                
                HStack {
                    Text("🍌")
                        .font(.title2)
                    Text("NanoBanana")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("2 Free Edits Left")
                    .font(.caption)
                    .foregroundColor(Color(hex: "9e9d99"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "121419"))
            
            // Main Content
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Upload your photo")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Share best memos to edit them!")
                        .font(.body)
                        .foregroundColor(Color(hex: "9e9d99"))
                    
                    // Upload Area with Image Selection
                    VStack {
                        ImageSelectionView(selectedImages: $chatViewModel.selectedImages)
                        
                        if chatViewModel.selectedImages.isEmpty {
                            Button(action: {}) {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "2e2e2e"))
                                    .frame(width: 200, height: 120)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(Color(hex: "9e9d99"))
                                    )
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "121419"))
            
            // Bottom Container - Input Area
            VStack(spacing: 12) {
                // Text Input Field
                HStack {
                    TextField("Enter your prompt...", text: $chatViewModel.currentInput, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(hex: "121419"))
                        .cornerRadius(20)
                        .lineLimit(1...5)
                }
                .padding(.horizontal, 16)
                
                HStack {
                    Button(action: {
                        showingChat = true
                    }) {
                        HStack {
                            Image(systemName: "message")
                                .foregroundColor(.white)
                            Text("Open Chat")
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(hex: "2e2e2e"))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if chatViewModel.canSend {
                            chatViewModel.sendMessage()
                            showingChat = true
                        }
                    }) {
                        Image(systemName: chatViewModel.isLoading ? "stop.circle" : "arrow.up")
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(chatViewModel.canSend ? .white : Color(hex: "9e9d99")))
                    }
                    .disabled(!chatViewModel.canSend)
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
            .background(Color(hex: "2e2e2e"))
            .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
        }
        .ignoresSafeArea(.all, edges: .top)
        .sheet(isPresented: $showingChat) {
            ChatView(viewModel: chatViewModel)
        }
    }
}


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}