import Foundation
import UIKit

struct GeminiRequest {
    let model: String
    let contents: String
    let stream: Bool
    let images: [UIImage]
}

struct GeminiResponse: Codable {
    let text: String?
    let images: [ImageResult]?
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
    let images: [ImageResult]?
}

struct ImageResult: Codable {
    let url: String?
    let base64: String?
    let data: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let stringValue = try? decoder.singleValueContainer().decode(String.self) {
            self.base64 = stringValue
            self.url = nil
            self.data = nil
            return
        }
        
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.base64 = try container.decodeIfPresent(String.self, forKey: .base64)
        self.data = try container.decodeIfPresent(String.self, forKey: .data)
    }
    
    enum CodingKeys: String, CodingKey {
        case url, base64, data
    }
    
    var imageData: String? {
        return base64 ?? data ?? url
    }
}

final class GeminiAPIService: ObservableObject {
    static let shared = GeminiAPIService()
    
    private let baseURL = "https://nano-banana-api-164860087792.us-central1.run.app"
    private let session = URLSession.shared
    
    private init() {}
    
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
            sendMultipartRequest(
                request: request,
                model: model,
                prompt: prompt,
                images: images,
                stream: stream,
                completion: completion
            )
        } else {
            sendJSONRequest(
                request: request,
                model: model,
                prompt: prompt,
                stream: stream,
                completion: completion
            )
        }
    }
    
    func generateContentStream(
        model: String = "gemini-2.5-flash-image-preview",
        prompt: String,
        images: [UIImage] = []
    ) async throws -> AsyncThrowingStream<StreamChunk, Error> {
        guard let url = URL(string: "\(baseURL)/v1/generate") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare request body
        let requestBody: [String: Any]
        if !images.isEmpty {
            // Convert images to base64
            let base64Images = images.compactMap { image -> String? in
                guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
                return data.base64EncodedString()
            }
            
            requestBody = [
                "model": model,
                "contents": prompt,
                "images": base64Images,
                "stream": true
            ]
        } else {
            requestBody = [
                "model": model,
                "contents": prompt,
                "stream": true
            ]
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw APIError.encodingError
        }
        
        request.httpBody = jsonData
        
        let (result, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw APIError.networkError("HTTP \(httpResponse.statusCode)")
        }
        
        return AsyncThrowingStream<StreamChunk, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    for try await line in result.lines {
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if trimmedLine.hasPrefix("data: ") {
                            let jsonString = String(trimmedLine.dropFirst(6))
                            
                            if jsonString == "[DONE]" || jsonString.contains("\"done\":true") {
                                continuation.finish()
                                return
                            }
                            
                            if let data = jsonString.data(using: .utf8) {
                                do {
                                    let chunk = try JSONDecoder().decode(StreamChunk.self, from: data)
                                    continuation.yield(chunk)
                                    
                                    if chunk.done == true {
                                        continuation.finish()
                                        return
                                    }
                                } catch {
                                    print("Failed to decode chunk: \(error)")
                                    print("Raw JSON: \(jsonString)")
                                }
                            }
                        } else if !trimmedLine.isEmpty && trimmedLine != "data: [DONE]" {
                            if let data = trimmedLine.data(using: .utf8) {
                                do {
                                    let chunk = try JSONDecoder().decode(StreamChunk.self, from: data)
                                    continuation.yield(chunk)
                                    
                                    if chunk.done == true {
                                        continuation.finish()
                                        return
                                    }
                                } catch {
                                    print("Failed to decode direct JSON chunk: \(error)")
                                    print("Raw line: \(trimmedLine)")
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
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
        let delegate = StreamingDelegate(onChunk: onChunk, onComplete: onComplete)
        let config = URLSessionConfiguration.default
        let customSession = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        
        let task = customSession.dataTask(with: request)
        task.resume()
    }
}

// MARK: - Streaming Delegate
final class StreamingDelegate: NSObject, URLSessionDataDelegate {
    private let onChunk: (StreamChunk) -> Void
    private let onComplete: (Error?) -> Void
    private var buffer = Data()
    
    init(onChunk: @escaping (StreamChunk) -> Void, onComplete: @escaping (Error?) -> Void) {
        self.onChunk = onChunk
        self.onComplete = onComplete
        super.init()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        processBuffer()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            self.onComplete(error)
        }
    }
    
    private func processBuffer() {
        let dataString = String(data: buffer, encoding: .utf8) ?? ""
        let lines = dataString.components(separatedBy: "\n")
        
        // Process complete lines, keep incomplete line in buffer
        for (index, line) in lines.enumerated() {
            if index == lines.count - 1 && !dataString.hasSuffix("\n") {
                // Keep incomplete line in buffer
                if let incompleteData = line.data(using: .utf8) {
                    buffer = incompleteData
                }
                break
            } else {
                // Process complete line
                processLine(line)
                // Remove processed line from buffer
                if let lineData = (line + "\n").data(using: .utf8) {
                    if buffer.count >= lineData.count {
                        buffer.removeFirst(lineData.count)
                    }
                }
            }
        }
    }
    
    private func processLine(_ line: String) {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedLine.hasPrefix("data: ") {
            let jsonString = String(trimmedLine.dropFirst(6))
            if jsonString == "[DONE]" {
                DispatchQueue.main.async {
                    self.onComplete(nil)
                }
                return
            }
            
            if let jsonData = jsonString.data(using: .utf8) {
                do {
                    let chunk = try JSONDecoder().decode(StreamChunk.self, from: jsonData)
                    DispatchQueue.main.async {
                        self.onChunk(chunk)
                    }
                    
                    if chunk.done == true {
                        DispatchQueue.main.async {
                            self.onComplete(nil)
                        }
                    }
                } catch {
                    print("Failed to decode chunk: \(error)")
                }
            }
        }
    }
}

// MARK: - Custom Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case encodingError
    case invalidResponse
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .encodingError:
            return "Failed to encode request"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Base64 Image Processing
extension GeminiAPIService {
    func processBase64Images(_ imageResults: [ImageResult]) -> [UIImage] {
        return imageResults.compactMap { imageResult in
            guard let imageDataString = imageResult.imageData else { return nil }
            
            // Remove data URL prefix if present
            let cleanBase64 = imageDataString.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
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
