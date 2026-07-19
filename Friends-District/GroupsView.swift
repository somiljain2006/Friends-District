//  GroupsView.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import SwiftUI

// Adding @MainActor here ensures all UI state changes safely run on the main thread
@MainActor
struct GroupsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Grab the stored phone from ProfileSetupView
    @AppStorage("profileUsername") private var storedUsername = ""
    
    @State private var rooms: [Room] = []
    @State private var pendingInvites: [Room] = []
    
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // MARK: - New Create Group States
    @State private var showCreateAlert = false
    @State private var newGroupName = ""
    @State private var isCreating = false
    
    // MARK: - Navigation State
    @State private var selectedRoom: Room? // Track the active chat room selection
    
    var body: some View {
        ZStack {
            Color(red: 0.008, green: 0.008, blue: 0.012).ignoresSafeArea()
            
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
                        HStack(spacing: 8) {
                            Text("Your Groups")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .tracking(-0.3)
                            
                            Text("\(rooms.count)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                            
                            Spacer()
                        }
                        .padding(.top, 8)
                        
                        if rooms.isEmpty {
                            VStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.04))
                                        .frame(width: 72, height: 72)
                                    Image(systemName: "person.3")
                                        .font(.system(size: 28))
                                        .foregroundStyle(Color(red: 0.37, green: 0.42, blue: 0.82).opacity(0.6))
                                }
                                Text("No groups yet")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.6))
                                Text("Create a group to start chatting")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(rooms) { room in
                                    Button {
                                        // Set the room selection to trigger navigation
                                        selectedRoom = room
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
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .padding(.top, 8)
                        }
                        
                        // MARK: - Pending Invites Section
                        HStack(spacing: 8) {
                            Text("Invites")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .tracking(-0.3)
                            
                            if !pendingInvites.isEmpty {
                                Text("\(pendingInvites.count)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(red: 0.37, green: 0.42, blue: 0.82))
                                    .clipShape(Capsule())
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 24)
                        
                        if pendingInvites.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.green.opacity(0.6))
                                Text("All caught up — no pending invites")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.35))
                            }
                            .padding(.top, 8)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(pendingInvites) { room in
                                    PendingInviteRow(
                                        room: room,
                                        onAccept: {
                                            Task {
                                                await acceptInvite(for: room)
                                            }
                                        },
                                        onReject: {
                                            Task {
                                                await rejectInvite(for: room)
                                            }
                                        }
                                    )
                                    
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
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
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
            
            // Show a loading spinner over the whole screen while creating
            if isCreating {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView("Creating...")
                    .tint(.white)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
            }
        }
        .navigationBarBackButtonHidden(true)
        // Explicitly binds the selection state to present the chat room
        .navigationDestination(item: $selectedRoom) { room in
            GroupChatView(room: room)
        }
        .task {
            await fetchAllData()
        }
        // MARK: - Create Group Alert
        .alert("Create New Group", isPresented: $showCreateAlert) {
            TextField("Group Name", text: $newGroupName)
            
            Button("Cancel", role: .cancel) {
                newGroupName = ""
            }
            
            Button("Create") {
                let trimmedName = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else { return }
                
                Task {
                    await createRoom(name: trimmedName)
                    newGroupName = ""
                }
            }
        } message: {
            Text("Enter a name for your new group.")
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
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.37, green: 0.42, blue: 0.82), Color(red: 0.49, green: 0.23, blue: 0.93)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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
        components.queryItems = [URLQueryItem(name: "username", value: storedUsername)]
        guard let url = components.url else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.errorMessage = "Failed to load groups."
                return
            }
            let decodedRooms = try JSONDecoder().decode([Room].self, from: data)
            self.rooms = decodedRooms
        } catch {
            print("Failed to fetch rooms: \(error)")
            self.errorMessage = "Network error occurred."
        }
    }
    
    private func fetchPendingInvites() async {
        guard var components = URLComponents(string: "https://district.monu14.me/api/v1/rooms/invites") else { return }
        components.queryItems = [URLQueryItem(name: "username", value: storedUsername)]
        guard let url = components.url else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return
            }
            let decodedInvites = try JSONDecoder().decode([Room].self, from: data)
            self.pendingInvites = decodedInvites
        } catch {
            print("Failed to fetch pending invites: \(error)")
        }
    }
    
    /// Hitting the member parameters details to process joining validation rules
    private func acceptInvite(for room: Room) async {
        guard let url = URL(string: "https://district.monu14.me/api/v1/rooms/\(room.id)/accept") else { return }
        
        let payload = ["username": storedUsername]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Successfully accepted invite for room \(room.id)")
                await fetchAllData()
            } else {
                print("⚠️ Failed to accept invite. Status Code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            }
        } catch {
            print("❌ Error accepting invite: \(error)")
        }
    }
    
    private func rejectInvite(for room: Room) async {
        guard let url = URL(string: "https://district.monu14.me/api/v1/rooms/\(room.id)/reject") else { return }
        
        let payload = ["username": storedUsername]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Successfully rejected invite for room \(room.id)")
                await fetchAllData()
            } else {
                print("⚠️ Failed to reject invite. Status Code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            }
        } catch {
            print("❌ Error rejecting invite: \(error)")
        }
    }
    
    private func createRoom(name: String) async {
        guard let url = URL(string: "https://district.monu14.me/api/v1/rooms") else { return }
        
        isCreating = true
        let payload = CreateRoomPayload(name: name, username: storedUsername)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                self.errorMessage = "Failed to create group."
                self.isCreating = false
                return
            }
            
            self.isCreating = false
            await fetchAllData()
            
        } catch {
            print("Failed to create room: \(error)")
            self.errorMessage = "Network error occurred while creating."
            self.isCreating = false
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
    let username: String
}

// MARK: - Subviews
struct GroupRow: View {
    let room: Room
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [room.themeColor, room.themeColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Text(room.initial)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                Circle()
                    .fill(Color(red: 0.2, green: 0.8, blue: 0.4))
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.008, green: 0.008, blue: 0.012), lineWidth: 2.5)
                    )
                    .offset(x: 2, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .tracking(-0.2)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.5))
                        .frame(width: 6, height: 6)
                    Text("Active now")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0.37, green: 0.42, blue: 0.82).opacity(0.6))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct PendingInviteRow: View {
    let room: Room
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(room.themeColor.opacity(0.6))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
                
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
                    .foregroundStyle(Color(red: 0.37, green: 0.42, blue: 0.82))
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    onReject()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    onAccept()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Color(red: 0.37, green: 0.42, blue: 0.82))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
    }
}

#Preview {
    NavigationStack {
        GroupsView()
    }
}
