import SwiftUI
import Photos
import PhotosUI

// Wrapper view that handles permissions
struct PhotoPickerView: View {
    @Binding var selectedImages: [UIImage]
    @Binding var isPresented: Bool
    @State private var authorizationStatus = PHPhotoLibrary.authorizationStatus()
    @State private var showingSettings = false
    
    var body: some View {
        Group {
            switch authorizationStatus {
            case .authorized, .limited:
                ImagePicker(selectedImages: $selectedImages)
            
            case .notDetermined:
                PermissionRequestView {
                    PHPhotoLibrary.requestAuthorization { status in
                        DispatchQueue.main.async {
                            authorizationStatus = status
                            if status == .authorized || status == .limited {
                                // Permissions granted, the view will automatically update
                            } else {
                                // Permissions denied, dismiss
                                isPresented = false
                            }
                        }
                    }
                }
            
            case .denied, .restricted:
                PermissionDeniedView(showingSettings: $showingSettings)
                
            @unknown default:
                PermissionDeniedView(showingSettings: $showingSettings)
            }
        }
        .onAppear {
            // Refresh authorization status when view appears
            authorizationStatus = PHPhotoLibrary.authorizationStatus()
        }
        .alert("Open Settings", isPresented: $showingSettings) {
            Button("Cancel") { }
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
                isPresented = false
            }
        } message: {
            Text("Please enable photo library access in Settings to select images.")
        }
    }
}

struct PermissionRequestView: View {
    let requestAction: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Access Your Photos")
                    .font(.system(size: 24, weight: .bold))
                
                Text("NanoBanana needs access to your photo library to transform and edit your images.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            
            Button(action: requestAction) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.blue)
                    .cornerRadius(12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PermissionDeniedView: View {
    @Binding var showingSettings: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                Text("Photo Access Required")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Please enable photo library access in Settings to select images for transformation.")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    showingSettings = true
                }) {
                    Text("Open Settings")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.blue)
                        .cornerRadius(12)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}