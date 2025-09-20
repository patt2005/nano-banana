import SwiftUI

struct HistoryView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                if chatViewModel.chatHistories.isEmpty {
                    // Modern Empty State
                    VStack(spacing: 30) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "clock")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(Color.orange)
                        }
                        
                        VStack(spacing: 12) {
                            Text("No History Yet")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Your chat conversations will appear here when you start chatting with NanoBanana")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .padding(.horizontal, 40)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "121419"))
                } else {
                    // Chat History List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatViewModel.chatHistories) { chatHistory in
                                ChatHistoryRow(
                                    chatHistory: chatHistory,
                                    onTap: {
                                        chatViewModel.loadChatFromHistory(chatHistory)
                                        presentationMode.wrappedValue.dismiss()
                                    },
                                    onDelete: {
                                        chatViewModel.deleteChatHistory(withId: chatHistory.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    .background(Color(hex: "121419"))
                }
            }
            .background(Color(hex: "121419"))
            .navigationBarHidden(true)
            .alert("Are you sure?", isPresented: $showingClearAlert) {
                Button("Clear All", role: .destructive) {
                    chatViewModel.clearAllChatHistories()
                    chatViewModel.clearChat()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all chat history.")
            }
        }
    }
}

struct ChatHistoryRow: View {
    let chatHistory: ChatHistory
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Chat Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(chatHistory.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(chatHistory.lastMessagePreview)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    Text(formatChatDate(chatHistory.lastMessageDate))
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.8))
                }
                
                Spacer()
                
                // Delete Button
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Delete Chat", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete this chat conversation.")
        }
    }
    
    private func formatChatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return "Today, " + formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "Yesterday, " + formatter.string(from: date)
        } else if calendar.dateComponents([.day], from: date, to: now).day! < 7 {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

