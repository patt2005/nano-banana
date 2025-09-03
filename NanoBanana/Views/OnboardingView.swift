import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var appManager = AppManager.shared
    @State private var currentStep = 0
    @State private var selectedOptions: Set<Int> = []
    @State private var isLoading = false
    @State private var loadingProgress: Double = 0.0
    
    let totalSteps = 5
    
    var hasSelection: Bool {
        switch currentStep {
        case 0: return selectedOptions.contains(where: { $0 < 10 })
        case 1: return selectedOptions.contains(where: { $0 >= 10 && $0 < 20 })
        case 2: return selectedOptions.contains(where: { $0 >= 20 && $0 < 30 })
        case 3: return selectedOptions.contains(where: { $0 >= 30 && $0 < 40 })
        case 4: return selectedOptions.contains(where: { $0 >= 40 && $0 < 50 })
        default: return false
        }
    }
    
    var body: some View {
        if isLoading {
            LoadingView(progress: $loadingProgress, onComplete: {
                appManager.completeOnboarding()
            })
        } else {
            ZStack {
                Color.black
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 4)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * (Double(currentStep + 1) / Double(totalSteps)), height: 4)
                            }
                        }
                        .frame(height: 4)
                        
                        HStack {
                            Spacer()
                            Text("\(currentStep + 1) of \(totalSteps)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.trailing, 20)
                        }
                    }
                    .padding(.top, 60)
                    
                    // Content
                    VStack {
                        switch currentStep {
                        case 0:
                            Step1View(selectedOptions: $selectedOptions)
                        case 1:
                            Step2View(selectedOptions: $selectedOptions)
                        case 2:
                            Step3View(selectedOptions: $selectedOptions)
                        case 3:
                            Step4View(selectedOptions: $selectedOptions)
                        case 4:
                            Step5View(selectedOptions: $selectedOptions)
                        default:
                            EmptyView()
                        }
                    }
                    
                    Spacer()
                    
                    HStack {
                        if currentStep > 0 {
                            Button {
                                currentStep -= 1
                            } label: {
                                Text("Back")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            if currentStep < totalSteps - 1 {
                                currentStep += 1
                            } else {
                                startLoading()
                            }
                        } label: {
                            Text(currentStep == totalSteps - 1 ? "Finish" : "Next")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(hasSelection ? Color.blue : Color.gray)
                                .cornerRadius(20)
                        }
                        .disabled(!hasSelection)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func startLoading() {
        isLoading = true
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            loadingProgress += 0.02
            if loadingProgress >= 1.0 {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    appManager.completeOnboarding()
                }
            }
        }
    }
}

// MARK: - Step Views
struct Step1View: View {
    @Binding var selectedOptions: Set<Int>
    
    let options = [
        "Quickly removing unwanted things or people ✂️",
        "Changing object colors effortlessly 🎨",
        "Making my sketches come alive ✏️",
        "Trying outfits virtually 👗",
        "Exploring creative edits via chat 💬",
        "Other (Tell us more!) 💡"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Text("What inspired you to try our AI-powered photo editor?")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 40)
            
            VStack(spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    OptionButton(
                        text: option,
                        isSelected: selectedOptions.contains(index),
                        hasCheckmark: selectedOptions.contains(index),
                        action: {
                            selectedOptions.removeAll()
                            selectedOptions.insert(index)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

struct Step2View: View {
    @Binding var selectedOptions: Set<Int>
    
    let options = [
        "Almost every day - It's my thing! 📸",
        "Once or twice a week 📅",
        "Monthly - Occasionally, for special moments 🔴",
        "Rarely - Just when necessary 😅",
        "This is new territory for me! 🌍"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("How often do you typically edit or enhance your photos?")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 20)
                .padding(.top, 40)
            
            VStack(spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    OptionButton(
                        text: option,
                        isSelected: selectedOptions.contains(index + 10),
                        hasCheckmark: selectedOptions.contains(index + 10)
                    , action: {
                        let filteredOptions = selectedOptions.filter { !($0 >= 10 && $0 < 20) }
                        selectedOptions = Set(filteredOptions)
                        selectedOptions.insert(index + 10)
                    })
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

struct Step3View: View {
    @Binding var selectedOptions: Set<Int>
    
    let options = [
        "Everyday personal or family moments 👥",
        "Professional-grade photography 📷",
        "Social media content ⭐",
        "E-commerce and product showcase 🛍️",
        "Creative experiments ✏️"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What type of photos are you most excited to enhance with AI?")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 20)
                .padding(.top, 40)
            
            VStack(spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    OptionButton(
                        text: option,
                        isSelected: selectedOptions.contains(index + 20),
                        hasCheckmark: selectedOptions.contains(index + 20)
                    , action: {
                        let filteredOptions = selectedOptions.filter { !($0 >= 20 && $0 < 30) }
                        selectedOptions = Set(filteredOptions)
                        selectedOptions.insert(index + 20)
                    })
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

struct Step4View: View {
    @Binding var selectedOptions: Set<Int>
    
    let options = [
        "Basic editing (crop, filters, brightness) 🔧",
        "Advanced AI transformations 🤖",
        "Object removal and replacement ✂️",
        "Style transfer and artistic effects 🎨",
        "Background changes and effects 🌄",
        "All of the above! 🚀"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Which editing features are you most excited about?")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 20)
                .padding(.top, 40)
            
            VStack(spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    OptionButton(
                        text: option,
                        isSelected: selectedOptions.contains(index + 30),
                        hasCheckmark: selectedOptions.contains(index + 30),
                        action: {
                            if selectedOptions.contains(index + 30) {
                                selectedOptions.remove(index + 30)
                            } else {
                                selectedOptions.insert(index + 30)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

struct Step5View: View {
    @Binding var selectedOptions: Set<Int>
    
    let options = [
        "Start with free features 🎉",
        "Upgrade to premium immediately 👑", 
        "Learn more about pricing 💰",
        "Just explore for now 🔍"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Text("Ready to transform your photos?")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Choose how you'd like to get started with NanoBanana")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
            
            VStack(spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    OptionButton(
                        text: option,
                        isSelected: selectedOptions.contains(index + 40),
                        hasCheckmark: selectedOptions.contains(index + 40),
                        action: {
                            let filteredOptions = selectedOptions.filter { !($0 >= 40 && $0 < 50) }
                            selectedOptions = Set(filteredOptions)
                            selectedOptions.insert(index + 40)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

struct LoadingView: View {
    @Binding var progress: Double
    let onComplete: () -> Void
    
    let loadingSteps = [
        "Prepping your workspace",
        "Powering up smart features",
        "Almost there..."
    ]
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(.all)
            
            VStack(spacing: 40) {
                Text("Getting things ready for you...")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                VStack(spacing: 20) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .accentColor(.blue)
                        .frame(width: 250)
                    
                    VStack(spacing: 12) {
                        ForEach(Array(loadingSteps.enumerated()), id: \.offset) { index, step in
                            HStack {
                                Image(systemName: progress > Double(index + 1) * 0.33 ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(progress > Double(index + 1) * 0.33 ? .blue : .gray)
                                
                                Text(step)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
        }
    }
}

struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let hasCheckmark: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if hasCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }
}
