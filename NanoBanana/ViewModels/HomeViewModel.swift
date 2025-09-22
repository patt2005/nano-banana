import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var selectedImageData: ImageData?
    @Published var showingEditSheet = false
    @Published var dataModel: DataModel?
    @Published var selectedTab: HomeTab = .forYou
    @Published var isProcessing = false
    @Published var generatedImage: UIImage?
    @Published var currentPrompt: String = ""
    @Published var errorMessage: String?
    @Published var generatedImageBase64: String?

    // Store random heights for explore grid
    @Published var exploreImageHeights: [String: CGFloat] = [:]

    init() {
        loadData()
    }

    func selectImage(_ imageData: ImageData) {
        selectedImageData = imageData
        showingEditSheet = true
    }

    func getExploreImageHeight(for imageId: String) -> CGFloat {
        // Generate and store height if not already exists
        if let height = exploreImageHeights[imageId] {
            return height
        } else {
            let randomHeight = CGFloat.random(in: 160...280)
            exploreImageHeights[imageId] = randomHeight
            return randomHeight
        }
    }

    func generateExploreHeights(for images: [ImageData]) {
        // Pre-generate all heights for explore images
        for image in images {
            if exploreImageHeights[image.id] == nil {
                exploreImageHeights[image.id] = CGFloat.random(in: 160...280)
            }
        }
    }

    func dismissEditSheet() {
        showingEditSheet = false
        // Clear selected image data after a short delay to avoid animation issues
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.selectedImageData = nil
            self?.generatedImage = nil
            self?.generatedImageBase64 = nil
            self?.errorMessage = nil
        }
    }

    enum GenerateImageResult {
        case success
        case needsPaywall
        case needsShop
    }

    func generateImage(with prompt: String, uploadedImage: UIImage? = nil) -> GenerateImageResult {
        // Check if user has enough credits
        if SubscriptionManager.shared.credits < 5 {
            if SubscriptionManager.shared.isSubscribed {
                // User is subscribed but needs more credits
                errorMessage = "Insufficient credits. You need 5 credits to generate an image."
                return .needsShop
            } else {
                // User is not subscribed and has insufficient credits
                errorMessage = "Insufficient credits. Subscribe to continue."
                return .needsPaywall
            }
        }

        // Store the current prompt and clear previous state
        currentPrompt = prompt
        errorMessage = nil
        generatedImage = nil
        generatedImageBase64 = nil
        isProcessing = true

        // Call the API to generate image
        GeminiAPIService.shared.createImage(prompt: prompt, image: uploadedImage) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false

                switch result {
                case .success(let response):
                    // Handle base64 image from response
                    if let images = response.result.images,
                       let firstImage = images.first,
                       let base64String = firstImage.data {
                        self?.generatedImageBase64 = base64String

                        // Convert base64 to UIImage
                        if let image = self?.decodeBase64ToImage(base64String) {
                            self?.generatedImage = image

                            // Save to gallery
                            _ = ImagePromptManager.shared.saveImage(image, withPrompt: prompt)

                            // Deduct 5 credits for successful image generation
                            SubscriptionManager.shared.useCredits(5)

                            print("✅ Successfully generated image")
                        } else {
                            self?.errorMessage = "Failed to decode generated image"
                        }
                    } else if let text = response.result.text {
                        self?.errorMessage = "Received text response instead of image: \(text)"
                    } else {
                        self?.errorMessage = "No image data received from API"
                    }

                case .failure(let error):
                    print("❌ Image generation error: \(error)")
                    switch error {
                    case .networkError:
                        self?.errorMessage = "Network error. Please check your connection."
                    case .serverError:
                        self?.errorMessage = "Server error. Please try again."
                    case .invalidResponse:
                        self?.errorMessage = "Invalid response from server."
                    case .decodingError:
                        self?.errorMessage = "Failed to process server response."
                    default:
                        self?.errorMessage = "Failed to generate image. Please try again."
                    }
                }
            }
        }

        return .success
    }

    private func decodeBase64ToImage(_ base64String: String) -> UIImage? {
        // Remove data URL prefix if present
        let cleanBase64 = base64String
            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            .replacingOccurrences(of: "data:image/png;base64,", with: "")
            .replacingOccurrences(of: "data:image/gif;base64,", with: "")
            .replacingOccurrences(of: "data:image/webp;base64,", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = Data(base64Encoded: cleanBase64) else {
            print("❌ Failed to decode base64 string")
            return nil
        }

        return UIImage(data: data)
    }

    private func loadData() {
        // This is now handled by HomePage's loadData which calls APIService
        // The HomePage will update this viewModel's dataModel and call generateExploreHeights
        print("📂 [HomeViewModel] Data loading initiated from HomePage")
    }
}