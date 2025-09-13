import Foundation
import SwiftUI
import Combine

final class ChatMessage: Identifiable, ObservableObject {
    let id: UUID
    @Published var content: String
    let images: [UIImage]
    let imageFileNames: [String]
    let isUser: Bool
    let timestamp: Date
    @Published var isStreaming: Bool = false
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let decodedId = try container.decode(UUID.self, forKey: .id)
        let decodedContent = try container.decode(String.self, forKey: .content)
        let decodedIsUser = try container.decode(Bool.self, forKey: .isUser)
        let decodedTimestamp = try container.decode(Date.self, forKey: .timestamp)
        let decodedIsStreaming = try container.decodeIfPresent(Bool.self, forKey: .isStreaming) ?? false
        let decodedImageFileNames = try container.decodeIfPresent([String].self, forKey: .imageFileNames) ?? []
        
        self.init(
            id: decodedId,
            content: decodedContent,
            imageFileNames: decodedImageFileNames,
            isUser: decodedIsUser,
            timestamp: decodedTimestamp,
            isStreaming: decodedIsStreaming
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(isUser, forKey: .isUser)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isStreaming, forKey: .isStreaming)
        
        try container.encode(imageFileNames, forKey: .imageFileNames)
    }
    
    init(content: String, images: [UIImage], isUser: Bool, timestamp: Date, isStreaming: Bool = true) {
        self.id = UUID()
        self.content = content
        self.images = images
        self.isUser = isUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        
        self.imageFileNames = ImageStorageManager.shared.saveImages(images)
    }
    
    init(id: UUID, content: String, imageFileNames: [String], isUser: Bool, timestamp: Date, isStreaming: Bool = false) {
        self.id = id
        self.content = content
        self.imageFileNames = imageFileNames
        self.isUser = isUser
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        
        self.images = ImageStorageManager.shared.loadImages(from: imageFileNames)
    }
    
    func updatedMessage(content: String, images: [UIImage], isStreaming: Bool) -> ChatMessage {
        let newImageFileNames: [String]
        if images.count != self.images.count {
            newImageFileNames = ImageStorageManager.shared.saveImages(images)
        } else {
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
    @Published var errorMessage: String?
    @Published var chatHistories: [ChatHistory] = []
    @Published var currentChatHistory: ChatHistory?
    
    private let apiService = GeminiAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let chatHistoriesKey = "savedChatHistories"
    private let freeMessagesCountKey = "freeMessagesCount"
    private let lastResetDateKey = "lastResetDate"
    
    private let freeUserMessageLimit = 2
    @Published private var totalFreeMessagesUsed: Int = 0
    
    init() {
        loadChatHistories()
        loadFreeMessageCount()
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
        
        if !SubscriptionManager.shared.hasActiveSubscription {
            totalFreeMessagesUsed += 1
            saveFreeMessageCount()
        }
        
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
    
    private func sendStreamingRequest(prompt: String, images: [UIImage]) {
        isLoading = true
        errorMessage = nil
        
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
            if let lastIndex = messages.indices.last, !messages[lastIndex].isUser {
                let processedImages: [UIImage] = result.images?.compactMap { imageResult in
                    guard let imageDataString = imageResult.imageData else { return nil }

                    let cleanBase64 = imageDataString.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                        .replacingOccurrences(of: "data:image/png;base64,", with: "")

                    if let data = Data(base64Encoded: cleanBase64) {
                        return UIImage(data: data)
                    }
                    return nil
                } ?? []

                DispatchQueue.main.async {
                    self.messages[lastIndex].content += text

                    // Add images to the message if we received any
                    if !processedImages.isEmpty {
                        let updatedMessage = self.messages[lastIndex].updatedMessage(
                            content: self.messages[lastIndex].content,
                            images: self.messages[lastIndex].images + processedImages,
                            isStreaming: self.messages[lastIndex].isStreaming
                        )
                        self.messages[lastIndex] = updatedMessage
                    }
                }
            }
        }
    }
    
    private func handleStreamComplete(error: Error?) {
        isLoading = false
        
        if let error = error {
            errorMessage = error.localizedDescription
            
            if let lastIndex = messages.indices.last, !messages[lastIndex].isUser && messages[lastIndex].content.isEmpty {
                messages.remove(at: lastIndex)
            }
        } else {
            if let lastIndex = messages.indices.last, !messages[lastIndex].isUser {
                messages[lastIndex].isStreaming = false
                print("📝 Final message content: '\(messages[lastIndex].content)'")
            }
        }
    }
    
    func clearChat() {
        if let currentChat = currentChatHistory, !currentChat.isEmpty {
            saveChatToHistory(currentChat)
        }
        
        messages.removeAll()
        currentInput = ""
        selectedImages.removeAll()
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

extension ChatViewModel {
    var hasContent: Bool {
        return !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty
    }
    
    var canSend: Bool {
        return hasContent && !isLoading && !isMessageLimitExceeded
    }
    
    var isMessageLimitExceeded: Bool {
        return totalFreeMessagesUsed >= freeUserMessageLimit
    }
    
    var remainingFreeMessages: Int {
        let isSubscribed = SubscriptionManager.shared.hasActiveSubscription
        if isSubscribed {
            return Int.max // No limit for subscribers
        }
        
        return max(0, freeUserMessageLimit - totalFreeMessagesUsed)
    }
}

extension ChatViewModel {
    
    private func loadFreeMessageCount() {
        totalFreeMessagesUsed = userDefaults.integer(forKey: freeMessagesCountKey)
        print("📊 Loaded free message count: \(totalFreeMessagesUsed)")
    }
    
    private func saveFreeMessageCount() {
        userDefaults.set(totalFreeMessagesUsed, forKey: freeMessagesCountKey)
        print("📊 Saved free message count: \(totalFreeMessagesUsed)")
    }
    
    func resetFreeMessageCount() {
        totalFreeMessagesUsed = 0
        saveFreeMessageCount()
        print("📊 Reset free message count")
    }
    
    // Call this when user subscribes to reset their count
    func handleSubscriptionActivated() {
        resetFreeMessageCount()
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
