import SwiftUI

struct HistoryView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    Text("History")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        showingClearAlert = true
                    }) {
                        Text("Clear")
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(hex: "121419"))
                
                // History Content
                if true { // Always show empty state for now
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "9e9d99"))
                        
                        VStack(spacing: 8) {
                            Text("No History Yet")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text("Your chat conversations will appear here")
                                .font(.body)
                                .foregroundColor(Color(hex: "9e9d99"))
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "121419"))
                }
            }
            .background(Color(hex: "121419"))
            .navigationBarHidden(true)
            .alert("Are you sure?", isPresented: $showingClearAlert) {
                Button("Clear All", role: .destructive) {
                    // Clear conversation functionality
                    chatViewModel.messages.removeAll()
                    chatViewModel.currentInput = ""
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all chat history.")
            }
        }
    }
}

