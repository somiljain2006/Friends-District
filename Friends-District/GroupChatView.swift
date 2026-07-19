//  GroupChatView.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import SwiftUI
internal import Combine

// MARK: - Models
struct MessageSender: Codable {
    let id: Int
    let name: String
    let username: String
    let mobile_number: String
}

struct MessageVote: Codable, Identifiable {
    let id: Int
    let message_id: Int
    let user_id: Int
    let vote: String // "interested", "maybe", "not_interested"
}

struct RoomMessage: Codable, Identifiable {
    let id: Int
    let content: String
    let created_at: String
    let external_event_id: String?
    let external_event_type: String?
    let external_event_name: String?
    let external_event_image_url: String?
    let room_id: Int
    let sender_id: Int
    let sender: MessageSender?
    let votes: [MessageVote]?
}

// MARK: - View Model
@MainActor
class GroupChatViewModel: ObservableObject {
    @Published var messages: [RoomMessage] = []
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    @Published var memberCount: Int = 1

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

    /// Fetches the dynamic member count for this room
    func fetchMemberCount(roomId: Int) async {
        guard let url = URL(string: "https://district.monu14.me/api/v1/rooms/\(roomId)/members") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                struct DummyMember: Decodable {}
                let members = try JSONDecoder().decode([DummyMember].self, from: data)
                self.memberCount = members.count
            }
        } catch {
            print("Failed to fetch member count: \(error)")
        }
    }

    /// Establishes the real-time WebSocket connection
    func connectWebSocket(roomId: Int, storedUsername: String) {
        // Close existing connections to prevent duplicate sockets
        disconnectWebSocket()

        // Manually percent-encode '+' to '%2B' because URLComponents ignores it.
        let encodedUsername = storedUsername.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacingOccurrences(of: "+", with: "%2B") ?? storedUsername
        
        guard let url = URL(string: "wss://district.monu14.me/api/v1/rooms/\(roomId)/ws?username=\(encodedUsername)") else {
            print("❌ Invalid WebSocket URL Configuration")
            return
        }

        print("🔌 Connecting to WebSocket: \(url.absoluteString)")
        _ = URLSession(configuration: .default)
        let task = URLSession.shared.webSocketTask(with: url)
        webSocketTask = task
        
        task.resume()
        
        // Start listening looping mechanism for incoming frames
        Task {
            await listenForWebSocketMessages()
        }
    }

    func voteOnEvent(messageId: Int, storedUsername: String, vote: String) async {
        guard let url = URL(string: "https://district.monu14.me/api/v1/messages/\(messageId)/vote") else { return }
        
        let payload = [
            "username": storedUsername,
            "vote": vote
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("Failed to vote, status: \(httpResponse.statusCode)")
            }
        } catch {
            print("Error casting vote: \(error)")
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
            let decoder = JSONDecoder()
            let parsedMessage = try decoder.decode(RoomMessage.self, from: data)
            
            // If message already exists (like from a vote update), replace it
            if let index = self.messages.firstIndex(where: { $0.id == parsedMessage.id }) {
                self.messages[index] = parsedMessage
            } else {
                self.messages.append(parsedMessage)
            }
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
    @State private var selectedEventMessage: RoomMessage? = nil

    // Pull the active setup directly out from your local AppStorage cache
    @AppStorage("profileUsername") private var storedUsername = ""
    @AppStorage("profileUsername") private var userUsername = ""

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
                                let senderDetails = getSenderDetails(for: message)
                                
                                if let eventId = message.external_event_id, !eventId.isEmpty {
                                    // Interactive Event Card
                                    userMessageRow(
                                        initials: senderDetails.initials,
                                        name: senderDetails.name,
                                        avatarColor: senderDetails.color,
                                        isMe: senderDetails.isMe,
                                        content: EventMessageCard(
                                            message: message,
                                            viewModel: viewModel,
                                            storedUsername: storedUsername,
                                            onTap: {
                                                selectedEventMessage = message
                                            }
                                        )
                                    )
                                    .id(message.id)
                                } else {
                                    // Standard Text Message
                                    userMessageRow(
                                        initials: senderDetails.initials,
                                        name: senderDetails.name,
                                        avatarColor: senderDetails.color,
                                        isMe: senderDetails.isMe,
                                        content: Text(message.content)
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(senderDetails.isMe ? Color(red: 0.37, green: 0.42, blue: 0.82) : Color.white.opacity(0.06))
                                            .clipShape(RoundedRectangle(cornerRadius: 18))
                                    )
                                    .id(message.id)
                                }
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
        .background(Color(red: 0.008, green: 0.008, blue: 0.012).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showGroupInfo) {
            GroupInfoView(room: room, memberCount: viewModel.memberCount)
        }
        .sheet(item: $selectedEventMessage) { msg in
            let spotlightItem = SpotlightItem(
                id: msg.external_event_id ?? "",
                title: msg.external_event_name ?? "Event",
                description: "",
                imageUrl: msg.external_event_image_url ?? "",
                date: nil,
                location: nil,
                type: msg.external_event_type,
                url: nil,
                priceMin: nil,
                priceMax: nil
            )
            EventDetailView(item: spotlightItem, roomId: room.id)
        }
        .task {
            // 1. Fetch historical data traces
            await viewModel.fetchMessages(roomId: room.id)
            // 2. Fetch dynamic member count
            await viewModel.fetchMemberCount(roomId: room.id)
            // 3. Open up real-time bidirectional messaging pipeline
            viewModel.connectWebSocket(roomId: room.id, storedUsername: storedUsername)
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

                Text("\(viewModel.memberCount) members · Group Space")
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

    private func userMessageRow(initials: String, name: String, avatarColor: Color, isMe: Bool, content: some View) -> some View {
        VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
            Text(isMe ? "You" : name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .padding(isMe ? .trailing : .leading, isMe ? 12 : 50)

            HStack(alignment: .bottom, spacing: 12) {
                if isMe {
                    Spacer()
                    content
                } else {
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
    }
    
    // MARK: - Helpers
    private func getSenderDetails(for message: RoomMessage) -> (name: String, initials: String, color: Color, isMe: Bool) {
        let colors: [Color] = [
            Color(red: 0.42, green: 0.20, blue: 0.83),
            Color(red: 0.60, green: 0.10, blue: 0.40),
            Color(red: 0.20, green: 0.50, blue: 0.80),
            Color(red: 0.10, green: 0.60, blue: 0.30),
            Color(red: 0.80, green: 0.40, blue: 0.10)
        ]
        
        let color = colors[abs(message.sender_id) % colors.count]
        
        let name = message.sender?.name ?? "User \(message.sender_id)"
        
        let initials = name
            .components(separatedBy: .whitespaces)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .prefix(2)
            .uppercased()

        let finalInitials = initials.isEmpty ? "U\(message.sender_id)" : String(initials)
        
        let cleanSenderPhone = message.sender?.mobile_number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined() ?? ""
        let cleanUserPhone = storedUsername.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Handle cases where one phone number includes a country code and the other does not
        let phoneMatches = !cleanSenderPhone.isEmpty && !cleanUserPhone.isEmpty && (cleanSenderPhone.hasSuffix(cleanUserPhone) || cleanUserPhone.hasSuffix(cleanSenderPhone))
        
        let usernameMatches = !userUsername.isEmpty && (message.sender?.username == userUsername)
        
        let isMe = phoneMatches || usernameMatches
        
        return (name, finalInitials, color, isMe)
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
        .background(Color(red: 0.02, green: 0.02, blue: 0.024))
    }
}

// MARK: - EventMessageCard
struct EventMessageCard: View {
    let message: RoomMessage
    let viewModel: GroupChatViewModel
    let storedUsername: String
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message.content)
                .font(.system(size: 16))
                .foregroundStyle(.white)
            
            Button {
                onTap()
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    if let imageUrl = message.external_event_image_url, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle().fill(Color.white.opacity(0.1))
                                    .frame(height: 140)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            case .failure:
                                Rectangle().fill(Color.white.opacity(0.1))
                                    .frame(height: 140)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    
                    if let eventName = message.external_event_name {
                        Text(eventName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            
            HStack(spacing: 8) {
                voteButton(title: "Interested", voteKey: "interested", color: Color.green.opacity(0.2), textColor: .green)
                voteButton(title: "Maybe", voteKey: "maybe", color: Color.yellow.opacity(0.2), textColor: .yellow)
                voteButton(title: "Not", voteKey: "not_interested", color: Color.red.opacity(0.2), textColor: .red)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    @ViewBuilder
    private func voteButton(title: String, voteKey: String, color: Color, textColor: Color) -> some View {
        let count = message.votes?.filter { $0.vote == voteKey }.count ?? 0
        
        Button {
            Task {
                await viewModel.voteOnEvent(messageId: message.id, storedUsername: storedUsername, vote: voteKey)
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Text("(\(count))")
                    .font(.system(size: 12))
            }
            .foregroundStyle(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(color)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GroupsView()
}
