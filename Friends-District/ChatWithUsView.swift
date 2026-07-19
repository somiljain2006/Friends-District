//
//  ChatWithUsView.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import SwiftUI
internal import Combine
import FoundationModels

// MARK: - View Model
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messageText = ""
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    @Published var isModelAvailable = false

    let suggestionChips = [
        "More nearby options",
        "Events this weekend",
        "Top-rated cafes"
    ]

    // The live on-device session. Kept around across turns so the model
    // remembers earlier messages in this conversation.
    private var session: LanguageModelSession?

    init() {
        configureSession()

        messages.append(
            ChatMessage(
                isUser: false,
                text: greetingText(),
                time: currentTime(),
                places: []
            )
        )
    }

    // MARK: - Setup

    /// Checks whether Apple Intelligence is actually usable on this device and,
    /// if so, spins up a LanguageModelSession with instructions that scope the
    /// model to being a Friends District concierge.
    private func configureSession() {
        switch SystemLanguageModel.default.availability {
        case .available:
            isModelAvailable = true
            session = LanguageModelSession(instructions: """
                You are the concierge chatbot for Friends District, a local \
                community app. Help the person with recommendations for \
                restaurants, cafes, and events, and general local questions.
                Keep answers short and warm, 2-4 sentences.
                You do not have live access to Friends District's actual \
                business or events database, so speak in general, helpful \
                terms and never invent specific restaurant names, addresses, \
                ratings, or event dates as if they were real listings.
                """)

        case .unavailable(.deviceNotEligible):
            isModelAvailable = false

        case .unavailable(.appleIntelligenceNotEnabled):
            isModelAvailable = false

        case .unavailable(.modelNotReady):
            isModelAvailable = false

        case .unavailable:
            isModelAvailable = false
        }
    }

    private func greetingText() -> String {
        guard isModelAvailable else {
            return unavailableExplanation()
        }
        return "Hi Somil! I’m here to help you with anything you need. Ask me anything!"
    }

    private func unavailableExplanation() -> String {
        switch SystemLanguageModel.default.availability {
        case .unavailable(.deviceNotEligible):
            return "This device doesn't support Apple Intelligence, so I can't chat right now."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Apple Intelligence is turned off. Enable it in Settings to chat with me."
        case .unavailable(.modelNotReady):
            return "The on-device model is still downloading. Give it a bit and try again."
        default:
            return "I'm not available on this device right now."
        }
    }

    // MARK: - Sending messages

    func sendMessage(text: String? = nil) {
        let textToSend = text ?? messageText
        guard !textToSend.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // 1. Add user message
        let userMessage = ChatMessage(isUser: true, text: textToSend, time: currentTime())
        messages.append(userMessage)
        messageText = ""

        guard let session else {
            appendAssistantMessage(unavailableExplanation())
            return
        }

        isTyping = true

        Task {
            await streamReply(from: session, to: textToSend)
        }
    }

    // MARK: - Real generation

    private func streamReply(from session: LanguageModelSession, to prompt: String) async {
        let aiMessageId = UUID()
        var hasStartedStreaming = false

        do {
            let stream = session.streamResponse(to: prompt)

            for try await partial in stream {
                if !hasStartedStreaming {
                    hasStartedStreaming = true
                    isTyping = false
                    // Insert the (initially empty) bubble once the model starts
                    // producing tokens, same as the old streaming placeholder.
                    messages.append(
                        ChatMessage(id: aiMessageId, isUser: false, text: "", time: currentTime())
                    )
                }

                if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                    messages[index].text = partial.content
                }
            }

            // If the stream produced no tokens at all (rare, but possible),
            // make sure the user still sees something.
            if !hasStartedStreaming {
                isTyping = false
                appendAssistantMessage("I didn't catch a response there — could you try rephrasing?")
            }
        } catch let error as LanguageModelSession.GenerationError {
            isTyping = false
            handleGenerationError(error, existingMessageId: hasStartedStreaming ? aiMessageId : nil)
        } catch {
            isTyping = false
            let text = "Something went wrong generating a reply: \(error.localizedDescription)"
            if hasStartedStreaming, let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                messages[index].text = text
            } else {
                appendAssistantMessage(text)
            }
        }
    }

    private func handleGenerationError(_ error: LanguageModelSession.GenerationError, existingMessageId: UUID?) {
        let text: String
        switch error {
        case .guardrailViolation:
            text = "I can't help with that one — let's try something else."
        case .exceededContextWindowSize:
            text = "This chat's gotten a bit long for me to keep track of. Try starting a fresh conversation."
            // Reset the session so the next message starts a clean context window.
            configureSession()
        case .unsupportedLanguageOrLocale:
            text = "I don't support that language yet — mind trying in English?"
        case .assetsUnavailable:
            text = "The on-device model isn't ready right now. Please try again in a moment."
        case .rateLimited:
            text = "I'm getting a lot of requests right now — give it a few seconds and try again."
        default:
            text = "Sorry, I couldn't generate a reply just now."
        }

        if let existingMessageId, let index = messages.firstIndex(where: { $0.id == existingMessageId }) {
            messages[index].text = text
        } else {
            appendAssistantMessage(text)
        }
    }

    private func appendAssistantMessage(_ text: String) {
        messages.append(ChatMessage(isUser: false, text: text, time: currentTime()))
    }

    private func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

// MARK: - Models
struct ChatMessage: Identifiable, Equatable {
    var id = UUID() // Changed to var so we can explicitly set it
    let isUser: Bool
    var text: String // Changed to var so we can update it during streaming
    let time: String
    var places: [PlaceCard] = []
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id && lhs.text == rhs.text // Added text to equatable check
    }
}

