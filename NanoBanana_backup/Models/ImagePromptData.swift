import Foundation

struct ImagePromptData: Codable, Identifiable {
    let id: UUID
    let imagePath: String
    let prompt: String
    let timestamp: Date
    
    init(imagePath: String, prompt: String) {
        self.id = UUID()
        self.imagePath = imagePath
        self.prompt = prompt
        self.timestamp = Date()
    }
}

struct ImagePromptCollection: Codable {
    var items: [ImagePromptData]
    let version: String
    
    init() {
        self.items = []
        self.version = "1.0"
    }
}