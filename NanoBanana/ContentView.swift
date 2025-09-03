import SwiftUI
import Foundation
import UserNotifications
import AVFoundation
import Photos

struct ContentView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var showingChat = false
    @State private var showingSettings = false
    @State private var showingImagePicker = false
    @State private var showingNotificationPermission = false
    @State private var showingCameraPermission = false
    @State private var showingPhotoPermission = false
    @State private var showingHistory = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom App Bar
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
            
            // Main Content
            VStack {
                Spacer()
                
                VStack(spacing: 7) {
                    Text("Upload your photo")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(Color.gray)
                    
                    Text("Share best memos to edit them!")
                        .font(.body)
                        .foregroundColor(Color.gray.opacity(0.6))
                    
                    // Upload Area with Cat Image
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 250, height: 140)
                            .overlay(
                                Image("Cat")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                            )
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            
            // Bottom Container - Input Area
            VStack(spacing: 16) {
                // Text Input Area
                TextField("Type your prompt here...", text: $chatViewModel.currentInput, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .accentColor(.white.opacity(0.8))
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: 50, maxHeight: 80)
                    .lineLimit(1...3)
                    
                    // Bottom Row with buttons - in one container
                    HStack(spacing: 16) {
                        // Left container with paperclip and PRO Creation
                        HStack(spacing: 12) {
                            // Paperclip Button
                            Button(action: {}) {
                                Image(systemName: "paperclip")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.25))
                            .cornerRadius(20)
                            
                            // PRO Creation Button
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "eye")
                                        .foregroundColor(.white)
                                    Text("PRO Creation")
                                        .foregroundColor(.white)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.25))
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        // Send Button
                        if !chatViewModel.currentInput.isEmpty {
                            Button(action: {
                                if chatViewModel.canSend {
                                    chatViewModel.sendMessage()
                                    showingChat = true
                                }
                            }) {
                                Image(systemName: chatViewModel.isLoading ? "stop.circle" : "arrow.up")
                                    .foregroundColor(.black)
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(.white))
                            }
                            .disabled(!chatViewModel.canSend)
                        }
                    }
                }
                .padding(20)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(.black)
            .sheet(isPresented: $showingChat) {
                ChatView(viewModel: chatViewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("\"NanoBanana\" ar dori să vă trimită notificări", isPresented: $showingNotificationPermission) {
                Button("Nu permiteți") {
                    showingNotificationPermission = false
                }
                Button("Permiteți") {
                    requestNotificationPermission()
                }
            } message: {
                Text("Notificările pot include alerte, sunete și insigne pentru pictograme. Acestea pot fi configurate în Configurări.")
            }
            .alert("\"NanoBanana\" ar dori să acceseze camera", isPresented: $showingCameraPermission) {
                Button("Nu permiteți") {
                    showingCameraPermission = false
                }
                Button("Permiteți") {
                    requestCameraPermission()
                }
            } message: {
                Text("We need to access your camera to capture and transform images for you to get accurate results")
            }
            .alert("\"NanoBanana\" ar dori să acceseze galeria foto", isPresented: $showingPhotoPermission) {
                Button("Nu permiteți") {
                    showingPhotoPermission = false
                }
                Button("Permiteți") {
                    requestPhotoPermission()
                }
            } message: {
                Text("We need to access your photo library to select and transform images for you to get accurate results")
            }
            .onAppear {
                checkNotificationPermission()
                checkCameraPermission()
                checkPhotoPermission()
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotoPickerView(selectedImages: $chatViewModel.selectedImages, isPresented: $showingImagePicker)
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView(chatViewModel: chatViewModel)
            }
        }
        
        func checkNotificationPermission() {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    if settings.authorizationStatus == .notDetermined {
                        showingNotificationPermission = true
                    }
                }
            }
        }
        
        func requestNotificationPermission() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                DispatchQueue.main.async {
                    showingNotificationPermission = false
                }
            }
        }
        
        func checkCameraPermission() {
            let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
            if cameraStatus == .notDetermined {
                showingCameraPermission = true
            }
        }
        
        func requestCameraPermission() {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    showingCameraPermission = false
                }
            }
        }
        
        func checkPhotoPermission() {
            let photoStatus = PHPhotoLibrary.authorizationStatus()
            if photoStatus == .notDetermined {
                showingPhotoPermission = true
            }
        }
        
        func requestPhotoPermission() {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    showingPhotoPermission = false
                }
            }
        }
    }

