//  GroupChatView.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import SwiftUI
internal import Combine

// MARK: - Models
struct RoomMessage: Codable, Identifiable {
    let id: Int
    let content: String
    let created_at: String
    let external_event_id: String?
    let external_event_type: String?
    let room_id: Int
    let sender_id: Int
}

// MARK: - View Model
@MainActor
class GroupChatViewModel: ObservableObject {
    @Published var messages: [RoomMessage] = []
    @Published var isLoading = true
    @Published var errorMessage: String? = nil

    // WebSocket Task reference
    private var webSocketTask: URLSessionWebSocketTask?

    /// Fetches initial history via REST API
    func fetchMessages(roomId: Int) async {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://district.monu14.me/api/v1/rooms/\(roomId)/messages") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Failed to load messages."
                isLoading = false
                return
            }
            
            let decodedMessages = try JSONDecoder().decode([RoomMessage].self, from: data)
            self.messages = decodedMessages
        } catch {
            print("Failed to decode messages: \(error)")
            self.errorMessage = "Something went wrong."
        }
        
        isLoading = false
    }

    /// Establishes the real-time WebSocket connection
    func connectWebSocket(roomId: Int, userPhone: String) {
        // Close existing connections to prevent duplicate sockets
        disconnectWebSocket()

        // Manually percent-encode '+' to '%2B' because URLComponents ignores it.
        let encodedPhone = userPhone.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacingOccurrences(of: "+", with: "%2B") ?? userPhone
        
        guard let url = URL(string: "wss://district.monu14.me/api/v1/rooms/\(roomId)/ws?user_phone=\(encodedPhone)") else {
            print("❌ Invalid WebSocket URL Configuration")
            return
        }

        print("🔌 Connecting to WebSocket: \(url.absoluteString)")
        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: url)
        self.webSocketTask = task
        task.resume()

        // Start listening looping mechanism for incoming frames
        Task {
            await listenForWebSocketMessages()
        }
    }

    /// Safely terminates the active WebSocket connection
    func disconnectWebSocket() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        print("🛑 WebSocket Connection Closed")
    }

    /// Continuously listens for incoming real-time text updates
    private func listenForWebSocketMessages() async {
        guard let task = webSocketTask else { return }

        do {
            let receivedFrame = try await task.receive()
            
            switch receivedFrame {
            case .string(let textFrameContent):
                if let data = textFrameContent.data(using: .utf8) {
                    parseAndAppendIncomingMessage(data)
                }
            case .data(let rawDataFrameContent):
                parseAndAppendIncomingMessage(rawDataFrameContent)
            @unknown default:
                break
            }

            // Immediately loop back to keep listening for the next incoming payload
            await listenForWebSocketMessages()
        } catch {
            print("❌ WebSocket tracking error occurred: \(error.localizedDescription)")
            // Connection drops out? Handle reconnect attempts here if needed
        }
    }

    /// Safely decodes text payloads to append to the active message state array
    private func parseAndAppendIncomingMessage(_ data: Data) {
        do {
            let incomingMsg = try JSONDecoder().decode(RoomMessage.self, from: data)
            // Ensure UI updates stay isolated safely onto the Main Thread
            self.messages.append(incomingMsg)
        } catch {
            // Fallback to print the actual string token starting with 'Y' if decoding fails
            if let rawString = String(data: data, encoding: .utf8) {
                print("⚠️ Server sent a non-JSON payload: \"\(rawString)\"")
            }
            print("⚠️ Failed to parse incoming socket event payload: \(error)")
        }
    }

    /// Transmits messages natively over the WebSocket connection
    func sendRealtimeMessage(text: String) {
        guard let task = webSocketTask, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Adjust the outgoing object layout if your server requires full JSON shapes instead of plain text strings
        let framePayload = URLSessionWebSocketTask.Message.string(text)
        
        Task {
            do {
                try await task.send(framePayload)
            } catch {
                print("❌ Failed transmitting data frame over stream: \(error)")
            }
        }
    }
}

// MARK: - View
struct GroupChatView: View {
    let room: Room
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = GroupChatViewModel()
    @State private var messageText = ""
    @State private var showGroupInfo = false

    // Pull the active phone number setup directly out from your local AppStorage cache
    @AppStorage("profilePhone") private var userPhone = ""

    var body: some View {
        VStack(spacing: 0) {
            topNavigationBar

            Divider()
                .overlay(Color.white.opacity(0.1))

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Group Space created · plan your outing here")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                            .padding(.top, 20)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 40)
                        } else if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundStyle(.red.opacity(0.8))
                                .padding(.top, 40)
                        } else {
                            ForEach(viewModel.messages) { message in
                                let senderDetails = getSenderDetails(for: message.sender_id)
                                
                                userMessageRow(
                                    initials: senderDetails.initials,
                                    name: senderDetails.name,
                                    avatarColor: senderDetails.color,
                                    content: Text(message.content)
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    // Automatically auto-scroll view downward as new updates arrive
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            bottomInputBar
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.09).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showGroupInfo) {
            GroupInfoView(room: room, memberCount: 4)
        }
        .task {
            // 1. Fetch historical data traces
            await viewModel.fetchMessages(roomId: room.id)
            // 2. Open up real-time bidirectional messaging pipeline
            viewModel.connectWebSocket(roomId: room.id, userPhone: userPhone)
        }
        .onDisappear {
            // Clear socket reference allocation cleanly when the screen tears down
            viewModel.disconnectWebSocket()
        }
    }

    private var topNavigationBar: some View {
        HStack(spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundStyle(.white.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(room.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Text("4 members · Group Space")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(8)
                .background(Circle().fill(Color.white.opacity(0.05)))

            Button {
                showGroupInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.05)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func userMessageRow(initials: String, name: String, avatarColor: Color, content: some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.leading, 50)

            HStack(alignment: .bottom, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(avatarColor)
                        .frame(width: 30, height: 30)

                    Text(initials)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }

                content
                Spacer()
            }
        }
    }
    
    // MARK: - Helpers
    private func getSenderDetails(for senderId: Int) -> (name: String, initials: String, color: Color) {
        let colors: [Color] = [
            Color(red: 0.42, green: 0.20, blue: 0.83),
            Color(red: 0.60, green: 0.10, blue: 0.40),
            Color(red: 0.20, green: 0.50, blue: 0.80),
            Color(red: 0.10, green: 0.60, blue: 0.30),
            Color(red: 0.80, green: 0.40, blue: 0.10)
        ]
        
        let color = colors[abs(senderId) % colors.count]
        return ("User \(senderId)", "U\(senderId)", color)
    }

    private var bottomInputBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("Ask @Planner")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0.65, green: 0.40, blue: 1.0))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(red: 0.20, green: 0.10, blue: 0.35))
                .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                TextField("Message or @Planner...", text: $messageText)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())

                Button {
                    let textToSend = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !textToSend.isEmpty {
                        // Transmit message data via the websocket lifecycle hook
                        viewModel.sendRealtimeMessage(text: textToSend)
                        messageText = ""
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 48, height: 48)
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(Color(red: 0.08, green: 0.08, blue: 0.09))
    }
}

#Preview {
    GroupsView()
}
