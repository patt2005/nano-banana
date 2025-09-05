import SwiftUI
import LaTeXSwiftUI

struct ShareView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
                UserMessageBubble(message: message)
            } else {
                AIMessageBubble(message: message)
                Spacer(minLength: 50)
            }
        }
    }
}

struct UserMessageBubble: View {
    let message: ChatMessage
    @State private var fullScreenImage: UIImage?
    @State private var showingCopyConfirmation = false
    
    var body: some View {
        VStack(alignment: .trailing) {
            if !message.images.isEmpty {
                ReversedScrollView {
                    ForEach(Array(message.images.enumerated()), id: \.offset) { index, image in
                        Button(action: {
                            fullScreenImage = image
                        }) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .cornerRadius(8)
                                .clipped()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .padding(.bottom, 8)
            }
            
            if !message.content.isEmpty {
                Text(message.content)
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            
            if !message.content.isEmpty {
                Button(action: {
                    UIPasteboard.general.string = message.content
                    showingCopyConfirmation = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .fullScreenCover(item: Binding<UIImageWrapper?>(
            get: { fullScreenImage.map(UIImageWrapper.init) },
            set: { _ in fullScreenImage = nil }
        )) { wrapper in
            FullScreenImageView(image: wrapper.image) {
                fullScreenImage = nil
            }
        }
        .alert("Copied!", isPresented: $showingCopyConfirmation) {
            Button("OK") { }
        } message: {
            Text("Text was copied to clipboard")
        }
    }
}

struct UIImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct FullScreenImageView: View {
    let image: UIImage
    let onDismiss: () -> Void
    @State private var showingShareSheet = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                
                Spacer()
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareView(activityItems: [image])
        }
    }
}

struct AIMessageBubble: View {
    let message: ChatMessage
    @State private var showingCopyConfirmation = false
    @State private var fullScreenImage: UIImage?
    @State private var showingShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 40, height: 40)
                    
                    Image("Cat")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }
                .padding(.top, 4)
                
                VStack(alignment: .leading) {
                    if !message.images.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(message.images.indices, id: \.self) { index in
                                    Button(action: {
                                        fullScreenImage = message.images[index]
                                    }) {
                                        Image(uiImage: message.images[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 160, height: 160)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if !message.content.isEmpty {
                            LaTeX(message.content)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                                .parsingMode(.onlyEquations)
                                .blockMode(.blockViews)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                        
                        if message.isStreaming {
                            HStack {
                                StreamingDots()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                    .background(Color(hex: "2e2e2e"))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    if !message.isStreaming {
                        HStack(spacing: 8) {
                            if !message.content.isEmpty {
                                Button(action: {
                                    UIPasteboard.general.string = message.content
                                    showingCopyConfirmation = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copy")
                                    }
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            
                            Button(action: {
                                showingShareSheet = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                }
                                .foregroundColor(.white.opacity(0.8))
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
            }
        }
        .fullScreenCover(item: Binding<UIImageWrapper?>(
            get: { fullScreenImage.map(UIImageWrapper.init) },
            set: { _ in fullScreenImage = nil }
        )) { wrapper in
            FullScreenImageView(image: wrapper.image) {
                fullScreenImage = nil
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareView(activityItems: createShareItems())
        }
        .alert("Copied!", isPresented: $showingCopyConfirmation) {
            Button("OK") { }
        } message: {
            Text("Text was copied to clipboard")
        }
    }
    
    // Create share items including text and images
    private func createShareItems() -> [Any] {
        var items: [Any] = []
        
        // Add text content if available
        if !message.content.isEmpty {
            items.append(message.content)
        }
        
        // Add images if available
        items.append(contentsOf: message.images)
        
        return items
    }
}

struct ChatInputView: View {
    @ObservedObject var viewModel: ChatViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Selected Images Preview
            if !viewModel.selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: viewModel.selectedImages[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Button(action: {
                                    viewModel.removeImage(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .font(.system(size: 16))
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 70)
            }
            
            // Input Row
            HStack(spacing: 12) {
                // Image Selection Button
                ImageSelectionView(selectedImages: $viewModel.selectedImages)
                
                // Text Input
                HStack {
                    TextField("Type your message...", text: $viewModel.currentInput, axis: .vertical)
                        .focused($isTextFieldFocused)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .lineLimit(1...5)
                        .disabled(viewModel.isLoading)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "2e2e2e"))
                .cornerRadius(20)
                
                // Send Button
                Button(action: {
                    if viewModel.canSend {
                        viewModel.sendMessage()
                        isTextFieldFocused = false
                    }
                }) {
                    Image(systemName: "arrow.up")
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(viewModel.canSend ? .white : Color(hex: "9e9d99")))
                }
                .disabled(!viewModel.canSend)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(hex: "121419"))
    }
}

// MARK: - ReversedScrollView
struct ReversedScrollView<Content: View>: View {
    var content: Content
    
    init(@ViewBuilder builder: ()->Content) {
        self.content = builder()
    }
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                HStack {
                    Spacer()
                    content
                }
                .frame(minWidth: proxy.size.width)
            }
        }
    }
}

struct StreamingDots: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                    .scaleEffect(animating ? 1.2 : 0.8)
                    .opacity(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
        .onDisappear {
            animating = false
        }
    }
}
