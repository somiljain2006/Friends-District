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
    @AppStorage("profilePhone") private var storedPhone = ""
    
    enum SearchMode: String, CaseIterable {
        case phone = "Phone Number"
        case email = "Email Address"
    }
    
    @State private var selectedMode: SearchMode = .phone
    @State private var phoneNumber = ""
    @State private var emailAddress = ""
    
    // API States (Send Request)
    @State private var isSending = false
    @State private var requestStatus: RequestStatus = .idle
    
    // API States (Accept Request)
    @State private var pendingRequests: [String] = []
    @State private var acceptingPhones: Set<String> = []
    @State private var acceptError: String? = nil
    
    enum RequestStatus {
        case idle
        case success
        case error(String)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    
                    segmentedControl
                    
                    Text(selectedMode == .phone ? "Enter your friend's phone number" : "Enter your friend's email address")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 4)
                    
                    if selectedMode == .phone {
                        inputField(
                            placeholder: "+91 XXXXX XXXXX",
                            text: $phoneNumber,
                            systemImage: "phone.fill"
                        )
                        .keyboardType(.phonePad)
                    } else {
                        inputField(
                            placeholder: "Enter email address",
                            text: $emailAddress,
                            systemImage: "envelope.fill"
                        )
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    }
                    
                    Divider()
                        .overlay(Color.white.opacity(0.12))
                        .padding(.top, 16)
                    
                    // Dynamic Search Result Block
                    if selectedMode == .phone && !phoneNumber.isEmpty {
                        Text("Search Result")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.top, 6)
                        
                        searchResultBlock
                    } else if selectedMode == .email && !emailAddress.isEmpty {
                        Text("Search Result")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.top, 6)
                        
                        Text("Search by email is not supported yet.")
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 8)
                    }
                    
                    // NEW: Pending Friend Requests Section
                    friendRequestsSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: phoneNumber) { _ in
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
    
    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(SearchMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: mode == .phone ? "phone.fill" : "envelope")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text(mode.rawValue)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundStyle(selectedMode == mode ? .white : .white.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(selectedMode == mode ? Color(red: 0.52, green: 0.22, blue: 0.95) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
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
                    Text(phoneNumber)
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
    
    // MARK: - Friend Requests Section (NEW)
    
    private var friendRequestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Friend Requests")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 16)
            
            if pendingRequests.isEmpty {
                Text("No pending requests.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 4)
            } else {
                ForEach(pendingRequests, id: \.self) { phone in
                    pendingRequestRow(for: phone)
                }
            }
            
            if let acceptError = acceptError {
                Text(acceptError)
                    .font(.system(size: 14))
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.top, 4)
            }
        }
    }
    
    private func pendingRequestRow(for phone: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.95, green: 0.45, blue: 0.22)) // Distinct color for incoming requests
                    .frame(width: 54, height: 54)
                
                Image(systemName: "person.fill.badge.plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(phone)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                
                Text("Sent you a request")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Button {
                Task {
                    await acceptFriendRequest(friendPhone: phone)
                }
            } label: {
                ZStack {
                    if acceptingPhones.contains(phone) {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Accept")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(Color(red: 0.16, green: 0.75, blue: 0.36)) // Green color to denote "Accept"
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(acceptingPhones.contains(phone))
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
                            .stroke(Color(red: 0.52, green: 0.22, blue: 0.95), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.52, green: 0.22, blue: 0.95))
            }
        }
    }
    
    // MARK: - API Calls
    
    private func sendFriendRequest() async {
        guard !phoneNumber.isEmpty else { return }
        
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
            "user_phone": storedPhone,
            "friend_phone": phoneNumber
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
    
    // NEW: Accept Friend Request API Call
    private func acceptFriendRequest(friendPhone: String) async {
        acceptError = nil
        acceptingPhones.insert(friendPhone)
        
        guard let url = URL(string: "https://district.monu14.me/api/v1/friends/accept") else {
            acceptingPhones.remove(friendPhone)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "user_phone": storedPhone,
            "friend_phone": friendPhone
        ]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                acceptingPhones.remove(friendPhone)
                
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        // On success, we remove the user from the UI list
                        withAnimation {
                            pendingRequests.removeAll { $0 == friendPhone }
                        }
                    case 400:
                        acceptError = "Invalid request parameters."
                    case 404:
                        acceptError = "Friend request not found."
                    case 500:
                        acceptError = "Server Error. Please try again later."
                    default:
                        acceptError = "Failed to accept. Please try again."
                    }
                } else {
                    acceptError = "Unknown error occurred."
                }
            }
        } catch {
            await MainActor.run {
                acceptingPhones.remove(friendPhone)
                acceptError = "Network error: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    AddFriendView()
}
