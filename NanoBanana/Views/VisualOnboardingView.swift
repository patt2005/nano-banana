import SwiftUI

struct VisualOnboardingView: View {
    @State private var currentPage = 0
    @State private var showSurveyOnboarding = false
    
    let totalPages = 3
    
    var body: some View {
        if showSurveyOnboarding {
            OnboardingView()
        } else {
            ZStack {
                Color.black
                    .ignoresSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    // Content based on current page
                    switch currentPage {
                    case 0:
                        OnboardingPage1()
                    case 1:
                        OnboardingPage2()
                    case 2:
                        OnboardingPage3()
                    default:
                        OnboardingPage1()
                    }
                    
                    Spacer()
                    
                    // Page Indicators
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.5))
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Navigation Buttons
                    HStack {
                        Button(action: {
                            showSurveyOnboarding = true
                        }) {
                            Text("Skip")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if currentPage < totalPages - 1 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage += 1
                                }
                            } else {
                                showSurveyOnboarding = true
                            }
                        }) {
                            Text(currentPage == totalPages - 1 ? "Get Started" : "Next")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 50 && currentPage > 0 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage -= 1
                            }
                        } else if value.translation.width < -50 && currentPage < totalPages - 1 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        }
                    }
            )
        }
    }
}

struct OnboardingPage1: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("Express Your Style, Instantly")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Image("1")
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 300)
                .clipShape(Circle())
        }
    }
}

struct OnboardingPage2: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("Reimagine Your Look")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Image("2")
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 300)
                .clipShape(Circle())
        }
    }
}

struct OnboardingPage3: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("Create and Share Your Style")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Image("3")
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 300)
                .clipShape(Circle())
        }
    }
}