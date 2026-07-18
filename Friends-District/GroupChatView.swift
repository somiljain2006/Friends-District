//
//  GroupChatView.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import SwiftUI

struct GroupChatView: View {
    let room: Room
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            topNavigationBar
            
            Divider()
                .overlay(Color.white.opacity(0.1))
            
            ScrollView {
                VStack(spacing: 24) {
                    // System Notification
                    Text("Group Space created · plan your outing here")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                        .padding(.top, 20)
                    
                    // User Message 1
                    userMessageRow(
                        initials: "AS",
                        name: "Ananya Singh",
                        avatarColor: Color(red: 0.42, green: 0.20, blue: 0.83),
                        content: Text("Movie night this weekend? 🍿")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    )
                    
                    // Movie Planner Card
                    moviePlannerCard
                        .padding(.leading, 50) // Aligning with messages
                    
                    // User Message 2
                    userMessageRow(
                        initials: "KM",
                        name: "Kabir Malhotra",
                        avatarColor: Color(red: 0.6, green: 0.1, blue: 0.4),
                        content: Text("In! but let's eat after")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            
            bottomInputBar
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.09).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Components
    
    private var topNavigationBar: some View {
        HStack(spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: "photo.on.rectangle.angled") // Placeholder for group icon
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(room.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text("4 members · Group Space")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(8)
                .background(Circle().fill(Color.white.opacity(0.05)))
            
            Image(systemName: "info.circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(8)
                .background(Circle().fill(Color.white.opacity(0.05)))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func userMessageRow(initials: String, name: String, avatarColor: Color, content: some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.leading, 50)
            
            HStack(alignment: .bottom, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(avatarColor)
                        .frame(width: 30, height: 30)
                    Text(initials)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
                content
                Spacer()
            }
        }
    }
    
    private var moviePlannerCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Image Box
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Color.blue.opacity(0.3)) // Fallback if no image
                    .frame(height: 140)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Movie")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.52, green: 0.22, blue: 0.95))
                        .clipShape(Capsule())
                    
                    Text("The Odyssey")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(16)
            }
            
            // Details Box
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Sat, 19 Jul · 9:15 PM")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(.white.opacity(0.5))
                        Text("PVR Select Citywalk")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "ticket")
                            .foregroundStyle(.white.opacity(0.5))
                        Text("₹480")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.42, green: 0.20, blue: 0.83))
                                    .frame(width: 20, height: 20)
                                Text("AS")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            Text("Shared by Ananya Singh")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
                
                Divider()
                    .overlay(Color.white.opacity(0.1))
                
                // Response Buttons
                HStack(spacing: 12) {
                    votingButton(icon: "👍", label: "Interested · 1")
                    votingButton(icon: "🤔", label: "Maybe · 1")
                    votingButton(icon: "👎", label: "Not Interested")
                }
                
                // Book Tickets
                Button {
                    // Action
                } label: {
                    Text("Book Tickets")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.04))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    private func votingButton(icon: String, label: String) -> some View {
        Button { } label: {
            VStack(spacing: 4) {
                Text(icon).font(.system(size: 16))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var bottomInputBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("Ask @Planner")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0.65, green: 0.40, blue: 1.0))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(red: 0.20, green: 0.10, blue: 0.35))
                .clipShape(Capsule())
            }
            
            HStack(spacing: 12) {
                TextField("Message or @Planner...", text: $messageText)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                
                Button { } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 48, height: 48)
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24) // accommodate home indicator area
        .background(Color(red: 0.08, green: 0.08, blue: 0.09))
    }
}
