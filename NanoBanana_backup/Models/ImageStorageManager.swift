import Foundation
import UIKit

final class ImageStorageManager {
    static let shared = ImageStorageManager()
    
    private let documentsDirectory: URL
    private let imagesDirectory: URL
    
    private init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        imagesDirectory = documentsDirectory.appendingPathComponent("ChatImages", isDirectory: true)
        
        createImagesDirectoryIfNeeded()
    }
    
    private func createImagesDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create images directory: \(error)")
            }
        }
    }
    
    func saveImage(_ image: UIImage) -> String? {
        let imageId = UUID().uuidString
        let fileName = "\(imageId).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG data")
            return nil
        }
        
        do {
            try imageData.write(to: fileURL)
            return fileName
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    // MARK: - Load Image
    func loadImage(from fileName: String) -> UIImage? {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Image file doesn't exist: \(fileName)")
            return nil
        }
        
        guard let imageData = try? Data(contentsOf: fileURL) else {
            print("Failed to load image data from: \(fileName)")
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    // MARK: - Delete Image
    func deleteImage(fileName: String) {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print("Failed to delete image: \(fileName), error: \(error)")
        }
    }
    
    // MARK: - Save Multiple Images
    func saveImages(_ images: [UIImage]) -> [String] {
        return images.compactMap { saveImage($0) }
    }
    
    // MARK: - Load Multiple Images
    func loadImages(from fileNames: [String]) -> [UIImage] {
        return fileNames.compactMap { loadImage(from: $0) }
    }
    
    // MARK: - Cleanup Unused Images
    func cleanupUnusedImages(usedFileNames: Set<String>) {
        do {
            let allFiles = try FileManager.default.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil)
            
            for fileURL in allFiles {
                let fileName = fileURL.lastPathComponent
                if !usedFileNames.contains(fileName) {
                    try FileManager.default.removeItem(at: fileURL)
                    print("Deleted unused image: \(fileName)")
                }
            }
        } catch {
            print("Failed to cleanup unused images: \(error)")
        }
    }
    
    // MARK: - Get Storage Size
    func getStorageSize() -> Int64 {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: [.fileSizeKey])
            
            var totalSize: Int64 = 0
            for fileURL in files {
                let resources = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resources.fileSize ?? 0)
            }
            
            return totalSize
        } catch {
            print("Failed to calculate storage size: \(error)")
            return 0
        }
    }
    
    // MARK: - Remove Duplicate Images
    func removeDuplicateImages() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            // Group files by content (comparing image data)
            var imageHashes: [String: [URL]] = [:]
            
            for fileURL in files {
                if let imageData = try? Data(contentsOf: fileURL) {
                    let hash = imageData.hashValue.description
                    imageHashes[hash, default: []].append(fileURL)
                }
            }
            
            // Remove duplicates, keeping only the oldest file for each hash
            for (_, urls) in imageHashes {
                if urls.count > 1 {
                    // Sort by modification date and keep the first (oldest)
                    let sortedUrls = urls.sorted { url1, url2 in
                        let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                        let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                        return date1 < date2
                    }
                    
                    // Remove all but the first (oldest)
                    for duplicateUrl in sortedUrls.dropFirst() {
                        try FileManager.default.removeItem(at: duplicateUrl)
                        print("Removed duplicate image: \(duplicateUrl.lastPathComponent)")
                    }
                }
            }
        } catch {
            print("Failed to remove duplicate images: \(error)")
        }
    }
}
