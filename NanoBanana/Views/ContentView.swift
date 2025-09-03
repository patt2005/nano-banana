import SwiftUI
import Foundation
import UserNotifications
import AVFoundation
import Photos
import RevenueCatUI

struct ContentView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @ObservedObject private var appManager = AppManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingSettings = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingHistory = false
    @State private var scrollProxy: ScrollViewProxy?
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        showingHistory = true
                    }) {
                        Image(systemName: "clock")
                            .foregroundColor(Color.gray)
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Text("🍌")
                            .font(.title2)
                        Text("NanoBanana")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(Color.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(Color.gray)
                            .font(.title2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.black)
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            if chatViewModel.messages.isEmpty {
                                VStack {
                                    VStack(spacing: 24) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(width: 120, height: 120)
                                            
                                            Text("🍌")
                                                .font(.system(size: 60))
                                        }
                                        
                                        VStack(spacing: 12) {
                                            Text("Welcome to NanoBanana")
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            Text("Start a conversation by typing a message or uploading photos using the attachment button below.")
                                                .font(.system(size: 16))
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(nil)
                                                .padding(.horizontal, 40)
                                        }
                                        
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, UIScreen.main.bounds.height * 0.16)
                            } else {
                                ForEach(chatViewModel.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                        .padding(.horizontal)
                                }
                            }
                            
                            Color.clear
                                .frame(height: 200)
                        }
                        .padding(.top)
                    }
                    .onChange(of: chatViewModel.messages.count) { _ in
                        scrollToBottom(proxy)
                    }
                    .onAppear {
                        scrollProxy = proxy
                        scrollToBottom(proxy)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 30)
                
                if let errorMessage = chatViewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                        
                        Spacer()
                        
                        Button("Retry") {
                            chatViewModel.retryLastMessage()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    if !chatViewModel.selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 10) {
                                ForEach(chatViewModel.selectedImages.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: chatViewModel.selectedImages[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        Button(action: {
                                            chatViewModel.removeImage(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Color.white)
                                                .clipShape(Circle())
                                                .font(.system(size: 16))
                                        }
                                        .offset(x: 4, y: -4)
                                    }
                                }
                            }
                        }
                        .frame(height: 75)
                        .padding(.top, 5)
                    }
                    
                    TextField("", text: $chatViewModel.currentInput, prompt: Text("Type your prompt here...").foregroundColor(.white.opacity(0.5)), axis: .vertical)
                        .lineLimit(1...5)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.leading)
                        .disabled(chatViewModel.isLoading)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                        .padding(.top, chatViewModel.selectedImages.isEmpty ? 20 : 0)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Menu {
                                Button(action: {
                                    showingCamera = true
                                }) {
                                    Label("Camera", systemImage: "camera")
                                }
                                
                                Button(action: {
                                    requestPhotoLibraryAccess()
                                }) {
                                    Label("Gallery", systemImage: "photo.on.rectangle")
                                }
                            } label: {
                                Image(systemName: "paperclip")
                                    .foregroundColor(.white)
                                    .font(.title2)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.25))
                                    .cornerRadius(20)
                            }
                            
//                            Button(action: {}) {
//                                HStack {
//                                    Image(systemName: "eye")
//                                        .foregroundColor(.white)
//                                    Text("PRO Creation")
//                                        .foregroundColor(.white)
//                                        .fontWeight(.medium)
//                                }
//                            }
//                            .padding(.horizontal, 16)
//                            .padding(.vertical, 10)
//                            .background(Color.gray.opacity(0.25))
//                            .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        if chatViewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                                .frame(width: 40, height: 40)
                        } else {
                            Button(action: {
                                if chatViewModel.canSend {
                                    // Check if free user has exceeded limit before sending
                                    if !subscriptionManager.hasActiveSubscription && chatViewModel.isMessageLimitExceeded {
                                        appManager.showPaywall = true
                                        return
                                    }
                                    
                                    chatViewModel.sendMessage()
                                    if let proxy = scrollProxy {
                                        scrollToBottom(proxy)
                                    }
                                }
                            }) {
                                Image(systemName: "arrow.up")
                                    .foregroundColor(chatViewModel.currentInput.isEmpty ? .white : .black)
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(.white.opacity(chatViewModel.currentInput.isEmpty ? 0.3 : 1.0)))
                            }
                            .disabled(!chatViewModel.canSend)
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 15)
                .background(Color(hex: "373e46"))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(chatViewModel: chatViewModel)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(chatViewModel: chatViewModel)
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotoPickerView(selectedImages: $chatViewModel.selectedImages, isPresented: $showingImagePicker)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPickerView(selectedImages: $chatViewModel.selectedImages, isPresented: $showingCamera)
        }
        .fullScreenCover(isPresented: $appManager.showPaywall) {
            PaywallView()
                .onPurchaseCompleted { customerInfo in
                    subscriptionManager.updateSubscriptionStatus(customerInfo)
                    appManager.showPaywall = false
                }
                .onRestoreCompleted { customerInfo in
                    subscriptionManager.updateSubscriptionStatus(customerInfo)
                    appManager.showPaywall = false
                }
        }
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let id = chatViewModel.messages.last?.id else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
    }
    
    func checkCameraPermission() {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraStatus == .notDetermined {
            //            showingCameraPermission = true
        }
    }
    
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                //                showingCameraPermission = false
            }
        }
    }
    
    func checkPhotoPermission() {
        let photoStatus = PHPhotoLibrary.authorizationStatus()
        if photoStatus == .notDetermined {
            //            showingPhotoPermission = true
        }
    }
    
    func requestPhotoPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                //                showingPhotoPermission = false
            }
        }
    }
    
    func requestPhotoLibraryAccess() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            // Full access already granted
            showingImagePicker = true
            
        case .limited:
            // Limited access - request full access
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        showingImagePicker = true
                    }
                }
            }
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        showingImagePicker = true
                    }
                }
            }
            
        case .denied, .restricted:
            let alert = UIAlertController(
                title: "Photo Access Required",
                message: "Please enable photo library access in Settings to select images.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            })
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true)
            }
            
        @unknown default:
            break
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}
