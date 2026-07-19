//
//  ProfileSetupView.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import SwiftUI
import PhotosUI

// MARK: - API Models
struct ProfilePayload: Codable {
    let email: String
    let mobile_number: String
    let name: String
    let username: String
}

struct ProfileSetupView: View {
    @AppStorage("hasCompletedProfile") private var hasCompletedProfile = false
    
    @AppStorage("profileName") private var storedName = ""
    @AppStorage("profileUsername") private var storedUsername = ""
    @AppStorage("profilePhone") private var storedPhone = ""
    @AppStorage("profileEmail") private var storedEmail = ""
    @AppStorage("profileBirthday") private var storedBirthday = ""
    @AppStorage("profileImageData") private var storedImageData: Data = Data()
    
    @State private var name = ""
    @State private var username = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    @State private var countryCode = "+91"
    
    // UI States
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    
    // Validates that mandatory fields are filled (Image is now optional)
    private var canCreateProfile: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isSubmitting
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.06)
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
                            
                            Circle()
                                .fill(Color(red: 0.44, green: 0.24, blue: 0.95))
                                .frame(width: 54, height: 54)
                                .overlay(
                                    Image(systemName: "camera")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(.white)
                                )
                                .offset(x: 4, y: 4)
                        }
                    }
                    .buttonStyle(.plain)
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        guard let newItem else { return }
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                
                                if let compressedData = uiImage.jpegData(compressionQuality: 0.1) {
                                    await MainActor.run {
                                        selectedImage = uiImage
                                        storedImageData = compressedData
                                    }
                                }
                            }
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text("Add profile photo")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.78))
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        fieldTitle("Full name", required: true)
                        textFieldRow(
                            icon: "person",
                            placeholder: "Enter your full name",
                            text: $name
                        )
                        
                        fieldTitle("Username", required: false)
                        textFieldRow(
                            icon: "at",
                            placeholder: "Choose a username (optional)",
                            text: $username
                        )
                        
                        fieldTitle("Email address", required: true)
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
                        Task {
                            await handleProfileCreation()
                        }
                    } label: {
                        Group {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Profile")
                                    .font(.system(size: 20, weight: .bold))
                            }
                        }
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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }
    
    // MARK: - Subviews
    
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
    
    // MARK: - Logic & API Calls
    
    private func handleProfileCreation() async {
        isSubmitting = true
        defer { isSubmitting = false }
        
        do {
            try await submitProfileToAPI()
            
            // If successful, save to AppStorage and navigate
            await MainActor.run {
                saveProfileLocally()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func submitProfileToAPI() async throws {
        guard let url = URL(string: "https://district.monu14.me/api/v1/profile") else {
            throw URLError(.badURL)
        }
        
        let formattedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload = ProfilePayload(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            mobile_number: formattedPhone,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            username: username.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 201 {
            throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to create profile. Server returned status code: \(httpResponse.statusCode)"])
        }
    }
    
    private func saveProfileLocally() {
        storedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        storedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        storedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        storedPhone = "\(countryCode) \(phone.trimmingCharacters(in: .whitespacesAndNewlines))"
        hasCompletedProfile = true
    }
}

#Preview {
    ProfileSetupView()
}
