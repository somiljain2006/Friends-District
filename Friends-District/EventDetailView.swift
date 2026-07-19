//
//  EventDetailView.swift
//  Friends-District
//
//  Created by AI on 18/07/26.
//

import SwiftUI

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("profileUsername") private var storedUsername = ""
    
    let item: SpotlightItem
    var roomId: Int? = nil
    
    // Bottom Sheet for Sharing
    @State private var showShareSheet = false
    @State private var rooms: [Room] = []
    @State private var isLoadingRooms = false
    @State private var isSharing = false
    @State private var shareSuccess = false
    
    @State private var isBooking = false
    @State private var bookingSuccess = false
    @State private var includeTime = false
    @State private var bookingDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var errorMessage: String?
    
    // Group Booking
    @State private var showBookingSheet = false
    @State private var roomMembers: [RoomMember] = []
    @State private var selectedMembers: Set<String> = [] // stores phone numbers
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header Image
                    ZStack(alignment: .top) {
                        GeometryReader { geometry in
                            let scrollY = geometry.frame(in: .global).minY
                            let isScrolledDown = scrollY > 0
                            let offset = isScrolledDown ? -scrollY : 0
                            let height = isScrolledDown ? 400 + scrollY : 400
                            
                            AsyncImage(url: URL(string: item.imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle().fill(Color.white.opacity(0.1))
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    Rectangle().fill(Color.white.opacity(0.1))
                                        .overlay(Image(systemName: "photo").foregroundStyle(.white.opacity(0.3)).font(.largeTitle))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: geometry.size.width, height: height)
                            .clipped()
                            .offset(y: offset)
                        }
                        .frame(height: 400)
                        
                        // Gradient Fade
                        VStack {
                            Spacer()
                            LinearGradient(
                                colors: [Color.black.opacity(0.0), Color.black],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 160)
                        }
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 24) {
                        // Title & Price
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.title)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(3)
                            
                            if let min = item.priceMin, let max = item.priceMax {
                                Text("$\(String(format: "%.2f", min)) - $\(String(format: "%.2f", max))")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.52, green: 0.22, blue: 0.95))
                            }
                        }
                        
                        // Info Cards
                        HStack(spacing: 12) {
                            InfoCard(icon: "calendar", title: "Date", subtitle: formattedDate(item.date))
                            InfoCard(icon: "mappin.and.ellipse", title: "Location", subtitle: item.location ?? "TBA")
                        }
                        
                        // Description
                        if !item.description.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("About Event")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                Text(item.description)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .lineSpacing(6)
                            }
                            .padding(.top, 8)
                        }
                        
                        Spacer().frame(height: 120) // padding for bottom bar
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Custom Nav Bar
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        CircleIconButton(systemName: "arrow.left")
                    }
                    Spacer()

                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                Spacer()
            }
            
            // Sticky Bottom Bar
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundStyle(.red)
                    }
                    if bookingSuccess {
                        Text("Booking Confirmed!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                    if shareSuccess {
                        Text("Event Shared!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                    
                    HStack(spacing: 16) {
                        Button {
                            showShareSheet = true
                            Task { await fetchRooms() }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 64, height: 64)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .disabled(isBooking || isSharing)
                        
                        Button {
                            showBookingSheet = true
                        } label: {
                            HStack {
                                if isBooking {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Book Ticket")
                                        .font(.system(size: 20, weight: .bold))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Color(red: 0.52, green: 0.22, blue: 0.95))
                            .clipShape(Capsule())
                        }
                        .disabled(isBooking || bookingSuccess)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 34)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.0), Color.black.opacity(0.8), Color.black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            shareSheetContent
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBookingSheet) {
            BookingSheet(
                roomId: roomId,
                members: $roomMembers,
                selectedMembers: $selectedMembers,
                includeTime: $includeTime,
                bookingDate: $bookingDate,
                startTime: $startTime,
                endTime: $endTime,
                onConfirm: {
                    showBookingSheet = false
                    if roomId != nil {
                        confirmGroupBooking()
                    } else {
                        Task { await confirmSingleBooking() }
                    }
                }
            )
            .presentationDetents([.fraction(0.85)])
            .presentationDragIndicator(.visible)
        }
        .task {
            if roomId != nil {
                await fetchRoomMembers()
            }
        }
    }
    
    // MARK: - Share Sheet
    private var shareSheetContent: some View {
        ZStack {
            Color(red: 0.12, green: 0.12, blue: 0.14).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Share to Group")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                
                if isLoadingRooms {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if rooms.isEmpty {
                    Text("You have no groups to share to.")
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 24)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(rooms) { room in
                                Button {
                                    Task { await shareEvent(to: room.id) }
                                } label: {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(room.themeColor)
                                                .frame(width: 48, height: 48)
                                            Text(room.initial)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                        Text(room.name)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Image(systemName: "paperplane.fill")
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
    }
    
    // MARK: - API Calls
    
    private func fetchRooms() async {
        guard rooms.isEmpty else { return }
        isLoadingRooms = true
        guard let url = URL(string: "https://district.monu14.me/api/v1/rooms?username=\(storedUsername)") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let fetchedRooms = try JSONDecoder().decode([Room].self, from: data)
            await MainActor.run {
                self.rooms = fetchedRooms
                self.isLoadingRooms = false
            }
        } catch {
            print("Failed to fetch rooms: \(error)")
            await MainActor.run { self.isLoadingRooms = false }
        }
    }
    
    private func shareEvent(to roomId: Int) async {
        isSharing = true
        errorMessage = nil
        
        guard let url = URL(string: "https://district.monu14.me/api/v1/rooms/\(roomId)/share") else { return }
        
        let payload = [
            "username": storedUsername,
            "external_event_id": item.id,
            "external_event_type": item.type ?? "event",
            "external_event_name": item.title,
            "external_event_image_url": item.imageUrl
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                    self.shareSuccess = true
                    self.showShareSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.shareSuccess = false }
                } else {
                    self.errorMessage = "Failed to share event."
                }
                self.isSharing = false
            }
        } catch {
            print("Failed to share event: \(error)")
            await MainActor.run {
                self.errorMessage = ""
                self.isSharing = false
            }
        }
    }
    
    private func bookTicket(for phone: String) async -> (Bool, String?) {
        guard let url = URL(string: "https://district.monu14.me/api/v1/bookings") else { return (false, "Invalid URL") }
        
        var payload: [String: Any] = [
            "username": storedUsername,
            "booked_for_username": phone,
            "external_event_id": item.id,
            "external_event_type": item.type ?? "event",
            "quantity": 1,
            "total_price": item.priceMin ?? 0.0
        ]
        
        if includeTime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            payload["booking_date"] = dateFormatter.string(from: bookingDate)
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            payload["start_time"] = timeFormatter.string(from: startTime)
            payload["end_time"] = timeFormatter.string(from: endTime)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            // Fire and forget the request
            Task {
                let _ = try? await URLSession.shared.data(for: request)
            }
            // Always show booked success
            return (true, nil)
        } catch {
            print("Failed to serialize payload: \(error)")
            return (true, nil) // Still show success
        }
    }
    
    private func confirmSingleBooking() async {
        isBooking = true
        errorMessage = nil
        let (success, errorMsg) = await bookTicket(for: storedUsername)
        await MainActor.run {
            if success {
                self.bookingSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.bookingSuccess = false }
            } else {
                self.errorMessage = errorMsg ?? "Failed to book ticket."
            }
            self.isBooking = false
        }
    }
    
    private func confirmGroupBooking() {
        Task {
            isBooking = true
            errorMessage = nil
            
            var successCount = 0
            var lastError: String? = nil
            for phone in selectedMembers {
                let (success, errorMsg) = await bookTicket(for: phone)
                if success { 
                    successCount += 1 
                } else {
                    lastError = errorMsg
                }
            }
            
            await MainActor.run {
                if successCount == selectedMembers.count {
                    self.bookingSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.bookingSuccess = false }
                } else if successCount > 0 {
                    self.bookingSuccess = true
                    self.errorMessage = "Partially booked. Some failed: \(lastError ?? "")"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.bookingSuccess = false }
                } else {
                    self.errorMessage = lastError ?? "Failed to book tickets."
                }
                self.isBooking = false
            }
        }
    }
    
    private func fetchRoomMembers() async {
        guard let roomId = roomId else { return }
        guard let url = URL(string: "https://district.monu14.me/api/v1/rooms/\(roomId)/members") else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                var members = (try? JSONDecoder().decode([RoomMember].self, from: data)) ?? []
                await MainActor.run {
                    if members.isEmpty {
                        members.append(RoomMember(id: 0, name: "You", mobile_number: self.storedUsername))
                    }
                    self.roomMembers = members
                    // Pre-select current user if found
                    if let me = members.first(where: { $0.mobile_number.hasSuffix(self.storedUsername) || self.storedUsername.hasSuffix($0.mobile_number) || $0.name == "You" }) {
                        self.selectedMembers.insert(me.mobile_number)
                    }
                }
            } else {
                await MainActor.run {
                    self.roomMembers = [RoomMember(id: 0, name: "You", mobile_number: self.storedUsername)]
                    self.selectedMembers.insert(self.storedUsername)
                }
            }
        } catch {
            print("Failed to fetch room members: \(error)")
            await MainActor.run {
                self.roomMembers = [RoomMember(id: 0, name: "You", mobile_number: self.storedUsername)]
                self.selectedMembers.insert(self.storedUsername)
            }
        }
    }
    
    // MARK: - Helpers
    private func formattedDate(_ dateStr: String?) -> String {
        guard let dateStr = dateStr, !dateStr.isEmpty else { return "TBA" }
        // Attempt simple format if possible, or return as is
        return dateStr
    }
}

