import SwiftUI

struct CategoryListView: View {
    let category: Category
    @State private var items: [SpotlightItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    CircleIconButton(systemName: "arrow.left")
                }
                
                Spacer()
                
                Text(category.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Placeholder to balance the back button
                CircleIconButton(systemName: "arrow.left")
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            if isLoading {
                Spacer()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                Spacer()
            } else if let errorMessage = errorMessage {
                Spacer()
                Text(errorMessage)
                    .foregroundStyle(.red.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Spacer()
            } else if items.isEmpty {
                Spacer()
                Text("No \(category.title.lowercased()) found.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        ForEach(items) { item in
                            NavigationLink(destination: EventDetailView(item: item)) {
                                CategoryListItemCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.008, green: 0.008, blue: 0.012),
                    Color(red: 0.02, green: 0.02, blue: 0.024)
                ],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .task {
            await fetchItems()
        }
    }
    
    private func fetchItems() async {
        guard let url = URL(string: "https://district.monu14.me/api/v1/events?type=\(category.apiType)") else { return }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                await MainActor.run {
                    self.errorMessage = "Failed to load events. Please try again."
                    self.isLoading = false
                }
                return
            }
            
            let decodedItems = try JSONDecoder().decode([SpotlightItem].self, from: data)
            
            await MainActor.run {
                self.items = decodedItems
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

struct CategoryListItemCard: View {
    let item: SpotlightItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Image
            AsyncImage(url: URL(string: item.imageUrl)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .overlay(ProgressView().tint(.white))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.white.opacity(0.3))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            // Details
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                if let type = item.type {
                    Text(type.capitalized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(red: 0.37, green: 0.42, blue: 0.82))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.37, green: 0.42, blue: 0.82).opacity(0.12))
                        .clipShape(Capsule())
                }
                
                Spacer(minLength: 0)
                
                if let date = item.date {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(date)
                            .font(.system(size: 14))
                    }
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                }
            }
            .padding(.vertical, 4)
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}
