import Foundation
import UIKit

// MARK: - Data Models
struct GeminiRequest {
    let model: String
    let contents: String
    let stream: Bool
    let images: [UIImage]
}

struct GeminiResponse: Codable {
    let text: String?
    let images: [String]?
    let model: String?
    let usage: Usage?
    let error: String?
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

struct StreamChunk: Codable {
    let result: ChunkResult?
    let model: String?
    let done: Bool?
    let error: String?
}

struct ChunkResult: Codable {
    let text: String?
    let images: [String]?
}

// MARK: - API Service
class GeminiAPIService: ObservableObject {
    static let shared = GeminiAPIService()
    
    private let baseURL = "https://nano-banana-api-164860087792.us-central1.run.app"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Main API Call Method
    func generateContent(
        model: String = "gemini-2.5-flash-image-preview",
        prompt: String,
        images: [UIImage] = [],
        stream: Bool = false,
        completion: @escaping (Result<GeminiResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/v1/generate") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if !images.isEmpty {
            // Use multipart form data for image uploads
            sendMultipartRequest(
                request: request,
                model: model,
                prompt: prompt,
                images: images,
                stream: stream,
                completion: completion
            )
        } else {
            // Use JSON for text-only requests
            sendJSONRequest(
                request: request,
                model: model,
                prompt: prompt,
                stream: stream,
                completion: completion
            )
        }
    }
    
    // MARK: - Streaming API Call
    func generateContentStream(
        model: String = "gemini-2.5-flash-image-preview",
        prompt: String,
        images: [UIImage] = [],
        onChunk: @escaping (StreamChunk) -> Void,
        onComplete: @escaping (Error?) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/v1/generate") else {
            onComplete(APIError.invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if !images.isEmpty {
            sendMultipartStreamRequest(
                request: request,
                model: model,
                prompt: prompt,
                images: images,
                onChunk: onChunk,
                onComplete: onComplete
            )
        } else {
            sendJSONStreamRequest(
                request: request,
                model: model,
                prompt: prompt,
                onChunk: onChunk,
                onComplete: onComplete
            )
        }
    }
    
    // MARK: - Private Methods - Multipart Form Data
    private func sendMultipartRequest(
        request: URLRequest,
        model: String,
        prompt: String,
        images: [UIImage],
        stream: Bool,
        completion: @escaping (Result<GeminiResponse, Error>) -> Void
    ) {
        var mutableRequest = request
        let boundary = UUID().uuidString
        mutableRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(model)\r\n".data(using: .utf8)!)
        
        // Add prompt parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(prompt)\r\n".data(using: .utf8)!)
        
        // Add stream parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"stream\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(stream)\r\n".data(using: .utf8)!)
        
        // Add images
        for (index, image) in images.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"image\(index)\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        mutableRequest.httpBody = body
        
        if stream {
            // Handle streaming response
            handleStreamingResponse(request: mutableRequest) { chunk in
                // Convert streaming chunk to non-streaming response for compatibility
                if let chunk = chunk.result {
                    let response = GeminiResponse(
                        text: chunk.text,
                        images: chunk.images,
                        model: model,
                        usage: nil,
                        error: nil
                    )
                    completion(.success(response))
                }
            } onComplete: { error in
                if let error = error {
                    completion(.failure(error))
                }
            }
        } else {
            // Handle regular response
            session.dataTask(with: mutableRequest) { data, response, error in
                DispatchQueue.main.async {
                    self.handleResponse(data: data, response: response, error: error, completion: completion)
                }
            }.resume()
        }
    }
    
    // MARK: - Private Methods - JSON Request
    private func sendJSONRequest(
        request: URLRequest,
        model: String,
        prompt: String,
        stream: Bool,
        completion: @escaping (Result<GeminiResponse, Error>) -> Void
    ) {
        var mutableRequest = request
        mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "model": model,
            "contents": prompt,
            "stream": stream
        ] as [String : Any]
        
        do {
            mutableRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        if stream {
            handleStreamingResponse(request: mutableRequest) { chunk in
                if let chunk = chunk.result {
                    let response = GeminiResponse(
                        text: chunk.text,
                        images: chunk.images,
                        model: model,
                        usage: nil,
                        error: nil
                    )
                    completion(.success(response))
                }
            } onComplete: { error in
                if let error = error {
                    completion(.failure(error))
                }
            }
        } else {
            session.dataTask(with: mutableRequest) { data, response, error in
                DispatchQueue.main.async {
                    self.handleResponse(data: data, response: response, error: error, completion: completion)
                }
            }.resume()
        }
    }
    
    // MARK: - Streaming Methods
    private func sendMultipartStreamRequest(
        request: URLRequest,
        model: String,
        prompt: String,
        images: [UIImage],
        onChunk: @escaping (StreamChunk) -> Void,
        onComplete: @escaping (Error?) -> Void
    ) {
        var mutableRequest = request
        let boundary = UUID().uuidString
        mutableRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add parameters (same as above)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(model)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(prompt)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"stream\"\r\n\r\n".data(using: .utf8)!)
        body.append("true\r\n".data(using: .utf8)!)
        
        for (index, image) in images.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"image\(index)\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        mutableRequest.httpBody = body
        
        handleStreamingResponse(request: mutableRequest, onChunk: onChunk, onComplete: onComplete)
    }
    
