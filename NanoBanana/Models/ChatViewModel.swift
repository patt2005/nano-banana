import Foundation
import SwiftUI
import Combine

struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let images: [UIImage]
    let imageFileNames: [String] // Store file paths for persistence
    let isUser: Bool
    let timestamp: Date
    var isStreaming: Bool = false
    
    init(content: String, images: [UIImage], isUser: Bool, timestamp: Date, isStreaming: Bool = true) {
        self.id = UUID()
        self.content = content
        self.images = images
        self.isUser = isUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        
        // Save images to local storage and store file names
        self.imageFileNames = ImageStorageManager.shared.saveImages(images)
    }
    
    // Initialize from stored data (when loading from chat history)
    init(id: UUID, content: String, imageFileNames: [String], isUser: Bool, timestamp: Date, isStreaming: Bool = false) {
        self.id = id
        self.content = content
        self.imageFileNames = imageFileNames
        self.isUser = isUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        
        // Load images from local storage
        self.images = ImageStorageManager.shared.loadImages(from: imageFileNames)
    }
    
    // Create updated message for streaming (preserves ID and timestamp)
    func updatedMessage(content: String, images: [UIImage], isStreaming: Bool) -> ChatMessage {
        // Only save new images if they're different from existing ones
        let newImageFileNames: [String]
        if images.count != self.images.count {
            // Images changed, save new ones
            newImageFileNames = ImageStorageManager.shared.saveImages(images)
        } else {
            // Same number of images, keep existing file names
            newImageFileNames = self.imageFileNames
        }
        
        return ChatMessage(
            id: self.id,
            content: content,
            images: images,
            imageFileNames: newImageFileNames,
            isUser: self.isUser,
            timestamp: self.timestamp,
            isStreaming: isStreaming
        )
    }
    
    // Private initializer for internal updates
    private init(id: UUID, content: String, images: [UIImage], imageFileNames: [String], isUser: Bool, timestamp: Date, isStreaming: Bool) {
        self.id = id
        self.content = content
        self.images = images
        self.imageFileNames = imageFileNames
        self.isUser = isUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
}

