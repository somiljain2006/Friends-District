//
//  FriendListView.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import SwiftUI

// MARK: - API Models
struct FriendModel: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String?
    let mobile_number: String
    let username: String?
    let status: String
    let created_at: String?
    let updated_at: String?
    
    // Computed properties for UI integration
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first.map { String($0) } ?? ""
        let lastInitial = components.count > 1 ? (components.last?.first.map { String($0) } ?? "") : ""
        let result = (firstInitial + lastInitial).uppercased()
        return result.isEmpty ? "?" : result
    }
    
    var color: Color {
        // Deterministic color generation based on the name so it stays consistent
        let predefinedColors: [Color] = [
            Color(red: 0.42, green: 0.20, blue: 0.83),
            Color(red: 0.74, green: 0.11, blue: 0.34),
            Color(red: 0.14, green: 0.33, blue: 0.87),
            Color(red: 0.05, green: 0.50, blue: 0.36),
            Color(red: 0.72, green: 0.33, blue: 0.06)
        ]
        let hash = abs(name.hashValue)
        return predefinedColors[hash % predefinedColors.count]
    }
    
    var subtitle: String {
        if let username = username, !username.isEmpty {
            return "@\(username)"
        }
        return status.capitalized
    }
}

struct FriendListView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Pull the logged-in user's phone from AppStorage to use in the API request
    @AppStorage("profileUsername") private var storedUsername = ""
    
    // States
    @State private var friends: [FriendModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.06).ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Friend List")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.top, 6)
                        
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.red.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else if friends.isEmpty {
                            Text("No accepted friends found.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(friends) { friend in
                                    FriendRow(friend: friend)
                                    
                                    if friend.id != friends.last?.id {
                                        Divider()
                                            .overlay(Color.white.opacity(0.08))
                                            .padding(.leading, 72)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await fetchFriends()
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
            
            Spacer()
        }
    }
    
    // MARK: - Logic & API Calls
    
    private func fetchFriends() async {
        isLoading = true
        errorMessage = nil
        
        // Clean up stored phone: remove spaces added in ProfileSetupView (e.g., "+91 9999999999" -> "+919999999999")
        let cleanPhone = storedUsername.replacingOccurrences(of: " ", with: "")
        
        // Ensure the phone number is correctly URL encoded (converting `+` to `%2B`)
        guard let encodedUsername = cleanPhone.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://district.monu14.me/api/v1/friends?username=\(encodedUsername)") else {
            errorMessage = "Invalid API URL setup."
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Bad server response."
                isLoading = false
                return
            }
            
            if httpResponse.statusCode == 200 {
                let decodedResponse = try JSONDecoder().decode([FriendModel].self, from: data)
                await MainActor.run {
                    self.friends = decodedResponse
                    self.isLoading = false
                }
            } else {
                errorMessage = "Failed to load friends. Status: \(httpResponse.statusCode)"
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Error connecting to server: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

struct FriendRow: View {
    let friend: FriendModel
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(friend.color)
                    .frame(width: 54, height: 54)
                
                Text(friend.initials)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                
                Text(friend.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Button {
                // open friend details or chat
            } label: {
                Text("View")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.37, green: 0.42, blue: 0.82))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

#Preview {
    FriendListView()
}
