//
//  ContentView.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showGroups = false
    @State private var isAddressExpanded = false
    
    // Changed UUID to String to match your API response ID
    @State private var currentSpotlightID: String?
    @State private var showProfile = false
    
    // New state variables for API data
    @State private var spotlightItems: [SpotlightItem] = []
    @State private var isLoadingSpotlight = false
    
    @State private var movies: [SpotlightItem] = []
    @State private var concerts: [SpotlightItem] = []
    @State private var dining: [SpotlightItem] = []
    @State private var isLoadingSections = false
    
    private let categories: [Category] = [
        .init(title: "Dining", icon: "dining"),
        .init(title: "Movies", icon: "movies"),
        .init(title: "Events", icon: "events")
    ]
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                            .padding(.horizontal, 18)
                        
                        searchBar
                            .padding(.horizontal, 18)
                        
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            ForEach(categories) { category in
                                CategoryCard(category: category)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 4)
                        
                        Text("In the spotlight")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.top, 6)
                        
                        spotlightSection
                        
                        if isLoadingSections {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 40)
                        } else {
                            if !movies.isEmpty { eventSection(title: "Movies", items: movies) }
                            if !concerts.isEmpty { eventSection(title: "Concerts", items: concerts) }
                            if !dining.isEmpty { eventSection(title: "Dining", items: dining) }
                        }
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
            }
            .navigationDestination(isPresented: $showProfile) {
                ProfileView()
            }
            .navigationDestination(isPresented: $showGroups) {
                GroupsView()
            }
        }
        // Switched from .onAppear to .task for modern async/await networking
        .task {
            locationManager.requestLocation()
            await fetchSpotlightEvents()
            await fetchAllSections()
        }
    }
    
    private func fetchSpotlightEvents() async {
        guard let url = URL(string: "https://district.monu14.me/api/v1/events/spotlight") else { return }
        
        isLoadingSpotlight = true
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedItems = try JSONDecoder().decode([SpotlightItem].self, from: data)
            
            await MainActor.run {
                self.spotlightItems = decodedItems
                if self.currentSpotlightID == nil {
                    self.currentSpotlightID = decodedItems.first?.id
                }
                self.isLoadingSpotlight = false
            }
        } catch {
            print("Failed to fetch or decode spotlight events: \(error)")
            await MainActor.run {
                self.isLoadingSpotlight = false
            }
        }
    }
    
    private func fetchAllSections() async {
        isLoadingSections = true
        async let fetchedMovies = fetchSectionEvents(type: "movie")
        async let fetchedConcerts = fetchSectionEvents(type: "concert")
        async let fetchedDining = fetchSectionEvents(type: "dining")
        
        let (m, c, d) = await (fetchedMovies, fetchedConcerts, fetchedDining)
        await MainActor.run {
            self.movies = m
            self.concerts = c
            self.dining = d
            self.isLoadingSections = false
        }
    }
    
    private func fetchSectionEvents(type: String) async -> [SpotlightItem] {
        guard let url = URL(string: "https://district.monu14.me/api/v1/events?type=\(type)") else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode([SpotlightItem].self, from: data)
        } catch {
            print("Failed to fetch \(type) events: \(error)")
            return []
        }
    }
    
    // MARK: - View Components
    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.09, blue: 0.22),
                Color(red: 0.08, green: 0.08, blue: 0.12),
                Color(red: 0.06, green: 0.06, blue: 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RadialGradient(
                colors: [
                    Color.purple.opacity(0.28),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
        )
    }
    
    private var header: some View {
        HStack(alignment: .top) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.top, -4)
                
                VStack(alignment: .leading, spacing: 3) {
                    Button {
                        withAnimation {
                            isAddressExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(locationManager.area)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.75))
                                .rotationEffect(.degrees(isAddressExpanded ? 180 : 0))
                                .padding(.top, 2)
                        }
                    }
                    
                    Text(locationManager.address)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(isAddressExpanded ? nil : 1)
                }
            }
            
            Spacer()
            
            HStack(spacing: 14) {
                Button {
                    showGroups = true
                } label: {
                    ImageCircleButton(imageName: "persons")
                }
                .buttonStyle(.plain)

                CircleIconButton(systemName: "bookmark")

                Button {
                    showProfile = true
                } label: {
                    ProfileAvatar()
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(.top, 18)
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))
            
            Text("Search for 'Shakira'")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
            
            Spacer()
        }
        .frame(height: 64)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.top, 8)
    }
    
    private var spotlightSection: some View {
        VStack(spacing: 20) {
            if isLoadingSpotlight && spotlightItems.isEmpty {
                ProgressView()
                    .tint(.white)
                    .frame(height: 420)
            } else if spotlightItems.isEmpty {
                Text("No spotlight events right now.")
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(height: 420)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(spotlightItems) { item in
                            SpotlightCard(item: item)
                                .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 16)
                                .id(item.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentSpotlightID)
                .safeAreaPadding(.horizontal, 32)
                
                HStack(spacing: 8) {
                    ForEach(spotlightItems) { item in
                        if currentSpotlightID == item.id {
                            Capsule()
                                .fill(Color.white)
                                .frame(width: 24, height: 6)
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                .padding(.top, 4)
                .animation(.snappy, value: currentSpotlightID)
            }
        }
    }
    
    private func eventSection(title: String, items: [SpotlightItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        SectionCard(item: item)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
        .padding(.top, 12)
    }
}

// MARK: - Models
struct Category: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
}

struct SpotlightItem: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let description: String
    let imageUrl: String
    
    let date: String?
    let location: String?
    let type: String?
    let url: String?
    let priceMin: Double?
    let priceMax: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, location, date, type, url
        case imageUrl = "image_url"
        case priceMin = "price_min"
        case priceMax = "price_max"
    }
}

