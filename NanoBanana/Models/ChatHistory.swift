import Foundation
import SwiftUI

struct ChatHistory: Identifiable, Codable {
    let id: UUID
    let date: Date
    var messages: [ChatMessage]
    var title: String
    
    init(id: UUID = UUID(), date: Date = Date(), messages: [ChatMessage] = [], title: String = "") {
        self.id = id
        self.date = date
        self.messages = messages
        self.title = title.isEmpty ? Self.generateTitle(from: messages) : title
    }
    
    private static func generateTitle(from messages: [ChatMessage]) -> String {
        if let firstUserMessage = messages.first(where: { $0.isUser && !$0.content.isEmpty }) {
            let content = firstUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if content.count > 30 {
                return String(content.prefix(30)) + "..."
            }
            return content
        }
        return "New Chat"
    }
    
    mutating func updateTitle() {
        self.title = Self.generateTitle(from: messages)
    }
    
    // Add a new message to this chat history
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        updateTitle()
    }
    
    // Get the last message timestamp for sorting
    var lastMessageDate: Date {
        return messages.last?.timestamp ?? date
    }
    
    // Check if this chat has any messages
    var isEmpty: Bool {
        return messages.isEmpty
    }
    
    // Get a preview of the last message for display
    var lastMessagePreview: String {
        guard let lastMessage = messages.last else { return "No messages" }
        
        if lastMessage.isUser {
            if !lastMessage.content.isEmpty {
                return lastMessage.content.count > 50 ? 
                    String(lastMessage.content.prefix(50)) + "..." : 
                    lastMessage.content
            } else if !lastMessage.images.isEmpty {
                return "📷 Photo"
            }
            return "User message"
        } else {
            return lastMessage.content.count > 50 ? 
                String(lastMessage.content.prefix(50)) + "..." : 
                lastMessage.content
        }
    }
}

// MARK: - Extended ChatMessage for Codable support
extension ChatMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case id, content, isUser, timestamp, isStreaming
        case imageFileNames
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let decodedId = try container.decode(UUID.self, forKey: .id)
        let decodedContent = try container.decode(String.self, forKey: .content)
        let decodedIsUser = try container.decode(Bool.self, forKey: .isUser)
        let decodedTimestamp = try container.decode(Date.self, forKey: .timestamp)
        let decodedIsStreaming = try container.decodeIfPresent(Bool.self, forKey: .isStreaming) ?? false
        let decodedImageFileNames = try container.decodeIfPresent([String].self, forKey: .imageFileNames) ?? []
        
        // Use the designated initializer for loading from storage
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
        
        // Encode image file names instead of image data
        try container.encode(imageFileNames, forKey: .imageFileNames)
    }
}
