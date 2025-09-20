import SwiftUI
import PhotosUI

struct GalleryImagePicker: View {
    @Binding var isPresented: Bool
    @ObservedObject private var imagePromptManager = ImagePromptManager.shared
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var imagePrompts: [String] = []
    @State private var showingPromptEditor = false
    @State private var currentImageIndex = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    if selectedImages.isEmpty {
                        // Photo picker selection
                        VStack(spacing: 20) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("Select Photos")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            PhotosPicker(
                                selection: $selectedItems,
                                maxSelectionCount: 10,
                                matching: .images
                            ) {
                                Text("Choose from Library")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                    .cornerRadius(25)
                            }
                        }
                    } else {
                        // Show selected images with prompt editing
                        VStack {
                            Text("Add Prompts to Images")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(.bottom, 20)
                            
                            ScrollView {
                                LazyVStack(spacing: 20) {
                                    ForEach(selectedImages.indices, id: \.self) { index in
                                        ImagePromptEditor(
                                            image: selectedImages[index],
                                            prompt: Binding(
                                                get: { 
                                                    index < imagePrompts.count ? imagePrompts[index] : ""
                                                },
                                                set: { newValue in
                                                    while imagePrompts.count <= index {
                                                        imagePrompts.append("")
                                                    }
                                                    imagePrompts[index] = newValue
                                                }
                                            )
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            HStack(spacing: 16) {
                                Button("Cancel") {
                                    resetSelection()
                                }
                                .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Button("Save All") {
                                    saveAllImages()
                                }
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(25)
                                .disabled(selectedImages.isEmpty)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Add to Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.white),
                
                trailing: selectedImages.isEmpty ? AnyView(EmptyView()) : 
                AnyView(
                    Button("Clear") {
                        resetSelection()
                    }
                    .foregroundColor(.white)
                )
            )
        }
        .onChange(of: selectedItems) { items in
            loadImages(from: items)
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) {
        selectedImages.removeAll()
        imagePrompts.removeAll()
        
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        if let data = data, let image = UIImage(data: data) {
                            selectedImages.append(image)
                            imagePrompts.append("") // Empty prompt initially
                        }
                    case .failure(let error):
                        print("Error loading image: \(error)")
                    }
                }
            }
        }
    }
    
    private func resetSelection() {
        selectedItems.removeAll()
        selectedImages.removeAll()
        imagePrompts.removeAll()
    }
    
    private func saveAllImages() {
        for (index, image) in selectedImages.enumerated() {
            let prompt = index < imagePrompts.count ? imagePrompts[index] : ""
            imagePromptManager.saveImage(image, withPrompt: prompt)
        }
        
        isPresented = false
    }
}

struct ImagePromptEditor: View {
    let image: UIImage
    @Binding var prompt: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Prompt pentru această imagine:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Adaugă un prompt...", text: $prompt, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .background(Color.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}