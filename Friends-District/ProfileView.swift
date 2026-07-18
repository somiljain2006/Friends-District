//
//   ProfileView.swift
//   Friends-District
//
//   Created by somil jain on 18/07/26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showEditProfile = false
    
    // MARK: - Local Storage
    @AppStorage("hasCompletedProfile") private var hasCompletedProfile = false
    @AppStorage("profileName") private var storedName = ""
    @AppStorage("profileUsername") private var storedUsername = ""
    @AppStorage("profilePhone") private var storedPhone = ""
    @AppStorage("profileEmail") private var storedEmail = ""
    @AppStorage("profileBirthday") private var storedBirthday = ""
    @AppStorage("profileImageData") private var storedImageData: Data = Data()
    @State private var showAddFriend = false
    @State private var showFriendList = false
    @State private var showChatWithUs = false
    
    // MARK: - Dynamic Progress Calculation
    private var stepsDone: Int {
        var count = 0
        if !storedName.trimmingCharacters(in: .whitespaces).isEmpty { count += 1 }
        if !storedPhone.trimmingCharacters(in: .whitespaces).isEmpty { count += 1 }
        if !storedEmail.trimmingCharacters(in: .whitespaces).isEmpty { count += 1 }
        if !storedBirthday.trimmingCharacters(in: .whitespaces).isEmpty { count += 1 }
        return count
    }
    
    private var progress: Double {
        return Double(stepsDone) / 4.0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.09)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        topBar
                            .padding(.horizontal, 18)
                        
                        profileCard
                            .padding(.horizontal, 18)
                        
                        sectionTitle("Friends")
                            .padding(.horizontal, 18)
                            .padding(.top, 4)
                        
                        VStack(spacing: 0) {
                            Button {
                                showAddFriend = true
                            } label: {
                                actionRowContent(icon: "person.crop.circle.badge.plus", isCustomImage: false, title: "Add Friends")
                            }
                            .buttonStyle(.plain)
                            .navigationDestination(isPresented: $showAddFriend) {
                                AddFriendView()
                            }
                            
                            Divider()
                                .overlay(Color.white.opacity(0.08))
                                .padding(.horizontal, 20)
                            
                            Button {
                                showFriendList = true
                            } label: {
                                actionRowContent(icon: "list.bullet", isCustomImage: false, title: "Friend List")
                            }
                            .buttonStyle(.plain)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(red: 0.12, green: 0.12, blue: 0.13))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 18)
                        
                        sectionTitle("More")
                            .padding(.horizontal, 18)
                            .padding(.top, 4)
                        
                        VStack(spacing: 0) {
                            Button {
                                showChatWithUs = true
                            } label: {
                                actionRowContent(icon: "message", isCustomImage: false, title: "Chat with us")
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                                .overlay(Color.white.opacity(0.08))
                                .padding(.horizontal, 20)
                            
                            Button {
                                if let emailURL = URL(string: "mailto:somil16022006@gmail.com") {
                                    openURL(emailURL)
                                }
                            } label: {
                                actionRowContent(icon: "square.and.arrow.up", isCustomImage: false, title: "Share feedback")
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                                .overlay(Color.white.opacity(0.08))
                                .padding(.horizontal, 20)
                            
                            Button {
                                logout()
                            } label: {
                                actionRowContent(icon: "rectangle.portrait.and.arrow.right", isCustomImage: false, title: "Logout", color: .red)
                            }
                            .buttonStyle(.plain)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(red: 0.12, green: 0.12, blue: 0.13))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 18)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .navigationDestination(isPresented: $showFriendList) {
                FriendListView()
            }
            .navigationDestination(isPresented: $showChatWithUs) {
                ChatWithUsView()
            }
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
            
            Text("Profile")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            
            Spacer()
        }
    }
    
    private var profileCard: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    // Profile Image Rendering
                    if !storedImageData.isEmpty, let uiImage = UIImage(data: storedImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 68, height: 68)
                            .clipShape(Circle())
                    } else {
                        ZStack(alignment: .bottom) {
                            Circle()
                                .fill(Color(red: 0.65, green: 0.70, blue: 0.85))
                            
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.white.opacity(0.6))
                                    .frame(width: 26, height: 26)
                                
                                Capsule()
                                    .fill(Color.white.opacity(0.6))
                                    .frame(width: 50, height: 30)
                                    .offset(y: 12)
                            }
                        }
                        .clipShape(Circle())
                        .frame(width: 68, height: 68)
                    }
                    
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 3)
                        .frame(width: 76, height: 76)
                    
                    // Dynamic Progress Circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color(red: 0.60, green: 0.55, blue: 0.90), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 76, height: 76)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: progress)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(storedName.isEmpty ? "No Name Provided" : storedName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(storedPhone.isEmpty ? "No Phone Provided" : storedPhone)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Text("\(stepsDone) / 4 steps done")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(red: 0.60, green: 0.55, blue: 0.90))
                        .padding(.top, 2)
                        .animation(.default, value: stepsDone)
                }
                
                Spacer()
            }
            
            Divider()
                .overlay(Color.white.opacity(0.12))
            
            HStack(alignment: .center) {
                Text("Complete your profile, so we can surprise\nyou on your special days!")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
                    .lineSpacing(2)
                
                Spacer()
                
                Button {
                    showEditProfile = true
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color(red: 0.60, green: 0.55, blue: 0.90), lineWidth: 1.5)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(red: 0.60, green: 0.55, blue: 0.90))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.14, blue: 0.28),
                            Color(red: 0.12, green: 0.10, blue: 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
    }
    
    private func actionRowContent(icon: String, isCustomImage: Bool = false, title: String, color: Color = .white) -> some View {
        HStack(spacing: 10) {
            if isCustomImage {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(color.opacity(0.6))
            } else {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(color.opacity(0.6))
                    .frame(width: 24)
            }
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color.opacity(0.4))
        }
        .padding(.horizontal, 20)
        .frame(height: 64)
        .contentShape(Rectangle())
    }
    
    private func logout() {
        hasCompletedProfile = false
        storedName = ""
        storedUsername = ""
        storedPhone = ""
        storedEmail = ""
        storedBirthday = ""
        storedImageData = Data()
    }
}

#Preview {
    ProfileView()
}
