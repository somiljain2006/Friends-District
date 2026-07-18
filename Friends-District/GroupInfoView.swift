//
//  GroupInfoView.swift
//  Friends-District
//
//  Created by somil jain on 19/07/26.
//

import SwiftUI

struct GroupInfoView: View {
    let room: Room
    let memberCount: Int

    @Environment(\.dismiss) private var dismiss
    @AppStorage("profileUsername") private var storedUsername = "" // Needed for inviter_username

    // MARK: - API States
    @State private var members: [GroupMember] = []
    @State private var isLoadingMembers = false
    @State private var showInviteAlert = false
    @State private var inviteeUsername = ""
    @State private var isInviting = false
    @State private var inviteMessage: String?
    @State private var showStatusAlert = false

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea() // Deep black/grey background

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        
                        // MARK: - Header Profile
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                                    .frame(width: 96, height: 96)

                                Text("🎬")
                                    .font(.system(size: 40))
                            }

                            VStack(spacing: 6) {
                                Text(room.name)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(.white)

                                Text("\(members.count) members")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                        // MARK: - Members Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Members")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                // "Add members" Pill Button
                                Button {
                                    inviteeUsername = ""
                                    showInviteAlert = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.badge.plus")
                                        Text("Add members")
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.52, green: 0.22, blue: 0.95))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.clear)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(Color(red: 0.52, green: 0.22, blue: 0.95).opacity(0.8), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            VStack(spacing: 0) {
                                if isLoadingMembers && members.isEmpty {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(.vertical, 24)
                                        .frame(maxWidth: .infinity)
                                } else if members.isEmpty {
                                    Text("No members found")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.4))
                                        .padding(.vertical, 24)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    ForEach(members) { member in
                                        MemberRow(member: member)

                                        if member.id != members.last?.id {
                                            Divider()
                                                .overlay(Color.white.opacity(0.08))
                                                .padding(.leading, 72)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(red: 0.12, green: 0.12, blue: 0.13))
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            
            if isInviting {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView("Sending invite...")
                    .tint(.white)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color(red: 0.15, green: 0.15, blue: 0.18))
                    .cornerRadius(12)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await fetchRoomMembers()
        }
        .alert("Invite Member", isPresented: $showInviteAlert) {
            TextField("Enter phone number", text: $inviteeUsername)
                .keyboardType(.phonePad)
            Button("Cancel", role: .cancel) { }
            Button("Invite") {
                Task {
                    await inviteUser()
                }
            }
        } message: {
            Text("Enter the phone number of the person you want to invite.")
        }
        .alert("Invitation Status", isPresented: $showStatusAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(inviteMessage ?? "")
        }
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Text("Group")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    // MARK: - API Calls
    
    /// Fetches all members attached to this specific room ID
    private func fetchRoomMembers() async {
        guard let url = URL(string: "https://district.monu14.me/api/v1/rooms/\(room.id)/members") else { return }
        
        isLoadingMembers = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                isLoadingMembers = false
                return
            }
            
            let networkMembers = try JSONDecoder().decode([APIMember].self, from: data)
            
            // Map backend models into local display structures
            self.members = networkMembers.map { member in
                let isMe = (member.mobile_number == storedUsername)
                
                // Parse initials from their display name safely
                let cleanInitials = member.name
                    .components(separatedBy: " ")
                    .compactMap { $0.first }
                    .map { String($0) }
                    .joined()
                    .prefix(2)
                
                // Distribute colors deterministically using the database id
                let designColors: [Color] = [
                    Color(red: 0.78, green: 0.24, blue: 0.32), // Red Tint
                    Color(red: 0.22, green: 0.43, blue: 0.67), // Blue Tint
                    Color(red: 0.43, green: 0.28, blue: 0.72), // Purple Tint
                    Color(red: 0.33, green: 0.49, blue: 0.24)  // Green Tint
                ]
                let mappedColor = designColors[abs(member.id.hashValue) % designColors.count]
                
                return GroupMember(
                    name: isMe ? "You" : member.name,
                    subtitle: isMe ? "Admin" : "@\(member.username)",
                    initials: cleanInitials.isEmpty ? "?" : String(cleanInitials).uppercased(),
                    color: mappedColor,
                    isOnline: false // Set base value (presence state not exposed by endpoint payload)
                )
            }
            
            isLoadingMembers = false
        } catch {
            isLoadingMembers = false
            print("❌ Failed processing room member entities: \(error)")
        }
    }
    
    private func inviteUser() async {
        let trimmedPhone = inviteeUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPhone.isEmpty else { return }

        guard let url = URL(string: "https://district.monu14.me/api/v1/rooms/\(room.id)/invite") else { return }
        
        isInviting = true
        let payload = InvitePayload(invitee_username: trimmedPhone, inviter_username: storedUsername)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            isInviting = false
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 201 {
                    inviteMessage = "User successfully invited!"
                    // Auto-refresh layout to reflect updates instantly
                    await fetchRoomMembers()
                } else if httpResponse.statusCode == 404 {
                    inviteMessage = "User or Room not found."
                } else if httpResponse.statusCode == 400 {
                    inviteMessage = "Bad Request. The user might already be in the group."
                } else {
                    inviteMessage = "Failed to invite user (Error Code: \(httpResponse.statusCode))."
                }
            }
            showStatusAlert = true
            
        } catch {
            isInviting = false
            inviteMessage = "Network error occurred. Please try again."
            showStatusAlert = true
        }
    }
}

// MARK: - Models
struct InvitePayload: Codable {
    let invitee_username: String
    let inviter_username: String
}

struct APIMember: Codable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let mobile_number: String
    let created_at: String
    let updated_at: String
}

struct GroupMember: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let initials: String
    let color: Color
    let isOnline: Bool
}

struct MemberRow: View {
    let member: GroupMember

    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(member.color)
                    .frame(width: 48, height: 48)

                Text(member.initials)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                if member.isOnline {
                    Circle()
                        .fill(Color(red: 0.2, green: 0.8, blue: 0.4))
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color(red: 0.12, green: 0.12, blue: 0.13), lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Text(member.subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
