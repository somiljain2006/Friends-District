//
//  GroupsView.swift
//  Friends-District
//
//  Created by somil jain on 18/07/26.
//

import SwiftUI

struct GroupsView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let groups: [GroupItem] = [
        .init(name: "Weekend Crew", subtitle: "5 members • 2 hours ago", initial: "W", color: Color(red: 0.42, green: 0.20, blue: 0.83)),
        .init(name: "Foodie Gang", subtitle: "4 members • Yesterday", initial: "F", color: Color(red: 0.05, green: 0.48, blue: 0.36)),
        .init(name: "Movie Nights", subtitle: "6 members • 3 days ago", initial: "M", color: Color(red: 0.75, green: 0.11, blue: 0.38)),
        .init(name: "DLF Neighbours", subtitle: "8 members • 1 week ago", initial: "D", color: Color(red: 0.14, green: 0.33, blue: 0.87))
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    
                    Text("4 groups")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.top, 8)
                    
                    VStack(spacing: 0) {
                        ForEach(groups) { group in
                            GroupRow(group: group)
                            
                            if group.id != groups.last?.id {
                                Divider()
                                    .overlay(Color.white.opacity(0.08))
                                    .padding(.leading, 84)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )
                    .padding(.top, 8)
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
            
            Text("Groups")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            
            Spacer()
            
            Button {
                // create group action
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                    Text("Create")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 40)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(red: 0.52, green: 0.22, blue: 0.95))
                )
            }
            .buttonStyle(.plain)
        }
    }
}

struct GroupItem: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let initial: String
    let color: Color
}

struct GroupRow: View {
    let group: GroupItem
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(group.color)
                    .frame(width: 64, height: 64)
                
                Text(group.initial)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(group.name)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                
                Text(group.subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
    }
}

#Preview {
    GroupsView()
}
