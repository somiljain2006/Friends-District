import SwiftUI

struct DailySchedulesView: View {
    @AppStorage("profileUsername") private var storedUsername = ""
    @Environment(\.dismiss) private var dismiss
    
    @State private var bookings: [BookingModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    private let bgDeep = Color(red: 0.05, green: 0.05, blue: 0.06)
    private let bgBase = Color(red: 0.02, green: 0.02, blue: 0.024)
    private let surface = Color.white.opacity(0.05)
    private let accent = Color(red: 0.37, green: 0.42, blue: 0.82)
    private let accentGlow = Color(red: 0.37, green: 0.42, blue: 0.82).opacity(0.2)
    
    var body: some View {
        ZStack {
            bgDeep
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 16) {
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.07))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Schedules")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                            .tracking(-0.5)
                        
                        Text("\(bookings.count) upcoming")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.54, green: 0.56, blue: 0.6))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 28)
                
                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(accent)
                            .scaleEffect(1.2)
                        Text("Loading schedules...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.54, green: 0.56, blue: 0.6))
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundStyle(.red.opacity(0.7))
                        Text(error)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else if bookings.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundStyle(accent.opacity(0.5))
                        Text("No upcoming schedules")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("Book an event to see it here.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.54, green: 0.56, blue: 0.6))
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(Array(bookings.enumerated()), id: \.element.id) { index, booking in
                                HStack(alignment: .top, spacing: 16) {
                                    VStack(spacing: 0) {
                                        Circle()
                                            .fill(accentColorFor(booking.external_event_type))
                                            .frame(width: 10, height: 10)
                                            .shadow(color: accentColorFor(booking.external_event_type).opacity(0.5), radius: 4)
                                        
                                        if index < bookings.count - 1 {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.08))
                                                .frame(width: 1.5)
                                                .frame(maxHeight: .infinity)
                                        }
                                    }
                                    .frame(width: 10)
                                    .padding(.top, 6)
                                    
                                    PremiumScheduleCard(
                                        booking: booking,
                                        currentUsername: storedUsername,
                                        accentColor: accentColorFor(booking.external_event_type)
                                    )
                                    .padding(.bottom, 16)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .task {
            await fetchBookings()
        }
    }
    
    private func accentColorFor(_ type: String) -> Color {
        switch type.lowercased() {
        case "dining":
            return Color(red: 0.92, green: 0.35, blue: 0.05)
        case "movie":
            return Color(red: 0.15, green: 0.39, blue: 0.92)
        case "concert":
            return Color(red: 0.49, green: 0.23, blue: 0.93)
        default:
            return accent
        }
    }
    
    private func fetchBookings() async {
        guard let url = URL(string: "https://district.monu14.me/api/v1/bookings?username=\(storedUsername)") else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                let decoded = try JSONDecoder().decode([BookingModel].self, from: data)
                await MainActor.run {
                    self.bookings = decoded.sorted { ($0.booking_date ?? "") < ($1.booking_date ?? "") }
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Failed to load schedules."
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

struct PremiumScheduleCard: View {
    let booking: BookingModel
    let currentUsername: String
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 8, height: 8)
                    Text(booking.external_event_type.capitalized)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(accentColor)
                        .textCase(.uppercase)
                        .tracking(0.8)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(accentColor.opacity(0.12))
                .clipShape(Capsule())
                
                Spacer()
                
                if let status = booking.status {
                    Text(status)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(status == "CONFIRMED" ? Color(red: 0.2, green: 0.83, blue: 0.6) : .orange)
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            (status == "CONFIRMED" ? Color(red: 0.2, green: 0.83, blue: 0.6) : .orange).opacity(0.1)
                        )
                        .clipShape(Capsule())
                }
            }
            
            Text("Event: \(booking.external_event_id)")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(red: 0.93, green: 0.93, blue: 0.94))
                .lineLimit(1)
                .tracking(-0.3)
            
            HStack(spacing: 20) {
                if let date = booking.booking_date {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(accentColor.opacity(0.8))
                        Text(date)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.93, green: 0.93, blue: 0.94).opacity(0.85))
                    }
                }
                
                if let start = booking.start_time, let end = booking.end_time {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(accentColor.opacity(0.8))
                        Text("\(start) – \(end)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(red: 0.93, green: 0.93, blue: 0.94).opacity(0.85))
                    }
                }
            }
            
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.vertical, 2)
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: isForMe ? "person.fill" : "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.54, green: 0.56, blue: 0.6))
                    Text(isForMe ? "For You" : "For Friend")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(red: 0.54, green: 0.56, blue: 0.6))
                }
                
                Spacer()
                
                Text("Qty: \(booking.quantity)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [accentColor.opacity(0.25), Color.white.opacity(0.06), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .overlay(
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: 3)
                    .padding(.vertical, 12)
                Spacer()
            }
        )
    }
    
    private var isForMe: Bool {
        if let bookedFor = booking.booked_for {
            return bookedFor.username == currentUsername
        }
        return booking.user.username == currentUsername
    }
}

struct BookingModel: Codable, Identifiable {
    let id: Int
    let user_id: Int
    let booked_for_id: Int?
    let external_event_id: String
    let external_event_type: String
    let quantity: Int
    let total_price: Double
    let status: String?
    let start_time: String?
    let end_time: String?
    let booking_date: String?
    let created_at: String
    
    let user: UserModel
    let booked_for: UserModel?
}

struct UserModel: Codable {
    let id: Int
    let name: String
    let username: String
    let mobile_number: String
}
