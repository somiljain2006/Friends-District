//
//  EventDetailView.swift
//  Friends-District
//
//  Created by AI on 18/07/26.
//

import SwiftUI

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("profilePhone") private var storedPhone = ""
    
    let item: SpotlightItem
    
    // Bottom Sheet for Sharing
    @State private var showShareSheet = false
    @State private var rooms: [Room] = []
    @State private var isLoadingRooms = false
    @State private var isSharing = false
    @State private var shareSuccess = false
    
    // Booking
    @State private var isBooking = false
    @State private var bookingSuccess = false
    @State private var errorMessage: String?
    
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
                    Button {
                        // Bookmark action
                    } label: {
                        CircleIconButton(systemName: "bookmark")
                    }
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
                            Task { await bookTicket() }
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
        guard let url = URL(string: "https://district.monu14.me/api/v1/rooms?user_phone=\(storedPhone)") else { return }
        
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
            "user_phone": storedPhone,
            "external_event_id": item.id,
            "external_event_type": item.type ?? "event"
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
                self.errorMessage = "Network error while sharing."
                self.isSharing = false
            }
        }
    }
    
    private func bookTicket() async {
        isBooking = true
        errorMessage = nil
        
        guard let url = URL(string: "https://district.monu14.me/api/v1/bookings") else { return }
        
        let payload = [
            "user_phone": storedPhone,
            "event_id": item.id,
            "event_title": item.title,
            "event_date": item.date ?? "",
            "event_location": item.location ?? ""
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    self.bookingSuccess = true
                } else {
                    self.errorMessage = "Failed to book ticket."
                }
                self.isBooking = false
            }
        } catch {
            print("Failed to book ticket: \(error)")
            await MainActor.run {
                self.errorMessage = "Network error while booking."
                self.isBooking = false
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