struct PlaceCard: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let category: String
    let description: String
    let image: String
}

// MARK: - Views
struct ChatWithUsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChatViewModel()
    
    // Reference our shared Siri manager
    @ObservedObject private var siriManager = SiriManager.shared
    
    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {
                            
                            dividerWithTitle("Today")
                                .padding(.top, 6)
                            
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isTyping {
                                typingIndicator
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .id("typingIndicator")
                            }
                            
                            chipRow
                                .padding(.top, 6)
                            
                            footerNote
                                .padding(.top, 10)
                                .padding(.bottom, 20)
                                .id("bottom")
                        }
                        .padding(.horizontal, 18)
                    }
                    .onChange(of: viewModel.messages.count) { oldValue, newValue in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    // Keep scroll at bottom while streaming text updates
                    .onChange(of: viewModel.messages.last?.text) { oldValue, newValue in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.isTyping) { oldValue, isTyping in
                        if isTyping {
                            withAnimation {
                                proxy.scrollTo("typingIndicator", anchor: .bottom)
                            }
                        }
                    }
                }
                
                inputBar
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onReceive(siriManager.$incomingSiriQuery) { query in
            if let query = query, !query.isEmpty {
                viewModel.sendMessage(text: query)
                siriManager.incomingSiriQuery = nil
            }
        }
    }
    
    // MARK: - UI Components
    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.008, green: 0.008, blue: 0.012),
                Color(red: 0.02, green: 0.02, blue: 0.024),
                Color(red: 0.008, green: 0.008, blue: 0.012)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            RadialGradient(
                colors: [
                    Color(red: 0.37, green: 0.42, blue: 0.82).opacity(0.12),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 30,
                endRadius: 420
            )
        )
    }
    
    private var topBar: some View {
        HStack(spacing: 14) {
            Button { dismiss() } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            
            ZStack {
                Circle()
                    .fill(Color(red: 0.44, green: 0.22, blue: 0.95))
                    .frame(width: 50, height: 50)
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Chat with us")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    Text("Powered by Apple Intelligence")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            Spacer()
        }
    }
    
    private func quickActionIcon(title: String, systemImage: String) -> some View {
        Button {
            viewModel.sendMessage(text: title)
        } label: {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.purple.opacity(0.85))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.03))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
    
    private func dividerWithTitle(_ title: String) -> some View {
        HStack(spacing: 14) {
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
            Text(title).font(.system(size: 16, weight: .medium)).foregroundStyle(.white.opacity(0.45))
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
        }
    }
    
    private var chipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.suggestionChips, id: \.self) { chip in
                    Button {
                        viewModel.sendMessage(text: chip)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: chip == "More nearby options" ? "fork.knife" :
                                    chip == "Events this weekend" ? "calendar" : "mappin.and.ellipse")
                                .font(.system(size: 16, weight: .semibold))
                            Text(chip).font(.system(size: 15, weight: .medium))
                        }
                        .foregroundStyle(Color(red: 0.78, green: 0.65, blue: 1.0))
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(
                            Capsule().fill(Color.white.opacity(0.03))
                                .overlay(Capsule().stroke(Color.white.opacity(0.07), lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    private var footerNote: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "lock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                Text("Chats may be reviewed to improve our service.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Message anything...", text: $viewModel.messageText)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .onSubmit {
                    viewModel.sendMessage()
                }
            
            Button { viewModel.sendMessage() } label: {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.44, green: 0.22, blue: 0.95))
                        .frame(width: 48, height: 48)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
        }
        .frame(height: 70)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
    
    private var typingIndicator: some View {
        HStack(spacing: 4) {
            Circle().fill(.white.opacity(0.5)).frame(width: 6, height: 6)
            Circle().fill(.white.opacity(0.5)).frame(width: 6, height: 6)
            Circle().fill(.white.opacity(0.5)).frame(width: 6, height: 6)
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Subviews
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.isUser {
                Spacer(minLength: 50)
                VStack(alignment: .trailing, spacing: 8) {
                    Text(message.text)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.white)
                        .padding(18)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.49, green: 0.22, blue: 0.97), Color(red: 0.36, green: 0.20, blue: 0.92)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    Text(message.time).font(.system(size: 13, weight: .regular)).foregroundStyle(.white.opacity(0.45))
                }
            } else {
                ZStack {
                    Circle().fill(Color.white.opacity(0.06)).frame(width: 34, height: 34)
                    Circle()
                        .fill(RadialGradient(colors: [Color.pink.opacity(0.9), Color.purple.opacity(0.7), Color.blue.opacity(0.7)], center: .center, startRadius: 2, endRadius: 30))
                        .frame(width: 24, height: 24)
                }
                .padding(.bottom, 22)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Only show text bubble if there is text (hides it momentarily when stream starts)
                    if !message.text.isEmpty {
                        Text(message.text)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(.white)
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
                    }
                    
                    if !message.places.isEmpty {
                        VStack(spacing: 16) {
                            ForEach(message.places) { place in
                                PlaceRow(place: place)
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.black.opacity(0.22)))
                        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
                    }
                    Text(message.time).font(.system(size: 13, weight: .regular)).foregroundStyle(.white.opacity(0.45))
                }
            }
        }
    }
}

struct PlaceRow: View {
    let place: PlaceCard
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 74, height: 74)
                .overlay(Image(place.image).resizable().scaledToFill())
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(place.name).font(.system(size: 19, weight: .medium)).foregroundStyle(.white)
                Text(place.category).font(.system(size: 15, weight: .regular)).foregroundStyle(.white.opacity(0.55))
                Text(place.description).font(.system(size: 15, weight: .regular)).foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
        }
    }
}

#Preview {
    ChatWithUsView()
}