final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var selectedImages: [UIImage] = []
    @Published var isLoading: Bool = false
    @Published var streamingText: String = ""
    @Published var errorMessage: String?
    @Published var chatHistories: [ChatHistory] = []
    @Published var currentChatHistory: ChatHistory?
    
    private let apiService = GeminiAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let chatHistoriesKey = "savedChatHistories"
    
    init() {
        loadChatHistories()
        createNewChatIfNeeded()
        
        DispatchQueue.global(qos: .background).async {
            ImageStorageManager.shared.removeDuplicateImages()
        }
    }
    
    func sendMessage() {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty else { return }
        
        let userMessage = ChatMessage(
            content: currentInput,
            images: selectedImages,
            isUser: true,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        
        let inputText = currentInput
        let inputImages = selectedImages
        
        currentInput = ""
        selectedImages = []
        
        sendStreamingRequest(prompt: inputText, images: inputImages)
    }
    
    func addImage(_ image: UIImage) {
        selectedImages.append(image)
    }
    
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
    }
    
    func clearImages() {
        selectedImages.removeAll()
    }
    
    // MARK: - Private Methods
    private func sendStreamingRequest(prompt: String, images: [UIImage]) {
        isLoading = true
        streamingText = ""
        errorMessage = nil
        
        // Create placeholder message for AI response
        let aiMessage = ChatMessage(
            content: "",
            images: [],
            isUser: false,
            timestamp: Date(),
            isStreaming: true
        )
        messages.append(aiMessage)
        
        Task {
            do {
                let stream = try await apiService.generateContentStream(
                    model: "gemini-2.5-flash-image-preview",
                    prompt: prompt,
                    images: images
                )
                
                for try await chunk in stream {
                    await MainActor.run {
                        self.handleStreamChunk(chunk)
                    }
                }
                
                await MainActor.run {
                    self.handleStreamComplete(error: nil)
                    self.updateCurrentChatHistory()
                }
            } catch {
                await MainActor.run {
                    self.handleStreamComplete(error: error)
                }
            }
        }
    }
    
    private func handleStreamChunk(_ chunk: StreamChunk) {
        if let error = chunk.error {
            errorMessage = error
            isLoading = false
            return
        }
        
        if let result = chunk.result, let text = result.text {
            streamingText += text
            
            // Update the last message (AI response) with streaming text
            if let lastIndex = messages.indices.last, !messages[lastIndex].isUser {
                let processedImages: [UIImage] = result.images?.compactMap { imageResult in
                    // Get the image data from the result
                    guard let imageDataString = imageResult.imageData else { return nil }
                    
                    // Convert base64 to UIImage if needed
                    let cleanBase64 = imageDataString.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                        .replacingOccurrences(of: "data:image/png;base64,", with: "")
                    
                    if let data = Data(base64Encoded: cleanBase64) {
                        return UIImage(data: data)
                    }
                    return nil
                } ?? []
                
                print("🖼️ Processing images in stream: \(result.images?.count ?? 0) ImageResults, converted to \(processedImages.count) UIImages")
                
                // Use updatedMessage to preserve ID and timestamp while adding new content/images
                // Only add new images if we have processed any new ones
                let updatedImages = processedImages.isEmpty ? messages[lastIndex].images : processedImages
                messages[lastIndex] = messages[lastIndex].updatedMessage(
                    content: streamingText,
                    images: updatedImages,
                    isStreaming: true
                )
            }
        }
    }
    
    private func handleStreamComplete(error: Error?) {
        isLoading = false
        
        if let error = error {
            errorMessage = error.localizedDescription
            
            // Remove the placeholder message if there was an error
            if let lastIndex = messages.indices.last, !messages[lastIndex].isUser && messages[lastIndex].content.isEmpty {
                messages.remove(at: lastIndex)
            }
        } else {
            // Mark streaming as complete
            if let lastIndex = messages.indices.last, !messages[lastIndex].isUser {
                messages[lastIndex] = messages[lastIndex].updatedMessage(
                    content: messages[lastIndex].content,
                    images: messages[lastIndex].images,
                    isStreaming: false
                )
            }
        }
        
        streamingText = ""
    }
    
    // MARK: - Non-Streaming Alternative
    func sendNonStreamingMessage() {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty else { return }
        
        let userMessage = ChatMessage(
            content: currentInput,
            images: selectedImages,
            isUser: true,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        
        let inputText = currentInput
        let inputImages = selectedImages
        
        currentInput = ""
        selectedImages = []
        isLoading = true
        errorMessage = nil
        
        apiService.generateContent(
            model: "gemini-2.5-flash-image-preview",
            prompt: inputText,
            images: inputImages,
            stream: false
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    let aiMessage = ChatMessage(
                        content: response.text ?? "",
                        images: response.images?.compactMap { imageResult in
                            guard let imageDataString = imageResult.imageData else { return nil }
                            
                            let cleanBase64 = imageDataString.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                                .replacingOccurrences(of: "data:image/png;base64,", with: "")
                            
                            if let data = Data(base64Encoded: cleanBase64) {
                                return UIImage(data: data)
                            }
                            return nil
                        } ?? [],
                        isUser: false,
                        timestamp: Date()
                    )
                    self?.messages.append(aiMessage)
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    func clearChat() {
        // Save current chat to history before clearing if it has messages
        if let currentChat = currentChatHistory, !currentChat.isEmpty {
            saveChatToHistory(currentChat)
        }
        
        // Clear current state
        messages.removeAll()
        currentInput = ""
        selectedImages.removeAll()
        streamingText = ""
        errorMessage = nil
        isLoading = false
        
        // Start a new chat session
        currentChatHistory = ChatHistory()
    }
    
    func retryLastMessage() {
        guard let lastUserMessage = messages.last(where: { $0.isUser }) else { return }
        
        // Remove any AI responses after the last user message
        if let lastUserIndex = messages.lastIndex(where: { $0.isUser }) {
            let messagesToRemove = messages.count - lastUserIndex - 1
            messages.removeLast(messagesToRemove)
        }
        
        sendStreamingRequest(prompt: lastUserMessage.content, images: lastUserMessage.images)
    }
}

// MARK: - Extensions
extension ChatViewModel {
    var hasContent: Bool {
        return !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty
    }
    
    var canSend: Bool {
        return hasContent && !isLoading
    }
}

// MARK: - Chat History Management
extension ChatViewModel {
    
    // Load chat histories from UserDefaults
    func loadChatHistories() {
        if let data = userDefaults.data(forKey: chatHistoriesKey),
           let histories = try? JSONDecoder().decode([ChatHistory].self, from: data) {
            chatHistories = histories.sorted { $0.lastMessageDate > $1.lastMessageDate }
        }
    }
    
    // Save chat histories to UserDefaults
    func saveChatHistories() {
        if let data = try? JSONEncoder().encode(chatHistories) {
            userDefaults.set(data, forKey: chatHistoriesKey)
        }
    }
    
    // Create a new chat session if needed
    func createNewChatIfNeeded() {
        if currentChatHistory == nil {
            currentChatHistory = ChatHistory()
        }
    }
    
    // Start a new chat session
    func startNewChat() {
        // Save current chat if it has messages
        if let currentChat = currentChatHistory, !currentChat.isEmpty {
            saveChatToHistory(currentChat)
        }
        
        // Clear current messages and start new chat
        messages.removeAll()
        currentInput = ""
        selectedImages.removeAll()
        streamingText = ""
        errorMessage = nil
        isLoading = false
        
        // Create new chat history
        currentChatHistory = ChatHistory()
    }
    
    // Load an existing chat from history
    func loadChatFromHistory(_ chatHistory: ChatHistory) {
        // Save current chat if it has messages
        if let currentChat = currentChatHistory, !currentChat.isEmpty {
            saveChatToHistory(currentChat)
        }
        
        // Load the selected chat
        currentChatHistory = chatHistory
        messages = chatHistory.messages
        currentInput = ""
        selectedImages.removeAll()
        streamingText = ""
        errorMessage = nil
        isLoading = false
    }
    
    // Save current chat to history
    func saveChatToHistory(_ chatHistory: ChatHistory) {
        var updatedChat = chatHistory
        updatedChat.messages = messages
        updatedChat.updateTitle()
        
        // Check if this chat already exists in history
        if let existingIndex = chatHistories.firstIndex(where: { $0.id == updatedChat.id }) {
            chatHistories[existingIndex] = updatedChat
        } else {
            chatHistories.insert(updatedChat, at: 0)
        }
        
        // Keep only the last 50 chat histories
        if chatHistories.count > 50 {
            chatHistories = Array(chatHistories.prefix(50))
        }
        
        // Sort by last message date
        chatHistories.sort { $0.lastMessageDate > $1.lastMessageDate }
        saveChatHistories()
    }
    
    // Update current chat with new message and save
    func updateCurrentChatHistory() {
        guard var currentChat = currentChatHistory else { return }
        currentChat.messages = messages
        currentChat.updateTitle()
        currentChatHistory = currentChat
        
        // Auto-save to persistent storage
        saveChatToHistory(currentChat)
    }
    
    // Delete a chat from history
    func deleteChatHistory(at indexSet: IndexSet) {
        chatHistories.remove(atOffsets: indexSet)
        saveChatHistories()
    }
    
    // Delete a specific chat by ID
    func deleteChatHistory(withId id: UUID) {
        chatHistories.removeAll { $0.id == id }
        saveChatHistories()
    }
    
    // Clear all chat histories
    func clearAllChatHistories() {
        chatHistories.removeAll()
        saveChatHistories()
    }
}
