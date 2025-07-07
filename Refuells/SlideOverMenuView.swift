//
//  SlideOverMenuView.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI

struct SlideOverMenuView: View {
    @Binding var isShowing: Bool
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var showingSettings = false
    @State private var showingVehicles = false
    
    var body: some View {
        ZStack {
            // Background overlay
            if isShowing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }
            }
            
            // Menu content
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "fuelpump.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            
                            Text("Refuells")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        if let user = firebaseManager.currentUser {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(user.displayName ?? "User")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(user.email ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                    
                    Divider()
                    
                    // Menu items
                    ScrollView {
                        VStack(spacing: 0) {
                            MenuSection(title: "Main") {
                                MenuItem(
                                    icon: "car.fill",
                                    title: "Vehicles",
                                    color: .blue
                                ) {
                                    showingVehicles = true
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isShowing = false
                                    }
                                }
                                
                                MenuItem(
                                    icon: "shield.fill",
                                    title: "Insure",
                                    color: .green
                                ) {
                                    // Navigate to insurance
                                }
                                
                                MenuItem(
                                    icon: "dollarsign.circle.fill",
                                    title: "Finance",
                                    color: .orange
                                ) {
                                    // Navigate to finance
                                }
                                
                                MenuItem(
                                    icon: "fuelpump.circle.fill",
                                    title: "Fuel Spend Calculator",
                                    color: .red
                                ) {
                                    // Navigate to fuel calculator
                                }
                                
                                MenuItem(
                                    icon: "plus.forwardslash.minus",
                                    title: "Trip Cost Calculator",
                                    color: .purple
                                ) {
                                    // Navigate to trip calculator
                                }
                                
                                MenuItem(
                                    icon: "book.fill",
                                    title: "Discovery Guides",
                                    color: .indigo
                                ) {
                                    // Navigate to guides
                                }
                                
                                MenuItem(
                                    icon: "gearshape.fill",
                                    title: "Admin Settings",
                                    color: .gray
                                ) {
                                    // Navigate to admin settings
                                }
                            }
                            
                            MenuSection(title: "Account") {
                                MenuItem(
                                    icon: "person.circle.fill",
                                    title: "Profile",
                                    color: .blue
                                ) {
                                    // Navigate to profile
                                }
                                
                                MenuItem(
                                    icon: "gear",
                                    title: "Settings",
                                    color: .gray
                                ) {
                                    showingSettings = true
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isShowing = false
                                    }
                                }
                                
                                MenuItem(
                                    icon: "questionmark.circle.fill",
                                    title: "Help & Support",
                                    color: .blue
                                ) {
                                    // Navigate to help
                                }
                            }
                            
                            MenuSection(title: "Data") {
                                MenuItem(
                                    icon: "square.and.arrow.up",
                                    title: "Export Data",
                                    color: .green
                                ) {
                                    // Export data
                                }
                                
                                MenuItem(
                                    icon: "icloud.fill",
                                    title: "Backup to iCloud",
                                    color: .blue
                                ) {
                                    // Backup data
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 10)
                            
                            // Sign out button
                            Button(action: {
                                firebaseManager.signOut()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isShowing = false
                                }
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .foregroundColor(.red)
                                    Text("Sign Out")
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 15)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .frame(width: 280)
                .background(Color(.systemBackground))
                .offset(x: isShowing ? 0 : -280)
                
                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isShowing)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingVehicles) {
            VehiclesView()
        }
    }
}

struct MenuSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 15)
                .padding(.bottom, 8)
            
            content
        }
    }
}

struct MenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SlideOverMenuView(isShowing: .constant(true))
} 
