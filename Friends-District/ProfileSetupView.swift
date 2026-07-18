//
//  ProfileSetupView.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @AppStorage("hasCompletedProfile") private var hasCompletedProfile = false
    
    @AppStorage("profileName") private var storedName = ""
    @AppStorage("profilePhone") private var storedPhone = ""
    @AppStorage("profileEmail") private var storedEmail = ""
    @AppStorage("profileBirthday") private var storedBirthday = ""
    @AppStorage("profileImageData") private var storedImageData: Data = Data()
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    @State private var countryCode = "+91"
    
    private var canCreateProfile: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.08),
                    Color(red: 0.08, green: 0.07, blue: 0.12),
                    Color(red: 0.12, green: 0.08, blue: 0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Text("Let’s get to know you")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Create your profile to get started")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            
                            // Center-aligned group for the border and the profile image
                            ZStack {
                                Circle()
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                                    .foregroundStyle(Color.purple.opacity(0.8))
                                    .frame(width: 204, height: 204)
                                
                                if let selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 190, height: 190)
                                        .clipShape(Circle())
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.92))
                                            .frame(width: 190, height: 190)
                                        
                                        Circle()
                                            .fill(Color(red: 0.78, green: 0.82, blue: 0.93))
                                            .frame(width: 58, height: 58)
                                            .offset(y: -32)
                                        
                                        Capsule()
                                            .fill(Color(red: 0.78, green: 0.82, blue: 0.93))
                                            .frame(width: 112, height: 72)
                                            .offset(y: 24)
                                    }
                                    .clipShape(Circle())
                                }
                            }
                            
                            // Camera button anchored to the bottom right of the main ZStack
                            Circle()
                                .fill(Color(red: 0.44, green: 0.24, blue: 0.95))
                                .frame(width: 54, height: 54)
                                .overlay(
                                    Image(systemName: "camera")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(.white)
                                )
                                .offset(x: 4, y: 4) // Adjusted offset for a clean overlap
                        }
                    }
                    .buttonStyle(.plain)
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        guard let newItem else { return }
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                
                                // Compress image before saving to UserDefaults
                                if let compressedData = uiImage.jpegData(compressionQuality: 0.1) {
                                    await MainActor.run {
                                        selectedImage = uiImage
                                        storedImageData = compressedData
                                    }
                                }
                            }
                        }
                    }
                    
                    Text("Add profile photo")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.78))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        fieldTitle("Full name")
                        textFieldRow(
                            icon: "person",
                            placeholder: "Enter your full name",
                            text: $name
                        )
                        
                        fieldTitle("Email address")
                        textFieldRow(
                            icon: "envelope",
                            placeholder: "Enter your email address",
                            text: $email
                        )
                        
                        fieldTitle("Phone number", required: true)
                        phoneRow
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "shield.checkerboard")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(Color.purple.opacity(0.85))
                                .padding(.top, 2)
                            
                            Text("Your phone number is required for account verification and security.")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(.white.opacity(0.62))
                                .lineSpacing(2)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.top, 6)
                    
                    Button {
                        saveProfile()
                    } label: {
                        Text("Create Profile")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.54, green: 0.28, blue: 0.96),
                                        Color(red: 0.36, green: 0.23, blue: 0.90)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .opacity(canCreateProfile ? 1 : 0.45)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canCreateProfile)
                    .padding(.top, 10)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
    }
    
    private var phoneRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "phone")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.purple.opacity(0.85))
            
            Menu {
                Button("+91") { countryCode = "+91" }
                Button("+1") { countryCode = "+1" }
                Button("+44") { countryCode = "+44" }
            } label: {
                HStack(spacing: 4) {
                    Text(countryCode)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white.opacity(0.9))
            }
            
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: 26)
            
            TextField("Enter your phone number", text: $phone)
                .keyboardType(.numberPad)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .frame(height: 62)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    private func fieldTitle(_ title: String, required: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
            
            if required {
                Text("*")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.red.opacity(0.9))
            }
        }
        .padding(.top, 4)
    }
    
    private func textFieldRow(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.purple.opacity(0.85))
            
            TextField(placeholder, text: text)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .frame(height: 62)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    private func saveProfile() {
        storedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        storedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        storedPhone = "\(countryCode) \(phone.trimmingCharacters(in: .whitespacesAndNewlines))"
        hasCompletedProfile = true
    }
}

#Preview {
    ProfileSetupView()
}
