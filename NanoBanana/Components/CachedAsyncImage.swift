import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (UIImage) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadFailed = false
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (UIImage) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(image)
            } else if loadFailed {
                placeholder()
            } else if isLoading {
                placeholder()
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let url = url, !isLoading else { return }
        
        isLoading = true
        loadFailed = false
        
        Task {
            let loadedImage = await ImageCacheManager.shared.getImage(from: url.absoluteString)
            
            await MainActor.run {
                self.image = loadedImage
                self.isLoading = false
                self.loadFailed = loadedImage == nil
            }
        }
    }
}

// Convenience initializer for common use cases
extension CachedAsyncImage where Content == Image, Placeholder == Color {
    init(url: URL?) {
        self.init(
            url: url,
            content: { uiImage in
                Image(uiImage: uiImage)
            },
            placeholder: {
                Color.gray.opacity(0.2)
            }
        )
    }
}

// Another convenience initializer with custom placeholder view
extension CachedAsyncImage where Content == Image {
    init(url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.init(
            url: url,
            content: { uiImage in
                Image(uiImage: uiImage)
            },
            placeholder: placeholder
        )
    }
}