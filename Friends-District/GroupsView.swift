//
//  GroupsView.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import SwiftUI

@MainActor
struct GroupsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("profilePhone") private var storedPhone = ""
    
    @State private var rooms: [Room] = []
    @State private var pendingInvites: [Room] = []
    
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // MARK: - Create Group States
    @State private var showCreateAlert = false
    @State private var newGroupName = ""
    @State private var isCreating = false
    
    // MARK: - Navigation State
    @State private var navigatingToRoom: Room?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        topBar
                        
                        if isLoading && rooms.isEmpty && pendingInvites.isEmpty {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.red.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 40)
                        } else {
                            
                            // MARK: - Joined Groups Section
                            Text("\(rooms.count) groups")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white.opacity(0.45))
                                .padding(.top, 8)
                            
                            if rooms.isEmpty {
                                Text("You haven't joined any groups yet.")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(.top, 8)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(rooms) { room in
                                        Button {
                                            navigatingToRoom = room
                                        } label: {
                                            GroupRow(room: room)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        if room.id != rooms.last?.id {
                                            Divider()
                                                .overlay(Color.white.opacity(0.08))
                                                .padding(.leading, 84)
                                        }
                                    }
                                }
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(Color.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                        )
                                )
                                .padding(.top, 8)
                            }
                            
                            // MARK: - Pending Invites Section
                            Text("Pending invites (\(pendingInvites.count))")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white.opacity(0.45))
                                .padding(.top, 24)
                            
                            if pendingInvites.isEmpty {
                                Text("No pending invitations.")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(.top, 8)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(pendingInvites) { room in
                                        PendingInviteRow(room: room)
                                        
                                        if room.id != pendingInvites.last?.id {
                                            Divider()
                                                .overlay(Color.white.opacity(0.08))
                                                .padding(.leading, 84)
                                        }
                                    }
                                }
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(Color.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                        )
                                )
                                .padding(.top, 8)
                            }
                            
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                
                if isCreating {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Creating & Joining...")
                        .tint(.white)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color(red: 0.15, green: 0.15, blue: 0.18))
                        .cornerRadius(12)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(item: $navigatingToRoom) { room in
                GroupChatView(room: room)
            }
            .task {
                await fetchAllData()
            }
            .alert("Create New Group", isPresented: $showCreateAlert) {
                TextField("Group Name", text: $newGroupName)
                
                Button("Cancel", role: .cancel) {
                    newGroupName = ""
                }
                
                Button("Create") {
                    let trimmedName = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedName.isEmpty else { return }
                    
                    Task {
                        await createAndJoinRoom(name: trimmedName)
                        newGroupName = ""
                    }
                }
            } message: {
                Text("Enter a name for your new group.")
            }
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
            
            Text("Groups")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            
            Spacer()
            
            Button {
                newGroupName = ""
                showCreateAlert = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                    Text("Create")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 40)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(red: 0.52, green: 0.22, blue: 0.95))
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - API Calls
    
    private func fetchAllData() async {
        isLoading = true
        errorMessage = nil
        
        async let fetchRoomsTask: () = fetchRooms()
        async let fetchInvitesTask: () = fetchPendingInvites()
        
        _ = await (fetchRoomsTask, fetchInvitesTask)
        
        isLoading = false
    }
    
    private func fetchRooms() async {
        guard var components = URLComponents(string: "https://district.monu14.me/api/v1/rooms") else { return }
        components.queryItems = [URLQueryItem(name: "user_phone", value: storedPhone)]
        guard let url = components.url else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.errorMessage = "Failed to load groups."
                return
            }
            self.rooms = try JSONDecoder().decode([Room].self, from: data)
        } catch {
            print("Failed to fetch rooms: \(error)")
            self.errorMessage = "Network error occurred."
        }
    }
    
    private func fetchPendingInvites() async {
        guard var components = URLComponents(string: "https://district.monu14.me/api/v1/rooms/invites") else { return }
        components.queryItems = [URLQueryItem(name: "user_phone", value: storedPhone)]
        guard let url = components.url else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            self.pendingInvites = try JSONDecoder().decode([Room].self, from: data)
        } catch {
            print("Failed to fetch pending invites: \(error)")
        }
    }
    
    // MARK: - Modified Create & Join Flow
    private func createAndJoinRoom(name: String) async {
        guard let createUrl = URL(string: "https://district.monu14.me/api/v1/rooms") else { return }
        
        isCreating = true
        let payload = CreateRoomPayload(name: name) // Backend docs for create doesn't strictly list user_phone inside body for room creation, but add if needed
        
        var request = URLRequest(url: createUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                self.errorMessage = "Failed to create group."
                self.isCreating = false
                return
            }
            
            // Decode the newly created room to get its ID
            let newRoom = try JSONDecoder().decode(Room.self, from: data)
            
            // Use ID to join the room
            await joinRoom(roomId: newRoom.id)
            
            // Refresh state & Navigate
            await fetchAllData()
            self.isCreating = false
            self.navigatingToRoom = newRoom
            
        } catch {
            print("Failed to create room: \(error)")
            self.errorMessage = "Network error occurred while creating."
            self.isCreating = false
        }
    }
    
    private func joinRoom(roomId: Int) async {
        guard let url = URL(string: "https://district.monu14.me/api/v1/rooms/\(roomId)/join") else { return }
        
        let joinPayload = JoinRoomPayload(user_phone: storedPhone)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(joinPayload)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                print("Failed to join room, status code: \(httpResponse.statusCode)")
            }
        } catch {
            print("Failed to join room: \(error)")
        }
    }
}

// MARK: - Models

struct Room: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let created_at: String
    let updated_at: String
    
    var initial: String {
        String(name.prefix(1)).uppercased()
    }
    
    var themeColor: Color {
        let colors: [Color] = [
            Color(red: 0.42, green: 0.20, blue: 0.83), // Purple
            Color(red: 0.05, green: 0.48, blue: 0.36), // Green
            Color(red: 0.75, green: 0.11, blue: 0.38), // Red/Pink
            Color(red: 0.14, green: 0.33, blue: 0.87)  // Blue
        ]
        return colors[id % colors.count]
    }
}

struct CreateRoomPayload: Codable {
    let name: String
}

struct JoinRoomPayload: Codable {
    let user_phone: String
}

// MARK: - Row Subviews
// (GroupRow and PendingInviteRow remain unchanged from your original code)
struct GroupRow: View {
    let room: Room
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(room.themeColor)
                    .frame(width: 64, height: 64)
                Text(room.initial)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(room.name)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                Text("Active recently")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }
}

struct PendingInviteRow: View {
    let room: Room
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(room.themeColor.opacity(0.6))
                    .frame(width: 64, height: 64)
                    .overlay(Circle().stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [5])))
                Text(room.initial)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(room.name)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                Text("Invitation pending")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color(red: 0.52, green: 0.22, blue: 0.95))
            }
            Spacer()
            Button {
                print("Accepting invite for room: \(room.id)")
            } label: {
                Text("View")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
    }
}

#Preview {
    GroupsView()
}