    private func sendJSONStreamRequest(
        request: URLRequest,
        model: String,
        prompt: String,
        onChunk: @escaping (StreamChunk) -> Void,
        onComplete: @escaping (Error?) -> Void
    ) {
        var mutableRequest = request
        mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = [
            "model": model,
            "contents": prompt,
            "stream": true
        ] as [String : Any]
        
        do {
            mutableRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            handleStreamingResponse(request: mutableRequest, onChunk: onChunk, onComplete: onComplete)
        } catch {
            onComplete(error)
        }
    }
    
    // MARK: - Response Handlers
    private func handleResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping (Result<GeminiResponse, Error>) -> Void
    ) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            completion(.failure(APIError.noData))
            return
        }
        
        do {
            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            completion(.success(geminiResponse))
        } catch {
            completion(.failure(error))
        }
    }
    
    private func handleStreamingResponse(
        request: URLRequest,
        onChunk: @escaping (StreamChunk) -> Void,
        onComplete: @escaping (Error?) -> Void
    ) {
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    onComplete(error)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    onComplete(APIError.noData)
                }
                return
            }
            
            let dataString = String(data: data, encoding: .utf8) ?? ""
            let lines = dataString.components(separatedBy: "\n")
            
            for line in lines {
                if line.hasPrefix("data: ") {
                    let jsonString = String(line.dropFirst(6))
                    if let jsonData = jsonString.data(using: .utf8) {
                        do {
                            let chunk = try JSONDecoder().decode(StreamChunk.self, from: jsonData)
                            DispatchQueue.main.async {
                                onChunk(chunk)
                            }
                            
                            if chunk.done == true {
                                DispatchQueue.main.async {
                                    onComplete(nil)
                                }
                                return
                            }
                        } catch {
                            // Continue processing other chunks
                        }
                    }
                }
            }
        }
        
        task.resume()
    }
}

// MARK: - Custom Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Base64 Image Processing
extension GeminiAPIService {
    func processBase64Images(_ base64Images: [String]) -> [UIImage] {
        return base64Images.compactMap { base64String in
            // Remove data URL prefix if present
            let cleanBase64 = base64String.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                .replacingOccurrences(of: "data:image/png;base64,", with: "")
            
            if let data = Data(base64Encoded: cleanBase64) {
                return UIImage(data: data)
            }
            return nil
        }
    }
    
    func convertImagesToBase64(_ images: [UIImage]) -> [String] {
        return images.compactMap { image in
            if let data = image.jpegData(compressionQuality: 0.8) {
                return "data:image/jpeg;base64,\(data.base64EncodedString())"
            }
            return nil
        }
    }
}