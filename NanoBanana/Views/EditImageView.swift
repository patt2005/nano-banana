import SwiftUI
import PhotosUI
import Photos

struct EditImageView: View {
    let imageData: ImageData
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedImage: UIImage?
    @State private var uploadedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var editedPrompt: String = ""
    @State private var showingImagePicker = false
    @FocusState private var isPromptFocused: Bool
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var isSavingToPhotos = false
    @State private var showingShopPage = false
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header with close button
                HStack {
                    Text(imageData.title ?? "Edit Image")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        viewModel.dismissEditSheet()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // Display generated, uploaded or original image
                if let generatedImage = viewModel.generatedImage {
                    VStack(spacing: 12) {
                        Image(uiImage: generatedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 350)
                            .cornerRadius(20)
                            .shadow(color: .white.opacity(0.1), radius: 10)
                            .overlay(
                                // Success indicator for generated image
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                    )
                                    .offset(x: UIScreen.main.bounds.width / 2 - 80, y: -140)
                            )

                        // Save and Share buttons for generated image
                        HStack(spacing: 12) {
                            Button(action: {
                                saveImageToPhotos(generatedImage)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 16))
                                    Text("Save")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue.opacity(0.8))
                                )
                            }
                            .disabled(isSavingToPhotos)

                            Button(action: {
                                shareImage(generatedImage)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16))
                                    Text("Share")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.green.opacity(0.8))
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                } else if let uploadedImage = uploadedImage {
                    Image(uiImage: uploadedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 350)
                        .cornerRadius(20)
                        .shadow(color: .white.opacity(0.1), radius: 10)
                        .padding(.horizontal)
                } else {
                    AsyncImage(url: URL(string: imageData.imagePath)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.5)
                            )
                    }
                    .frame(maxHeight: 350)
                    .cornerRadius(20)
                    .shadow(color: .white.opacity(0.1), radius: 10)
                    .padding(.horizontal)
                }

                // Upload Image Button
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 18))
                        Text(uploadedImage == nil ? "Upload Image" : "Change Image")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                await MainActor.run {
                                    uploadedImage = uiImage
                                    // Clear any previously generated image
                                    viewModel.generatedImage = nil
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Editable Prompt
                VStack(alignment: .leading, spacing: 10) {
                    Text("Prompt")
                        .font(.headline)
                        .foregroundColor(.gray)

                    ZStack(alignment: .topLeading) {
                        // Background for TextEditor
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))

                        // TextEditor for multi-line editing
                        TextEditor(text: $editedPrompt)
                            .font(.body)
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden) // Hide default background
                            .background(Color.clear)
                            .padding(8)
                            .focused($isPromptFocused)
                    }
                    .frame(minHeight: 100, maxHeight: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isPromptFocused ? Color.purple.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                .onTapGesture {
                    // Dismiss keyboard when tapping outside
                }
                .simultaneousGesture(
                    TapGesture().onEnded { _ in
                        // Allow taps to pass through to TextEditor
                    }
                )

                Spacer()

                // Error message display from viewModel
                if let errorMessage = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red)

                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                }

                // Generate button
                Button(action: {
                    generateImage()
                }) {
                    HStack(spacing: 12) {
                        if viewModel.isProcessing {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 20))
                        }

                        Text(viewModel.isProcessing ? "Generating..." : "Generate")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: viewModel.isProcessing
                                ? [Color.gray, Color.gray.opacity(0.8)]
                                : [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: viewModel.isProcessing ? .clear : .purple.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal)
                .disabled(viewModel.isProcessing)
                .animation(.easeInOut, value: viewModel.isProcessing)

                // Bottom padding
                Spacer()
                    .frame(height: 20)
            }
        }
        .onAppear {
            // Initialize the edited prompt with the original prompt
            editedPrompt = imageData.prompt
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside the text editor
            isPromptFocused = false
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .alert("Save Image", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveAlertMessage)
        }
        .sheet(isPresented: $showingShopPage) {
            ShopPage()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func shareImage(_ image: UIImage) {
        shareItems = [image, viewModel.currentPrompt]
        showingShareSheet = true
    }

    private func saveImageToPhotos(_ image: UIImage) {
        guard !isSavingToPhotos else { return }

        isSavingToPhotos = true

        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized, .limited:
                        self.performImageSave(image)
                    case .denied, .restricted:
                        self.isSavingToPhotos = false
                        self.saveAlertMessage = "Photo library access denied. Please enable access in Settings."
                        self.showingSaveAlert = true
                    case .notDetermined:
                        self.isSavingToPhotos = false
                    @unknown default:
                        self.isSavingToPhotos = false
                    }
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        self.performImageSave(image)
                    case .denied, .restricted:
                        self.isSavingToPhotos = false
                        self.saveAlertMessage = "Photo library access denied. Please enable access in Settings."
                        self.showingSaveAlert = true
                    case .notDetermined:
                        self.isSavingToPhotos = false
                    case .limited:
                        self.performImageSave(image)
                    @unknown default:
                        self.isSavingToPhotos = false
                    }
                }
            }
        }
    }

    private func performImageSave(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        isSavingToPhotos = false
        saveAlertMessage = "Image successfully saved to Photos"
        showingSaveAlert = true
    }

    private func generateImage() {
        guard !editedPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            viewModel.errorMessage = "Please enter a prompt"
            return
        }

        // Dismiss keyboard
        isPromptFocused = false

        // Call viewModel to generate image with the edited prompt and optional uploaded image
        let result = viewModel.generateImage(with: editedPrompt, uploadedImage: uploadedImage)

        switch result {
        case .needsPaywall:
            AppManager.shared.presentPaywall()
        case .needsShop:
            showingShopPage = true
        case .success:
            // Generation started successfully
            break
        }
    }
}

struct EditImageView_Previews: PreviewProvider {
    static var previews: some View {
        EditImageView(
            imageData: ImageData(
                id: "preview",
                imagePath: "https://example.com/image.jpg",
                prompt: "Sample prompt for image editing",
                title: "Sample Title"
            ),
            viewModel: HomeViewModel()
        )
    }
}