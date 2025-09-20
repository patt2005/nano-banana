import SwiftUI
import Photos
import PhotosUI

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
                            } else {
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
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 16) {
                        Text("Access Your Photos")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Navo AI needs access to your photo library to transform and edit your images.")
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 40)
                    }
                }
                
                Button(action: requestAction) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.blue)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.orange, lineWidth: 3)
                                )
                        )
                }
                .padding(.horizontal, 32)
            }
        }
    }
}

struct PermissionDeniedView: View {
    @Binding var showingSettings: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 16) {
                        Text("Photo Access Required")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Please enable photo library access in Settings to select images for transformation.")
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 40)
                    }
                }
                
                VStack(spacing: 16) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Text("Open Settings")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.blue)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.orange, lineWidth: 3)
                                    )
                            )
                    }
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 32)
            }
        }
    }
}
