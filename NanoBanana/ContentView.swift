import SwiftUI
import PhotosUI

struct Message {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
    let image: UIImage?
}

struct ContentView: View {
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var selectedUIImage: UIImage? = nil
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Good morning")
                        .font(.title)
                        .fontWeight(.light)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Suggestions/Recent section
                VStack(alignment: .leading, spacing: 16) {
                    // Suggestion cards
                    HStack(spacing: 12) {
                        SuggestionCard(title: "Compare the differences between pickleball and tennis")
                        SuggestionCard(title: "Ideas to surprise a friend on their birthday")
                        SuggestionCard(title: "Finish my podcast setup")
                    }
                    .padding(.horizontal, 20)
                    
                    // Recent section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent")
                                .font(.headline)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        VStack(spacing: 8) {
                            RecentItem(title: "Green vs. Oolong Tea: Processing & Flavor")
                            RecentItem(title: "LLM architecture")
                            RecentItem(title: "How Wet Are Rainforests?")
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Chat messages area
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages, id: \.id) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Input area
                VStack(spacing: 0) {
                    if let selectedUIImage = selectedUIImage {
                        HStack {
                            Image(uiImage: selectedUIImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Spacer()
                            
                            Button("Remove") {
                                selectedUIImage = nil
                                selectedImage = nil
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    
                    HStack(spacing: 12) {
                        // Text input
                        HStack(spacing: 8) {
                            TextField("Type, talk, or share a photo", text: $messageText)
                                .textFieldStyle(.plain)
                            
                            Button(action: {
                                showImagePicker = true
                            }) {
                                Image(systemName: "camera")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        
                        // Send button
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(messageText.isEmpty && selectedUIImage == nil ? .gray : AppColors.primary)
                        }
                        .disabled(messageText.isEmpty && selectedUIImage == nil)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                }
            }
            .background(Color.white)
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedImage)
        .onChange(of: selectedImage) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedUIImage = UIImage(data: data)
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty || selectedUIImage != nil else { return }
        
        let message = Message(
            text: messageText,
            isUser: true,
            timestamp: Date(),
            image: selectedUIImage
        )
        
        messages.append(message)
        messageText = ""
        selectedUIImage = nil
        selectedImage = nil
        
        // TODO: Add Gemini AI API call here
        simulateAIResponse()
    }
    
    private func simulateAIResponse() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let response = Message(
                text: "Hello! I'm your Google Nano Banana AI assistant. How can I help you today?",
                isUser: false,
                timestamp: Date(),
                image: nil
            )
            messages.append(response)
        }
    }
}

struct SuggestionCard: View {
    let title: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(width: 100, height: 80)
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RecentItem: View {
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: "clock")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.body)
                        .foregroundColor(message.isUser ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(message.isUser ? AppColors.primary : Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}
