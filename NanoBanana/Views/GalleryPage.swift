import SwiftUI
import Photos

struct GalleryPage: View {
    @ObservedObject private var imagePromptManager = ImagePromptManager.shared
    @StateObject private var viewModel = GalleryViewModel()

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Gallery")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                if imagePromptManager.galleryHistory.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()

                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            Text("No Photos Yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            Text("Your generated images will appear here")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(imagePromptManager.galleryHistory) { item in
                                Button(action: {
                                    viewModel.selectItem(item)
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        // Image container
                                        ZStack(alignment: .topTrailing) {
                                            if let image = imagePromptManager.loadImage(from: item.imagePath) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(minWidth: 0, maxWidth: .infinity)
                                                    .frame(height: 200)
                                                    .clipped()

                                                // AI Generated badge
                                                if item.isAIGenerated {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "sparkles")
                                                            .font(.system(size: 10))
                                                        Text("AI")
                                                            .font(.system(size: 10, weight: .bold))
                                                    }
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 3)
                                                    .background(
                                                        Capsule()
                                                            .fill(Color.black.opacity(0.7))
                                                    )
                                                    .padding(8)
                                                }
                                            } else {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(minWidth: 0, maxWidth: .infinity)
                                                    .frame(height: 200)
                                                    .overlay(
                                                        Image(systemName: "photo")
                                                            .font(.largeTitle)
                                                            .foregroundColor(.gray)
                                                    )
                                            }
                                        }

                                        // Prompt and date with gradient background
                                        VStack(alignment: .leading, spacing: 4) {
                                            if !item.prompt.isEmpty {
                                                Text(item.prompt)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                            }

                                            Text(item.relativeDate)
                                                .font(.system(size: 11))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "2a2a2a"),
                                                    Color(hex: "1c1c1e").opacity(0.9)
                                                ],
                                                startPoint: .bottom,
                                                endPoint: .top
                                            )
                                        )
                                    }
                                    .background(Color(hex: "1a1a1a"))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(action: {
                                        if let image = imagePromptManager.loadImage(from: item.imagePath) {
                                            viewModel.shareImage(image, prompt: item.prompt)
                                        }
                                    }) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }

                                    Button(action: {
                                        if let image = imagePromptManager.loadImage(from: item.imagePath) {
                                            viewModel.saveImageToPhotos(image)
                                        }
                                    }) {
                                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                                    }

                                    Button(role: .destructive, action: {
                                        imagePromptManager.removeGalleryHistoryItem(withId: item.id)
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingImageViewer) {
            if let item = viewModel.selectedItem {
                ImageViewerView(item: item, viewModel: viewModel, imagePromptManager: imagePromptManager)
            }
        }
        .alert("Save Image", isPresented: $viewModel.showingSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.saveAlertMessage)
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            ShareSheet(items: viewModel.shareItems)
        }
    }
}

// Full-screen image viewer
struct ImageViewerView: View {
    let item: GalleryHistoryItem
    @ObservedObject var viewModel: GalleryViewModel
    @ObservedObject var imagePromptManager: ImagePromptManager

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Image
                    if let image = imagePromptManager.loadImage(from: item.imagePath) {
                        GeometryReader { geometry in
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                        .padding(.vertical)
                    } else {
                        Spacer()

                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Spacer()
                    }

                    // Bottom info
                    VStack(alignment: .leading, spacing: 12) {
                        if !item.prompt.isEmpty {
                            Text(item.prompt)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                        }

                        HStack {
                            if item.isAIGenerated {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12))
                                    Text("AI Generated")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.yellow)
                            }

                            Spacer()

                            Text(item.relativeDate)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.9),
                                Color.clear
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        viewModel.dismissViewer()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 20) {
                        Button(action: {
                            if let image = imagePromptManager.loadImage(from: item.imagePath) {
                                viewModel.shareImage(image, prompt: item.prompt)
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                        }

                        Button(action: {
                            if let image = imagePromptManager.loadImage(from: item.imagePath) {
                                viewModel.saveImageToPhotos(image)
                            }
                        }) {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            ShareSheet(items: viewModel.shareItems)
        }
    }
}