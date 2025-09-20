import Foundation
import UIKit

class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory cache
        
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("ImageCache")
        
        createCacheDirectoryIfNeeded()
        cleanupOldFiles()
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func cleanupOldFiles() {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }
        
        for file in files {
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let creationDate = attributes[.creationDate] as? Date,
               creationDate < cutoffDate {
                try? fileManager.removeItem(at: file)
            }
        }
    }
    
    func getImage(from urlString: String) async -> UIImage? {
        let cacheKey = NSString(string: urlString)
        
        // Check memory cache first
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Check disk cache
        let filename = urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        let fileURL = cacheDirectory.appendingPathComponent("\(filename).jpg")
        
        if fileManager.fileExists(atPath: fileURL.path),
           let imageData = try? Data(contentsOf: fileURL),
           let image = UIImage(data: imageData) {
            // Add to memory cache
            cache.setObject(image, forKey: cacheKey)
            return image
        }
        
        // Download from network
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            
            // Save to disk cache
            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                try? jpegData.write(to: fileURL)
            }
            
            // Add to memory cache
            cache.setObject(image, forKey: cacheKey)
            
            return image
        } catch {
            print("❌ [ImageCacheManager] Error downloading image from \(urlString): \(error)")
            return nil
        }
    }
    
    func preloadImages(from urlStrings: [String]) {
        Task {
            await withTaskGroup(of: Void.self) { group in
                for urlString in urlStrings {
                    group.addTask {
                        _ = await self.getImage(from: urlString)
                    }
                }
            }
        }
    }
    
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        createCacheDirectoryIfNeeded()
    }
    
    func getCacheSize() -> String {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return "0 MB"
        }
        
        let totalSize = files.compactMap { file in
            try? fileManager.attributesOfItem(atPath: file.path)[.size] as? Int64
        }.reduce(0, +)
        
        let sizeInMB = Double(totalSize) / (1024 * 1024)
        return String(format: "%.1f MB", sizeInMB)
    }
}