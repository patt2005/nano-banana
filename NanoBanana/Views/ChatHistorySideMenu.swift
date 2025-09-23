import SwiftUI

struct ChatHistorySideMenu: View {
    @ObservedObject var chatViewModel: ChatViewModel
    @Binding var showMenu: Bool
    @State private var showDeleteAllAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with New Chat button
            HStack {
                Text("Chat History")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                // New Chat icon button
                Button(action: {
                    chatViewModel.startNewChat()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showMenu = false
                    }
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(Color.yellow)
                        .cornerRadius(10)
                }

                // Delete all button
                Button(action: {
                    showDeleteAllAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                        .frame(width: 40, height: 40)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.black)

            // Chat history list
            if chatViewModel.chatHistories.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))

                    Text("No chat history")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(chatViewModel.chatHistories.sorted(by: { $0.date > $1.date })) { chat in
                            Button(action: {
                                chatViewModel.loadChatFromHistory(chat)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                                    showMenu = false
                                }
                            }) {
                                HStack(spacing: 12) {
                                    // Chat icon
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(hex: "FFD700").opacity(0.2),
                                                        Color(hex: "FFA500").opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 40, height: 40)

                                        Image(systemName: "message.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "FFD700"))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        // Chat preview
                                        Text(chat.messages.first?.content ?? "New Chat")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)

                                        HStack(spacing: 8) {
                                            Text(formatDate(chat.date))
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray.opacity(0.8))

                                            if chat.messages.count > 1 {
                                                Text("•")
                                                    .foregroundColor(.gray.opacity(0.6))

                                                Text("\(chat.messages.count) messages")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.gray.opacity(0.8))
                                            }
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.gray.opacity(0.25),
                                                    Color.gray.opacity(0.15)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
            }

        }
        .background(Color.black)
        .alert("Delete All Chats", isPresented: $showDeleteAllAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                chatViewModel.clearAllHistory()
            }
        } message: {
            Text("Are you sure you want to delete all chat history? This action cannot be undone.")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday, \(formatter.string(from: date))"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE, h:mm a"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
}

struct ChatHistorySideMenu_Previews: PreviewProvider {
    @StateObject static var chatViewModel = ChatViewModel()

    static var previews: some View {
        ChatHistorySideMenu(
            chatViewModel: chatViewModel,
            showMenu: .constant(true)
        )
    }
}
