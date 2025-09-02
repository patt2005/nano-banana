import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack {
                        Text("🍌")
                            .font(.title2)
                        Text("NanoBanana Chat")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button("Clear") {
                        viewModel.clearChat()
                    }
                    .foregroundColor(.white)
                }
                .padding()
                .background(Color(hex: "121419"))
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .background(Color(hex: "121419"))
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.streamingText) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                        
                        Spacer()
                        
                        Button("Retry") {
                            viewModel.retryLastMessage()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(hex: "2e2e2e"))
                }
                
                // Input Area
                ChatInputView(viewModel: viewModel)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
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
    
    var body: some View {
        VStack(alignment: .trailing) {
            // Images
            if !message.images.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(message.images.indices, id: \.self) { index in
                        Image(uiImage: message.images[index])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.bottom, 8)
            }
            
            // Text
            if !message.content.isEmpty {
                Text(message.content)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(Color(hex: "9e9d99"))
                .padding(.trailing, 8)
        }
    }
}

struct AIMessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Text("🤖")
                    .font(.title2)
                    .padding(.top, 4)
                
                VStack(alignment: .leading) {
                    // Text with streaming indicator
                    HStack {
                        if !message.content.isEmpty {
                            Text(message.content)
                                .foregroundColor(.white)
                        }
                        
                        if message.isStreaming {
                            Text("●")
                                .foregroundColor(.green)
                                .font(.caption)
                                .animation(.easeInOut(duration: 0.8).repeatForever(), value: message.isStreaming)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(hex: "2e2e2e"))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    // AI Generated Images
                    if !message.images.isEmpty {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(message.images.indices, id: \.self) { index in
                                Image(uiImage: message.images[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(Color(hex: "9e9d99"))
                        .padding(.leading, 16)
                }
            }
        }
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

// MARK: - Helper Functions
private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

#Preview {
    ChatView(viewModel: ChatViewModel())
}