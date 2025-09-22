import Foundation
import Combine
import UIKit

class APIService {
    static let shared = APIService()

    private let baseURL = "https://nano-banana-api-164860087792.us-central1.run.app"
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    private func safeSession() -> URLSession {
        let config: URLSessionConfiguration
        if #available(iOS 18.4, *) {
            config = URLSessionConfiguration.ephemeral
        } else {
            config = URLSessionConfiguration.default
        }

        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.httpShouldSetCookies = false
        config.httpShouldUsePipelining = false
        config.httpMaximumConnectionsPerHost = 1

        return URLSession(configuration: config)
    }

    func registerUser(userId: String, completion: @escaping (Result<UserResponse, NanoBananaAPIError>) -> Void) {
        guard var urlComponents = URLComponents(string: "\(baseURL)/v1/register") else {
            completion(.failure(.invalidURL))
            return
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "user_id", value: userId)
        ]

        guard let url = urlComponents.url else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        safeSession().dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.networkError(error.localizedDescription)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }

                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }

                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📱 [APIService] Register response: \(jsonString)")
                }

                switch httpResponse.statusCode {
                case 201, 409:
                    do {
                        let response = try JSONDecoder().decode(UserResponse.self, from: data)
                        completion(.success(response))
                    } catch {
                        completion(.failure(.decodingError(error.localizedDescription)))
                    }
                case 400:
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        completion(.failure(.serverError(errorResponse.error)))
                    } else {
                        completion(.failure(.serverError("Bad request")))
                    }
                case 500:
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        completion(.failure(.serverError(errorResponse.error)))
                    } else {
                        completion(.failure(.serverError("Internal server error")))
                    }
                default:
                    completion(.failure(.unexpectedStatusCode(httpResponse.statusCode)))
                }
            }
        }.resume()
    }

    // MARK: - User Credits

    func getUserCredits(userId: String, completion: @escaping (Result<UserResponse, NanoBananaAPIError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/v1/user/\(userId)") else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        safeSession().dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.networkError(error.localizedDescription)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    completion(.failure(.invalidResponse))
                    return
                }

                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }

                do {
                    let response = try JSONDecoder().decode(UserResponse.self, from: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(.decodingError(error.localizedDescription)))
                }
            }
        }.resume()
    }

    func updateUserCredits(userId: String, credits: Int, completion: @escaping (Result<UserResponse, NanoBananaAPIError>) -> Void) {
        guard var urlComponents = URLComponents(string: "\(baseURL)/v1/add_credits") else {
            completion(.failure(.invalidURL))
            return
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "credits", value: String(credits))
        ]

        guard let url = urlComponents.url else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        safeSession().dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.networkError(error.localizedDescription)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }

                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }

                // Log the response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("💳 [APIService] Add credits response: \(jsonString)")
                }

                switch httpResponse.statusCode {
                case 200:
                    // Credits added successfully
                    do {
                        let response = try JSONDecoder().decode(UserResponse.self, from: data)
                        completion(.success(response))
                    } catch {
                        completion(.failure(.decodingError(error.localizedDescription)))
                    }

                case 400:
                    // Bad request
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        completion(.failure(.serverError(errorResponse.error)))
                    } else {
                        completion(.failure(.serverError("Bad request")))
                    }

                case 404:
                    // User not found
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        completion(.failure(.serverError(errorResponse.error)))
                    } else {
                        completion(.failure(.serverError("User not found")))
                    }

                case 500:
                    // Server error
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        completion(.failure(.serverError(errorResponse.error)))
                    } else {
                        completion(.failure(.serverError("Internal server error")))
                    }

                default:
                    completion(.failure(.unexpectedStatusCode(httpResponse.statusCode)))
                }
            }
        }.resume()
    }

    // MARK: - Load Data from Google Cloud Storage

    func loadData(completion: @escaping (Result<DataModel, NanoBananaAPIError>) -> Void) {
        let dataURL = "https://storage.googleapis.com/nano_ai/data.json"

        guard let url = URL(string: dataURL) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData

        safeSession().dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [APIService] Network error loading data: \(error.localizedDescription)")
                    completion(.failure(.networkError(error.localizedDescription)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ [APIService] Invalid response")
                    completion(.failure(.invalidResponse))
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    print("❌ [APIService] Unexpected status code: \(httpResponse.statusCode)")
                    completion(.failure(.unexpectedStatusCode(httpResponse.statusCode)))
                    return
                }

                guard let data = data else {
                    print("❌ [APIService] No data received")
                    completion(.failure(.noData))
                    return
                }

                print("📦 [APIService] Successfully fetched data (\(data.count) bytes)")

                do {
                    let dataModel = try JSONDecoder().decode(DataModel.self, from: data)
                    print("✅ [APIService] Successfully decoded DataModel")

                    if let lifestyle = dataModel.categories["lifestyle"] {
                        print("✅ [APIService] Lifestyle category: \(lifestyle.images.count) images")
                    }
                    if let explore = dataModel.categories["explore"] {
                        print("✅ [APIService] Explore category: \(explore.images.count) images")
                    }
                    if let functionality = dataModel.categories["functionality"] {
                        print("✅ [APIService] Functionality category: \(functionality.images.count) images")
                    }

                    completion(.success(dataModel))
                } catch {
                    print("❌ [APIService] Decoding error: \(error)")
                    completion(.failure(.decodingError(error.localizedDescription)))
                }
            }
        }.resume()
    }
}

struct UserResponse: Codable {
    let message: String?
    let user: User?
    let error: String?
}

struct User: Codable {
    let id: String
    let credits: Int
    let createdAt: String?
    let updatedAt: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case credits
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ImageData: Codable {
    let id: String
    let imagePath: String
    let prompt: String
    let title: String?
}

struct Category: Codable {
    let name: String
    let description: String
    let maxItems: Int
    let images: [ImageData]
}

struct DataModel: Codable {
    let version: String
    let categories: [String: Category]
}

enum NanoBananaAPIError: LocalizedError {
    case invalidURL
    case networkError(String)
    case invalidResponse
    case noData
    case decodingError(String)
    case serverError(String)
    case unexpectedStatusCode(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unexpectedStatusCode(let code):
            return "Unexpected status code: \(code)"
        }
    }
}
