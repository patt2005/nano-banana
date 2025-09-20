import Foundation
import UIKit

class ImagePromptManager: ObservableObject {
    static let shared = ImagePromptManager()
    
    @Published var imagePrompts: [ImagePromptData] = []
    
    private let documentsDirectory: URL
    private let jsonFileURL: URL
    private let imagesDirectory: URL
    
    private init() {
        // Setup directories
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        jsonFileURL = documentsDirectory.appendingPathComponent("imagePrompts.json")
        imagesDirectory = documentsDirectory.appendingPathComponent("SavedImages")
        
        // Create images directory if it doesn't exist
        createImagesDirectoryIfNeeded()
        
        // Load existing data
        // loadImagePrompts() // Disabled for now
    }
    
    private func createImagesDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
            try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - JSON Operations
    
    func saveImagePrompts() {
        // Simple JSON save without complex encoding
    }
    
    func loadImagePrompts() {
        // Simple load without complex decoding
    }
    
    // MARK: - Image Management
    
    func saveImage(_ image: UIImage, withPrompt prompt: String) -> String? {
        let imageFileName = "\(UUID().uuidString).jpg"
        let imageURL = imagesDirectory.appendingPathComponent(imageFileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to data")
            return nil
        }
        
        do {
            try imageData.write(to: imageURL)
            
            // Create image prompt data
            let imagePromptData = ImagePromptData(
                imagePath: imageFileName, // Store relative path
                prompt: prompt
            )
            
            // Add to collection
            imagePrompts.append(imagePromptData)
            
            // Image saved without JSON operations
            
            print("✅ Successfully saved image: \(imageFileName) with prompt: \(prompt)")
            return imageFileName
        } catch {
            print("❌ Error saving image: \(error)")
            return nil
        }
    }
    
    func loadImage(from fileName: String) -> UIImage? {
        let imageURL = imagesDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: imageURL.path)
    }
    
    func getFullImagePath(for fileName: String) -> String {
        return imagesDirectory.appendingPathComponent(fileName).path
    }
    
    // MARK: - Data Management
    
    func addImagePrompt(imagePath: String, prompt: String) {
        let newItem = ImagePromptData(imagePath: imagePath, prompt: prompt)
        imagePrompts.append(newItem)
        // No JSON save
    }
    
    func removeImagePrompt(withId id: UUID) {
        if let index = imagePrompts.firstIndex(where: { $0.id == id }) {
            let item = imagePrompts[index]
            
            // Delete the image file
            let imageURL = imagesDirectory.appendingPathComponent(item.imagePath)
            try? FileManager.default.removeItem(at: imageURL)
            
            // Remove from collection
            imagePrompts.remove(at: index)
            // No JSON save
            
            print("✅ Removed image prompt: \(item.imagePath)")
        }
    }
    
    func clearAllData() {
        // Remove all image files
        let fileManager = FileManager.default
        if let files = try? fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
        
        // Clear the collection
        imagePrompts.removeAll()
        // No JSON save
        
        print("✅ Cleared all image prompt data")
    }
    
    // MARK: - Export Functions
    
    func exportToJSON() -> Data? {
        return nil // Disabled
    }
    
    func exportPrettyJSON() -> String? {
        return "Export disabled" // Simple return
    }
    
    // MARK: - Debug Functions
    
    func printAllImagePrompts() {
        print("\n📋 Current Image Prompts:")
        print("Total items: \(imagePrompts.count)")
        
        for (index, item) in imagePrompts.enumerated() {
            print("\n\(index + 1). ID: \(item.id)")
            print("   Image Path: \(item.imagePath)")
            print("   Prompt: \(item.prompt)")
            print("   Timestamp: \(item.timestamp)")
        }
        print("\n")
    }
}