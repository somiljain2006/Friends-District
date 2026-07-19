import SwiftUI

struct DailySchedulesView: View {
    @AppStorage("profileUsername") private var storedUsername = ""
    @Environment(\.dismiss) private var dismiss
    
    @State private var bookings: [BookingModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.12, blue: 0.14).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Custom Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    Text("Daily Schedules")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.leading, 12)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                if isLoading {
                    Spacer()
                    ProgressView().tint(.white).frame(maxWidth: .infinity)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    Text(error).foregroundStyle(.red).frame(maxWidth: .infinity)
                    Spacer()
                } else if bookings.isEmpty {
                    Spacer()
                    Text("No upcoming schedules.")
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(bookings) { booking in
                                ScheduleCard(booking: booking, currentUsername: storedUsername)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
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

struct ScheduleCard: View {
    let booking: BookingModel
    let currentUsername: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(booking.external_event_type.capitalized)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.15))
                    .clipShape(Capsule())
                
                Spacer()
                
                if let status = booking.status {
                    Text(status)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(status == "CONFIRMED" ? .green : .orange)
                }
            }
            
            Text("Event ID: \(booking.external_event_id)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
            
            HStack(spacing: 16) {
                if let date = booking.booking_date {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.white.opacity(0.6))
                        Text(date)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                
                if let start = booking.start_time, let end = booking.end_time {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .foregroundStyle(.white.opacity(0.6))
                        Text("\(start) - \(end)")
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }
            .font(.system(size: 14, weight: .medium))
            
            Divider().background(Color.white.opacity(0.1)).padding(.vertical, 4)
            
            HStack {
                Text(isForMe ? "For You" : "For Friend")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                
                Spacer()
                
                Text("Qty: \(booking.quantity)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var isForMe: Bool {
        if let bookedFor = booking.booked_for {
            return bookedFor.username == currentUsername
        }
        return booking.user.username == currentUsername
    }
}

// Ensure BookingModel matches the API response
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
