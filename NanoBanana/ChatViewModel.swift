import Foundation
import SwiftUI
import Combine

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let images: [UIImage]
    let isUser: Bool
    let timestamp: Date
    var isStreaming: Bool = false
}

// MARK: - Chat View Model
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var selectedImages: [UIImage] = []
    @Published var isLoading: Bool = false
    @Published var streamingText: String = ""
    @Published var errorMessage: String?
    
    private let apiService = GeminiAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
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
        
        // Clear input
        currentInput = ""
        selectedImages = []
        
        // Send to API with streaming
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
        
        apiService.generateContentStream(
            model: "gemini-2.5-flash-image-preview",
            prompt: prompt,
            images: images
        ) { [weak self] chunk in
            DispatchQueue.main.async {
                self?.handleStreamChunk(chunk)
            }
        } onComplete: { [weak self] error in
            DispatchQueue.main.async {
                self?.handleStreamComplete(error: error)
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
                messages[lastIndex] = ChatMessage(
                    content: streamingText,
                    images: result.images?.compactMap { base64String in
                        // Convert base64 to UIImage if needed
                        let cleanBase64 = base64String.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                            .replacingOccurrences(of: "data:image/png;base64,", with: "")
                        
                        if let data = Data(base64Encoded: cleanBase64) {
                            return UIImage(data: data)
                        }
                        return nil
                    } ?? [],
                    isUser: false,
                    timestamp: messages[lastIndex].timestamp,
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
                messages[lastIndex] = ChatMessage(
                    content: messages[lastIndex].content,
                    images: messages[lastIndex].images,
                    isUser: false,
                    timestamp: messages[lastIndex].timestamp,
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
                        images: response.images?.compactMap { base64String in
                            let cleanBase64 = base64String.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
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
        messages.removeAll()
        currentInput = ""
        selectedImages.removeAll()
        streamingText = ""
        errorMessage = nil
        isLoading = false
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