// MARK: - Subviews
struct CategoryCard: View {
    let category: Category
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                
                Image(category.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82, height: 82)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            
            Text(category.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.bottom, 2)
        }
    }
}

struct SpotlightCard: View {
    let item: SpotlightItem
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            ZStack(alignment: .top) {
                
                // 1. Establish a rigid, unchanging bounding box
                Color.white.opacity(0.05)
                    .frame(maxWidth: .infinity)
                    .frame(height: 420)
                    // 2. Place AsyncImage in an overlay so it cannot stretch the container
                    .overlay(
                        AsyncImage(url: URL(string: item.imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .tint(.white)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill() // Fills the overlay without expanding it
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white.opacity(0.3))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    )
                    // 3. Clip the entire container (which neatly crops any scaledToFill overflow)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
                
                // Badges overlay
                HStack(alignment: .top) {
                    Spacer()
                    
                    CircleIconButton(systemName: "bookmark")
                        .frame(width: 40, height: 40)
                }
                .padding(16)
            }
            
            // Text Content Below Image
            VStack(spacing: 6) {
                Text(item.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                Text(item.description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
        }
    }
}

struct SectionCard: View {
    let item: SpotlightItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .top) {
                Color.white.opacity(0.05)
                    .frame(width: 240, height: 160)
                    .overlay(
                        AsyncImage(url: URL(string: item.imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView().tint(.white)
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .failure:
                                Image(systemName: "photo").foregroundStyle(.white.opacity(0.3))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(item.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
            }
            .frame(width: 240, alignment: .leading)
        }
    }
}

struct CircleIconButton: View {
    let systemName: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 42, height: 42)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
            
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

struct ProfileAvatar: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.82))
                .frame(width: 46, height: 46)
            
            Circle()
                .fill(Color(red: 0.80, green: 0.80, blue: 0.88))
                .frame(width: 18, height: 18)
                .offset(y: -6)
            
            Capsule()
                .fill(Color(red: 0.82, green: 0.82, blue: 0.90))
                .frame(width: 28, height: 12)
                .offset(y: 10)
        }
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
    }
}

struct ImageCircleButton: View {
    let imageName: String

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 42, height: 42)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        }
    }
}

#Preview {
    ContentView()
}