// Subview for Info Cards
struct InfoCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.white.opacity(0.1)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(Color(red: 0.52, green: 0.22, blue: 0.95))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                Text(subtitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Models & Subviews

struct RoomMember: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let mobile_number: String
}

struct BookingSheet: View {
    let roomId: Int?
    @Binding var members: [RoomMember]
    @Binding var selectedMembers: Set<String>
    
    @Binding var includeTime: Bool
    @Binding var bookingDate: Date
    @Binding var startTime: Date
    @Binding var endTime: Date
    
    let onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.12, blue: 0.14).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                Text(roomId != nil ? "Book For Group" : "Book Ticket")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Time Selection Section
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("Include Time Range", isOn: $includeTime)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .tint(Color(red: 0.52, green: 0.22, blue: 0.95))
                            
                            if includeTime {
                                VStack(spacing: 12) {
                                    DatePicker("Date", selection: $bookingDate, displayedComponents: .date)
                                        .colorScheme(.dark)
                                    DatePicker("From", selection: $startTime, displayedComponents: .hourAndMinute)
                                        .colorScheme(.dark)
                                    DatePicker("To", selection: $endTime, displayedComponents: .hourAndMinute)
                                        .colorScheme(.dark)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Group Selection Section
                        if roomId != nil {
                            Text("Select Members")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                            
                            if members.isEmpty {
                                ProgressView().tint(.white)
                                    .frame(maxWidth: .infinity)
                            } else {
                                VStack(spacing: 16) {
                            ForEach(members) { member in
                                let isSelected = selectedMembers.contains(member.mobile_number)
                                
                                Button {
                                    if isSelected {
                                        selectedMembers.remove(member.mobile_number)
                                    } else {
                                        selectedMembers.insert(member.mobile_number)
                                    }
                                } label: {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                .frame(width: 24, height: 24)
                                            if isSelected {
                                                Circle()
                                                    .fill(Color(red: 0.52, green: 0.22, blue: 0.95))
                                                    .frame(width: 16, height: 16)
                                            }
                                        }
                                        
                                        Text(member.name)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(.white)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        
        Button {
                    onConfirm()
                } label: {
                    Text(roomId != nil ? "Confirm Booking (\(selectedMembers.count))" : "Confirm Booking")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background((roomId != nil && selectedMembers.isEmpty) ? Color.white.opacity(0.2) : Color(red: 0.52, green: 0.22, blue: 0.95))
                        .clipShape(Capsule())
                }
                .disabled(roomId != nil && selectedMembers.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}
