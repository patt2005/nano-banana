import SwiftUI
import Photos

class GalleryViewModel: NSObject, ObservableObject {
    @Published var selectedItem: GalleryHistoryItem?
    @Published var showingImageViewer = false
    @Published var showingSaveAlert = false
    @Published var saveAlertMessage = ""
    @Published var showingShareSheet = false
    @Published var shareItems: [Any] = []
    @Published var isSavingToPhotos = false

    func selectItem(_ item: GalleryHistoryItem) {
        selectedItem = item
        showingImageViewer = true
    }

    func dismissViewer() {
        showingImageViewer = false
        // Clear selected item after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.selectedItem = nil
        }
    }

    func shareImage(_ image: UIImage, prompt: String) {
        shareItems = [image, prompt]
        showingShareSheet = true
    }

    func saveImageToPhotos(_ image: UIImage) {
        guard !isSavingToPhotos else { return }

        isSavingToPhotos = true

        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized, .limited:
                        self?.performImageSave(image)
                    case .denied, .restricted:
                        self?.isSavingToPhotos = false
                        self?.saveAlertMessage = "Photo library access denied. Please enable access in Settings."
                        self?.showingSaveAlert = true
                    case .notDetermined:
                        self?.isSavingToPhotos = false
                    @unknown default:
                        self?.isSavingToPhotos = false
                    }
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        self?.performImageSave(image)
                    case .denied, .restricted:
                        self?.isSavingToPhotos = false
                        self?.saveAlertMessage = "Photo library access denied. Please enable access in Settings."
                        self?.showingSaveAlert = true
                    case .notDetermined:
                        self?.isSavingToPhotos = false
                    case .limited:
                        self?.performImageSave(image)
                    @unknown default:
                        self?.isSavingToPhotos = false
                    }
                }
            }
        }
    }

    private func performImageSave(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async {
            self.isSavingToPhotos = false
            if let error = error {
                self.saveAlertMessage = "Failed to save image: \(error.localizedDescription)"
            } else {
                self.saveAlertMessage = "Image successfully saved to Photos"
            }
            self.showingSaveAlert = true
        }
    }
}