//
//  AddFriendView.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    
    enum SearchMode: String, CaseIterable {
        case phone = "Phone Number"
        case email = "Email Address"
    }
    
    @State private var selectedMode: SearchMode = .phone
    @State private var phoneNumber = ""
    @State private var emailAddress = ""
    @State private var searchText = ""
    
    private let people: [SuggestedPerson] = [
        .init(name: "Arjun Sharma", detail: "3 mutual friends", initials: "A", color: Color(red: 0.42, green: 0.20, blue: 0.83), buttonTitle: "Add", buttonStyle: .add),
        .init(name: "Priya Mehta", detail: "1 mutual friend", initials: "P", color: Color(red: 0.74, green: 0.11, blue: 0.34), buttonTitle: "Add", buttonStyle: .add),
        .init(name: "Rahul Verma", detail: "5 mutual friends", initials: "R", color: Color(red: 0.14, green: 0.33, blue: 0.87), buttonTitle: "Friends", buttonStyle: .friends),
        .init(name: "Sneha Kapoor", detail: "2 mutual friends", initials: "S", color: Color(red: 0.05, green: 0.50, blue: 0.36), buttonTitle: "Add", buttonStyle: .add),
        .init(name: "Vikram Nair", detail: "On District", initials: "V", color: Color(red: 0.72, green: 0.33, blue: 0.06), buttonTitle: "Requested", buttonStyle: .requested)
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    
                    segmentedControl
                    
                    Text(selectedMode == .phone ? "Enter your friend's phone number" : "Enter your friend's email address")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 4)
                    
                    if selectedMode == .phone {
                        inputField(
                            placeholder: "+91 XXXXX XXXXX",
                            text: $phoneNumber,
                            systemImage: "phone.fill"
                        )
                    } else {
                        inputField(
                            placeholder: "Enter email address",
                            text: $emailAddress,
                            systemImage: "envelope.fill"
                        )
                    }
                    
                    searchBar
                    
                    Divider()
                        .overlay(Color.white.opacity(0.12))
                        .padding(.top, 2)
                    
                    Text("People You May Know")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, 6)
                    
                    VStack(spacing: 0) {
                        ForEach(people) { person in
                            SuggestedPersonRow(person: person)
                            
                            if person.id != people.last?.id {
                                Divider()
                                    .overlay(Color.white.opacity(0.08))
                                    .padding(.leading, 72)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
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
            
            Text("Add Friend")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            
            Spacer()
        }
    }
    
    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(SearchMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: mode == .phone ? "phone.fill" : "envelope")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text(mode.rawValue)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundStyle(selectedMode == mode ? .white : .white.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(selectedMode == mode ? Color(red: 0.52, green: 0.22, blue: 0.95) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
    
    private var searchBar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(red: 0.10, green: 0.55, blue: 0.95), lineWidth: 2)
                )
                .frame(height: 60)
            
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                
                TextField("Search", text: $searchText)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 18)
        }
    }
    
    private func inputField(placeholder: String, text: Binding<String>, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white.opacity(0.45))
            
            TextField(placeholder, text: text)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .frame(height: 62)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct SuggestedPerson: Identifiable {
    enum ButtonStyleType {
        case add
        case friends
        case requested
    }
    
    let id = UUID()
    let name: String
    let detail: String
    let initials: String
    let color: Color
    let buttonTitle: String
    let buttonStyle: ButtonStyleType
}

struct SuggestedPersonRow: View {
    let person: SuggestedPerson
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(person.color)
                    .frame(width: 54, height: 54)
                
                Text(person.initials)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                
                Text(person.detail)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Button {
                // action for add / friends / requested
            } label: {
                Text(person.buttonTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(buttonTextColor)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(buttonBackground)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
    
    private var buttonTextColor: Color {
        switch person.buttonStyle {
        case .add:
            return .white
        case .friends:
            return Color(red: 0.35, green: 0.95, blue: 0.40)
        case .requested:
            return Color(red: 0.72, green: 0.45, blue: 0.95)
        }
    }
    
    private var buttonBackground: some View {
        switch person.buttonStyle {
        case .add:
            return AnyView(Color(red: 0.52, green: 0.22, blue: 0.95))
        case .friends:
            return AnyView(Color(red: 0.07, green: 0.25, blue: 0.07))
        case .requested:
            return AnyView(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color(red: 0.52, green: 0.22, blue: 0.95), lineWidth: 1)
                    )
            )
        }
    }
}
