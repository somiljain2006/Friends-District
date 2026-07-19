import SwiftUI

struct BookingResponse: Codable, Identifiable {
    let id: Int
    let external_event_id: String
    let external_event_type: String
    let quantity: Int
    let total_price: Double
    let status: String
    let start_time: String?
    let end_time: String?
    let user: UserResponse?
    let booked_for: UserResponse?
}

struct UserResponse: Codable {
    let id: Int
    let name: String
    let username: String
}

struct BookingsListView: View {
    @State private var bookings: [BookingResponse] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    @AppStorage("username") private var storedUsername: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    CircleIconButton(systemName: "arrow.left")
                }
                
                Spacer()
                
                Text("My Bookings")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                CircleIconButton(systemName: "arrow.left")
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            if isLoading {
                Spacer()
                ProgressView().tint(.white).scaleEffect(1.5)
                Spacer()
            } else if let errorMessage = errorMessage {
                Spacer()
                Text(errorMessage).foregroundStyle(.red.opacity(0.8))
                Spacer()
            } else if bookings.isEmpty {
                Spacer()
                Text("You haven't booked anything yet.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(bookings) { booking in
                            BookingCard(booking: booking, currentUsername: storedUsername)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
            }
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.09).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .task {
            await fetchBookings()
        }
    }
    
    private func fetchBookings() async {
        guard let encodedUsername = storedUsername.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://district.monu14.me/api/v1/bookings?username=\(encodedUsername)") else { return }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                await MainActor.run {
                    self.errorMessage = "Failed to load bookings."
                    self.isLoading = false
                }
                return
            }
            
            let decodedBookings = try JSONDecoder().decode([BookingResponse].self, from: data)
            
            await MainActor.run {
                self.bookings = decodedBookings
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Network error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

struct BookingCard: View {
    let booking: BookingResponse
    let currentUsername: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(booking.external_event_type.capitalized)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(red: 0.52, green: 0.22, blue: 0.95))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.52, green: 0.22, blue: 0.95).opacity(0.15))
                    .clipShape(Capsule())
                
                Spacer()
                
                Text(booking.status)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.green)
            }
            
            Text("Event ID: \(booking.external_event_id)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            
            if let startTime = booking.start_time, let endTime = booking.end_time {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .foregroundStyle(.white.opacity(0.6))
                    Text("\(startTime) - \(endTime)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            Divider().overlay(Color.white.opacity(0.1))
            
            HStack {
                if let bookedFor = booking.booked_for, bookedFor.username != currentUsername {
                    Text("Booked for: \(bookedFor.name)")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                } else if let user = booking.user, user.username != currentUsername {
                    Text("Booked by: \(user.name)")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    Text("Booked for yourself")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text("Qty: \(booking.quantity)")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
