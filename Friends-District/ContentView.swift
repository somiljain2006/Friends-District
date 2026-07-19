//  ContentView.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showGroups = false
    @State private var showSchedules = false
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
        .init(title: "Dining", icon: "dining", apiType: "dining"),
        .init(title: "Movies", icon: "movies", apiType: "movie"),
        .init(title: "Events", icon: "events", apiType: "concert")
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
                    // 1. Wrap the VStack in a ScrollViewReader to enable programmatic scrolling
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading, spacing: 22) {
                            header
                                .padding(.horizontal, 18)
                            
                            searchBar
                                .padding(.horizontal, 18)
                            
                            LazyVGrid(columns: gridColumns, spacing: 16) {
                                ForEach(categories) { category in
                                    // 2. Wrap the CategoryCard in a NavigationLink
                                    NavigationLink(destination: CategoryListView(category: category)) {
                                        CategoryCard(category: category)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 4)
                            
                            HStack {
                                Text("In the spotlight")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)
                                    .tracking(-0.5)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Text("\(spotlightItems.count) events")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color(red: 0.54, green: 0.56, blue: 0.6))
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.top, 6)
                            
                            spotlightSection
                            
                            if isLoadingSections {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.top, 40)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                // Changed "Concerts" to "Events" so it matches your category array above
                                if !movies.isEmpty { eventSection(title: "Movies", items: movies) }
                                if !concerts.isEmpty { eventSection(title: "Events", items: concerts) }
                                if !dining.isEmpty { eventSection(title: "Dining", items: dining) }
                            }
                        }
                        .padding(.top, 14)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationDestination(isPresented: $showProfile) {
                ProfileView()
            }
            .navigationDestination(isPresented: $showGroups) {
                GroupsView()
            }
            .navigationDestination(isPresented: $showSchedules) {
                DailySchedulesView()
            }
        }
        .task {
            locationManager.requestLocation()
            await fetchSpotlightEvents()
            await fetchAllSections()
        }
    }
    
    private func fetchSpotlightEvents() async {
        guard let url = URL(string: "https://district.monu14.me/api/v1/events/spotlight") else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        isLoadingSpotlight = true
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
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
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try JSONDecoder().decode([SpotlightItem].self, from: data)
        } catch {
            print("Failed to fetch \(type) events: \(error)")
            return []
        }
    }
    
    // MARK: - View Components
    private var background: some View {
        Color(red: 0.05, green: 0.05, blue: 0.06)
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
                                .font(.system(size: 22, weight: .bold))
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

                Button {
                    showSchedules = true
                } label: {
                    CircleIconButton(systemName: "calendar")
                }
                .buttonStyle(.plain)
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
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            
            Text("Search events, movies, restaurants...")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white.opacity(0.3))
            
            Spacer()
        }
        .frame(height: 52)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
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
                            NavigationLink(destination: EventDetailView(item: item)) {
                                SpotlightCard(item: item)
                                    .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 16)
                            }
                            .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                NavigationLink(destination: CategoryListView(category: categories.first(where: { $0.title == title || ($0.title == "Events" && title == "Events") }) ?? categories[0])) {
                    Text("See all")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 18)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(items) { item in
                        NavigationLink(destination: EventDetailView(item: item)) {
                            SectionCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
        .padding(.top, 10)
        .id(title)
    }
}

// MARK: - Models
struct Category: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let apiType: String
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
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 100)
                
                Image(category.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            }
            
            Text(category.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

struct SpotlightCard: View {
    let item: SpotlightItem
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.white.opacity(0.06)
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .overlay(
                    AsyncImage(url: URL(string: item.imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().tint(.white)
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.2))
                        @unknown default:
                            EmptyView()
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.8)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                if let type = item.type {
                    Text(type.capitalized)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                
                Text(item.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                Text(item.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .padding(20)
        }
    }
}

struct SectionCard: View {
    let item: SpotlightItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.white.opacity(0.06)
                .frame(width: 200, height: 140)
                .overlay(
                    AsyncImage(url: URL(string: item.imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().tint(.white)
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            Image(systemName: "photo").foregroundStyle(.white.opacity(0.2))
                        @unknown default:
                            EmptyView()
                        }
                    }
                )
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 16,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 16,
                        style: .continuous
                    )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                if let date = item.date {
                    Text(String(date.prefix(10)))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(12)
            .frame(width: 200, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
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
                .fill(Color(red: 0.37, green: 0.42, blue: 0.82))
                .frame(width: 42, height: 42)
            
            Image(systemName: "person.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
        }
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
