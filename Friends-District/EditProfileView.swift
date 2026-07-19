//
//   EditProfileView.swift
//   Friends-District
//
//   Created by somil jain on 18/07/26.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Local Storage
    @AppStorage("profileName") private var storedName = ""
    @AppStorage("profileUsername") private var storedUsername = ""
    @AppStorage("profileEmail") private var storedEmail = ""
    @AppStorage("profileBirthday") private var storedBirthday = ""
    @AppStorage("profileImageData") private var storedImageData: Data = Data()
    
    // MARK: - Form States
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var birthday = ""
    
    // Image Selection States
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: Image? = nil
    @State private var selectedImageData: Data? = nil
    
    // MARK: - Dynamic Progress Calculation
    private var stepsDone: Int {
        var count = 0
        if !name.trimmingCharacters(in: .whitespaces).isEmpty { count += 1 }
        if !phone.trimmingCharacters(in: .whitespaces).isEmpty { count += 1 }
        if !email.trimmingCharacters(in: .whitespaces).isEmpty { count += 1 }
        if !birthday.trimmingCharacters(in: .whitespaces).isEmpty { count += 1 }
        return count
    }
    
    private var progress: Double {
        return Double(stepsDone) / 4.0
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.008, green: 0.008, blue: 0.012)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    
                    cardContent
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Load existing stored data into the form
            name = storedName
            phone = storedUsername
            email = storedEmail
            birthday = storedBirthday
            
            if !storedImageData.isEmpty, let uiImage = UIImage(data: storedImageData) {
                profileImage = Image(uiImage: uiImage)
                selectedImageData = storedImageData
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
            
            Text("Edit Profile")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            
            Spacer()
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Basic information")
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(.white)
            
            ProgressView(value: progress)
                .tint(Color(red: 0.72, green: 0.67, blue: 0.98))
                .scaleEffect(y: 2.2)
                .padding(.horizontal, 4)
                .padding(.top, 10)
                .animation(.easeInOut, value: progress)
            
            Text("\(stepsDone) / 4 steps done")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(red: 0.72, green: 0.67, blue: 0.98))
                .animation(.easeInOut, value: stepsDone)
            
            Divider()
                .overlay(Color.white.opacity(0.10))
                .padding(.vertical, 6)
            
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 190, height: 190)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.95))
                            .frame(width: 190, height: 190)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(Color(red: 0.78, green: 0.82, blue: 0.93))
                            )
                    }
                }
                
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.18, green: 0.18, blue: 0.20))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .buttonStyle(.plain)
                .offset(x: -4, y: -4)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        
                        // Compress the image down so UserDefaults doesn't fail saving it
                        if let compressedData = uiImage.jpegData(compressionQuality: 0.1) {
                            await MainActor.run {
                                profileImage = Image(uiImage: uiImage)
                                selectedImageData = compressedData
                            }
                        }
                    }
                }
            }
            
            fieldTitle("Name")
            textFieldBox(text: $name, placeholder: "Enter your name")
            
            fieldTitle("Phone number")
            textFieldBox(text: $phone, placeholder: "+91 9997990155", disabled: false)
                .keyboardType(.phonePad)
            
            fieldTitle("Email")
            textFieldBox(text: $email, placeholder: "Enter your email")
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            fieldTitle("Birthday")
            textFieldBox(text: $birthday, placeholder: "DD / MM / YY")
                .keyboardType(.numberPad)
                .onChange(of: birthday) { _, newValue in
                    formatBirthday(newValue)
                }
            
            Button {
                saveProfile()
            } label: {
                Text("Update profile")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(red: 0.60, green: 0.55, blue: 0.90))
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private func fieldTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .regular))
            .foregroundStyle(.white)
            .padding(.top, 4)
    }
    
    private func textFieldBox(text: Binding<String>, placeholder: String, disabled: Bool = false) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.25)))
            .font(.system(size: 20, weight: .regular))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .disabled(disabled)
            .opacity(disabled ? 0.6 : 1)
    }
    
    private func formatBirthday(_ value: String) {
        let numbersOnly = value.filter { $0.isNumber }
        var formatted = ""
        
        for (index, char) in numbersOnly.enumerated() {
            if index == 2 || index == 4 {
                formatted += " / "
            }
            if index < 6 {
                formatted.append(char)
            }
        }
        
        if birthday != formatted {
            birthday = formatted
        }
    }
    
    private func saveProfile() {
        storedName = name
        storedUsername = phone
        storedEmail = email
        storedBirthday = birthday
        if let selectedImageData {
            storedImageData = selectedImageData
        }
        dismiss()
    }
}

#Preview {
    EditProfileView()
}
