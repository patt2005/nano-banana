import Foundation
import UIKit

class ImagePromptManager: ObservableObject {
    static let shared = ImagePromptManager()

    @Published var imagePrompts: [ImagePromptData] = []
    @Published var galleryHistory: [GalleryHistoryItem] = []

    private let documentsDirectory: URL
    private let jsonFileURL: URL
    private let galleryHistoryFileURL: URL
    private let imagesDirectory: URL

    private init() {
        // Setup directories
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        jsonFileURL = documentsDirectory.appendingPathComponent("imagePrompts.json")
        galleryHistoryFileURL = documentsDirectory.appendingPathComponent("galleryHistory.json")
        imagesDirectory = documentsDirectory.appendingPathComponent("SavedImages")

        // Create images directory if it doesn't exist
        createImagesDirectoryIfNeeded()

        // Load existing data
        loadGalleryHistory()
    }
    
    private func createImagesDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
            try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - JSON Operations

    func saveGalleryHistory() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        do {
            let history = GalleryHistory(items: galleryHistory)
            let data = try encoder.encode(history)
            try data.write(to: galleryHistoryFileURL)
            print("✅ Gallery history saved: \(galleryHistory.count) items")
        } catch {
            print("❌ Failed to save gallery history: \(error)")
        }
    }

    func loadGalleryHistory() {
        guard FileManager.default.fileExists(atPath: galleryHistoryFileURL.path) else {
            print("ℹ️ No gallery history file found")
            return
        }

        do {
            let data = try Data(contentsOf: galleryHistoryFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let history = try decoder.decode(GalleryHistory.self, from: data)
            galleryHistory = history.items

            print("✅ Loaded \(galleryHistory.count) gallery items")
        } catch {
            print("❌ Failed to load gallery history: \(error)")
        }
    }
    
    // MARK: - Image Management
    
    func saveImage(_ image: UIImage, withPrompt prompt: String, originalImagePath: String? = nil) -> String? {
        let imageFileName = "\(UUID().uuidString).jpg"
        let imageURL = imagesDirectory.appendingPathComponent(imageFileName)

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to data")
            return nil
        }

        do {
            try imageData.write(to: imageURL)

            // Create image prompt data for backward compatibility
            let imagePromptData = ImagePromptData(
                imagePath: imageFileName, // Store relative path
                prompt: prompt
            )

            // Add to collection
            imagePrompts.append(imagePromptData)

            // Create gallery history item
            let galleryItem = GalleryHistoryItem(
                imagePath: imageFileName,
                prompt: prompt,
                isAIGenerated: true,
                originalImagePath: originalImagePath
            )

            // Add to gallery history
            galleryHistory.insert(galleryItem, at: 0) // Insert at beginning for newest first

            // Save gallery history to JSON
            saveGalleryHistory()

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

            print("✅ Removed image prompt: \(item.imagePath)")
        }
    }

    func removeGalleryHistoryItem(withId id: UUID) {
        if let index = galleryHistory.firstIndex(where: { $0.id == id }) {
            let item = galleryHistory[index]

            // Delete the image file
            let imageURL = imagesDirectory.appendingPathComponent(item.imagePath)
            try? FileManager.default.removeItem(at: imageURL)

            // Remove from gallery history
            galleryHistory.remove(at: index)

            // Save updated history
            saveGalleryHistory()

            // Also remove from imagePrompts if exists
            if let promptIndex = imagePrompts.firstIndex(where: { $0.imagePath == item.imagePath }) {
                imagePrompts.remove(at: promptIndex)
            }

            print("✅ Removed gallery item: \(item.imagePath)")
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

        // Clear both collections
        imagePrompts.removeAll()
        galleryHistory.removeAll()

        // Save empty gallery history
        saveGalleryHistory()

        print("✅ Cleared all image prompt and gallery data")
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