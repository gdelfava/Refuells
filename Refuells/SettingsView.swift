//
//  SettingsView.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var showingProfile = false
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var units = "Metric"
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if let user = firebaseManager.currentUser {
                                Text(user.displayName ?? "User")
                                    .font(.headline)
                                Text(user.email ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("User")
                                    .font(.headline)
                                Text("user@example.com")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Edit") {
                            showingProfile = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Profile")
                }
                
                // Preferences Section
                Section {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                        Text("Notifications")
                        Spacer()
                        Toggle("", isOn: $notificationsEnabled)
                    }
                    
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.purple)
                        Text("Dark Mode")
                        Spacer()
                        Toggle("", isOn: $darkModeEnabled)
                    }
                    
                    HStack {
                        Image(systemName: "ruler.fill")
                            .foregroundColor(.green)
                        Text("Units")
                        Spacer()
                        Picker("Units", selection: $units) {
                            Text("Metric").tag("Metric")
                            Text("Imperial").tag("Imperial")
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                } header: {
                    Text("Preferences")
                }
                
                // Data Section
                Section {
                    Button(action: {
                        // Export data functionality
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Export Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        // Backup data functionality
                    }) {
                        HStack {
                            Image(systemName: "icloud.fill")
                                .foregroundColor(.blue)
                            Text("Backup to iCloud")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        // Clear data functionality
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Clear All Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Data Management")
                }
                
                // Support Section
                Section {
                    Button(action: {
                        // Help functionality
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.blue)
                            Text("Help & Support")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        // Feedback functionality
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                            Text("Send Feedback")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        // About functionality
                    }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("About Refuells")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Support")
                }
                
                // Account Section
                Section {
                    Button(action: {
                        firebaseManager.signOut()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                } header: {
                    Text("Account")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileEditView()
        }
    }
}

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    @State private var displayName: String = ""
    @State private var email: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Information") {
                    HStack {
                        Text("Display Name")
                        Spacer()
                        TextField("Enter name", text: $displayName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        TextField("Enter email", text: $email)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                
                Section {
                    Button("Save Changes") {
                        // Save profile changes
                        dismiss()
                    }
                    .disabled(displayName.isEmpty || email.isEmpty)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let user = firebaseManager.currentUser {
                    displayName = user.displayName ?? ""
                    email = user.email ?? ""
                }
            }
        }
    }
}

#Preview {
    SettingsView()
} 