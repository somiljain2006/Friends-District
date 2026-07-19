//
//  AddFriendView.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Grab the stored phone from ProfileSetupView or Login
    @AppStorage("profileUsername") private var storedUsername = ""
    
    @State private var searchUsername = ""
    
    // API States (Send Request)
    @State private var isSending = false
    @State private var requestStatus: RequestStatus = .idle
    
    // API States (Requests)
    @State private var receivedRequests: [FriendModel] = []
    @State private var sentRequests: [FriendModel] = []
    @State private var isLoadingRequests = false
    @State private var acceptingUsernames: Set<String> = []
    @State private var rejectingUsernames: Set<String> = []
    @State private var requestsError: String? = nil
    
    enum RequestStatus {
        case idle
        case success
        case error(String)
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.008, green: 0.008, blue: 0.012).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    
                    Text("Enter your friend's username")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 4)
                    
                    inputField(
                        placeholder: "@username",
                        text: $searchUsername,
                        systemImage: "person.fill"
                    )
                    .textInputAutocapitalization(.never)
                    
                    Divider()
                        .overlay(Color.white.opacity(0.12))
                        .padding(.top, 16)
                    
                    // Dynamic Search Result Block
                    if !searchUsername.isEmpty {
                        Text("Search Result")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.top, 6)
                        
                        searchResultBlock
                    }
                    
                    // NEW: Received and Sent Requests Sections
                    receivedRequestsSection
                    sentRequestsSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await fetchRequests()
        }
        .onChange(of: searchUsername) { oldValue, newValue in
            // Reset status when user types a new number
            requestStatus = .idle
        }
    }
    
    private var topBar: some View {
        HStack(spacing: 16) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            
            Text("Add Friend")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            
            Spacer()
        }
    }
    
    private func inputField(placeholder: String, text: Binding<String>, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white.opacity(0.45))
            
            TextField(placeholder, text: text)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .frame(height: 62)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private var searchResultBlock: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.14, green: 0.33, blue: 0.87))
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(searchUsername)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Text("User on District")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                Spacer()
                
                Button {
                    Task {
                        await sendFriendRequest()
                    }
                } label: {
                    ZStack {
                        if isSending {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(buttonTitle)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(buttonTextColor)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(buttonBackground)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isSending || isRequested)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            
            if case .error(let message) = requestStatus {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Received & Sent Requests Sections
    
    private var receivedRequestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Received Requests")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 16)
            
            if isLoadingRequests {
                ProgressView().tint(.white).padding(.top, 4)
            } else if receivedRequests.isEmpty {
                Text("No pending received requests.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 4)
            } else {
                ForEach(receivedRequests) { request in
                    receivedRequestRow(for: request)
                }
            }
            
            if let requestsError = requestsError {
                Text(requestsError)
                    .font(.system(size: 14))
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.top, 4)
            }
        }
    }
    
    private func receivedRequestRow(for request: FriendModel) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(request.color)
                    .frame(width: 54, height: 54)
                
                Text(request.initials)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.name)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                
                Text(request.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Reject Button
            Button {
                Task {
                    await rejectFriendRequest(friendUsername: (request.username ?? ""))
                }
            } label: {
                ZStack {
                    if rejectingUsernames.contains((request.username ?? "")) {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(rejectingUsernames.contains((request.username ?? "")) || acceptingUsernames.contains((request.username ?? "")))
            
            // Accept Button
            Button {
                Task {
                    await acceptFriendRequest(friendUsername: (request.username ?? ""))
                }
            } label: {
                ZStack {
                    if acceptingUsernames.contains((request.username ?? "")) {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 36, height: 36)
                .background(Color(red: 0.16, green: 0.75, blue: 0.36))
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(acceptingUsernames.contains((request.username ?? "")) || rejectingUsernames.contains((request.username ?? "")))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var sentRequestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sent Requests")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 16)
            
            if !isLoadingRequests && sentRequests.isEmpty {
                Text("No pending sent requests.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 4)
            } else {
                ForEach(sentRequests) { request in
                    sentRequestRow(for: request)
                }
            }
        }
    }
    
    private func sentRequestRow(for request: FriendModel) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(request.color)
                    .frame(width: 54, height: 54)
                
                Text(request.initials)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(request.name)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                
                Text(request.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Text("Pending")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Button Styling Helpers
    
    private var isRequested: Bool {
        if case .success = requestStatus { return true }
        return false
    }
    
    private var buttonTitle: String {
        isRequested ? "Requested" : "Add"
    }
    
    private var buttonTextColor: Color {
        isRequested ? Color(red: 0.72, green: 0.45, blue: 0.95) : .white
    }
    
    private var buttonBackground: some View {
        Group {
            if isRequested {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(red: 0.37, green: 0.42, blue: 0.82), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.37, green: 0.42, blue: 0.82))
            }
        }
    }
    
    // MARK: - API Calls
    
    private func sendFriendRequest() async {
        guard !searchUsername.isEmpty else { return }
        
        isSending = true
        requestStatus = .idle
        
        guard let url = URL(string: "https://district.monu14.me/api/v1/friends/request") else {
            isSending = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "username": storedUsername,
            "friend_username": searchUsername
        ]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                isSending = false
                
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 201:
                        requestStatus = .success
                        Task { await fetchRequests() }
                    case 400:
                        requestStatus = .error("Invalid request or already friends.")
                    case 404:
                        requestStatus = .error("User not found.")
                    default:
                        requestStatus = .error("Server error. Please try again.")
                    }
                } else {
                    requestStatus = .error("Unknown error occurred.")
                }
            }
        } catch {
            await MainActor.run {
                isSending = false
                requestStatus = .error("Network error: \(error.localizedDescription)")
            }
        }
    }
    
    // Accept Friend Request API Call
    private func acceptFriendRequest(friendUsername: String) async {
        requestsError = nil
        acceptingUsernames.insert(friendUsername)
        
        guard let url = URL(string: "https://district.monu14.me/api/v1/friends/accept") else {
            acceptingUsernames.remove(friendUsername)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "username": storedUsername,
            "friend_username": friendUsername
        ]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                acceptingUsernames.remove(friendUsername)
                
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        // On success, we remove the user from the UI list
                        withAnimation {
                            receivedRequests.removeAll { $0.username == friendUsername }
                        }
                    case 400:
                        requestsError = "Invalid request parameters."
                    case 404:
                        requestsError = "Friend request not found."
                    case 500:
                        requestsError = "Server Error. Please try again later."
                    default:
                        requestsError = "Failed to accept. Please try again."
                    }
                } else {
                    requestsError = "Unknown error occurred."
                }
            }
        } catch {
            await MainActor.run {
                acceptingUsernames.remove(friendUsername)
                requestsError = "Network error: \(error.localizedDescription)"
            }
        }
    }

    private func rejectFriendRequest(friendUsername: String) async {
        requestsError = nil
        rejectingUsernames.insert(friendUsername)
        
        guard let url = URL(string: "https://district.monu14.me/api/v1/friends/reject") else {
            rejectingUsernames.remove(friendUsername)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "username": storedUsername,
            "friend_username": friendUsername
        ]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                rejectingUsernames.remove(friendUsername)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    withAnimation {
                        receivedRequests.removeAll { $0.username == friendUsername }
                    }
                } else {
                    requestsError = "Failed to reject. Please try again."
                }
            }
        } catch {
            await MainActor.run {
                rejectingUsernames.remove(friendUsername)
                requestsError = "Network error: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchRequests() async {
        isLoadingRequests = true
        requestsError = nil
        
        let cleanPhone = storedUsername.replacingOccurrences(of: " ", with: "")
        guard let encodedUsername = cleanPhone.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            isLoadingRequests = false
            return
        }
        
        async let receivedRes = fetchRequestList(endpoint: "received", phone: encodedUsername)
        async let sentRes = fetchRequestList(endpoint: "sent", phone: encodedUsername)
        
        do {
            let (rData, sData) = try await (receivedRes, sentRes)
            await MainActor.run {
                self.receivedRequests = rData
                self.sentRequests = sData
                self.isLoadingRequests = false
            }
        } catch {
            await MainActor.run {
                self.requestsError = "Failed to load requests."
                self.isLoadingRequests = false
            }
        }
    }
    
    private func fetchRequestList(endpoint: String, phone: String) async throws -> [FriendModel] {
        guard let url = URL(string: "https://district.monu14.me/api/v1/friends/requests/\(endpoint)?username=\(phone)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([FriendModel].self, from: data)
    }
}

#Preview {
    AddFriendView()
}
