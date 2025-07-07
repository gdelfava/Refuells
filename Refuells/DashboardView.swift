//
//  DashboardView.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Trips Tab
            TripsView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Trips")
                }
                .tag(0)
            
            // Refuels Tab
            FuelLogView()
                .tabItem {
                    Image(systemName: "fuelpump.fill")
                    Text("Refuels")
                }
                .tag(1)
            
            // Stations Tab
            StationsView()
                .tabItem {
                    Image(systemName: "building.2.fill")
                    Text("Stations")
                }
                .tag(2)
            
            // Reports Tab
            DashboardHomeView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Reports")
                }
                .tag(3)
            
            // Drive Tab
            AnalyticsView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("Drive")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .overlay(
            // Network status indicator (for debugging)
            VStack {
                if firebaseManager.networkStatus != "Connected" {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.orange)
                        Text("Network: \(firebaseManager.networkStatus)")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 50) // Account for safe area
                }
                Spacer()
            }
        )
    }
}

// Dashboard Home View
struct DashboardHomeView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    
        var body: some View {
        MenuWrapperView {
            NavigationStack {
                VStack(spacing: 20) {
                    
                    
                    // Main content
                    KeyboardAwareScrollView {
                        VStack(spacing: 20) {
                            // Quick stats
                            HStack(spacing: 15) {
                                StatCard(
                                    title: "Total Fuel",
                                    value: "45.2L",
                                    icon: "fuelpump.fill",
                                    color: .blue
                                )
                                
                                StatCard(
                                    title: "Cost",
                                    value: "$89.50",
                                    icon: "dollarsign.circle.fill",
                                    color: .green
                                )
                            }
                            .padding(.horizontal)
                            
                            HStack(spacing: 15) {
                                StatCard(
                                    title: "Efficiency",
                                    value: "8.2L/100km",
                                    icon: "speedometer",
                                    color: .orange
                                )
                                
                                StatCard(
                                    title: "Distance",
                                    value: "1,234km",
                                    icon: "location.fill",
                                    color: .purple
                                )
                            }
                            .padding(.horizontal)
                            
                            // Recent activity
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Recent Activity")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 10) {
                                    ActivityRow(
                                        title: "Fuel Refill",
                                        subtitle: "Added 45.2L at Shell Station",
                                        time: "2 hours ago",
                                        icon: "fuelpump.fill",
                                        color: .blue
                                    )
                                    
                                    ActivityRow(
                                        title: "Trip Completed",
                                        subtitle: "Drove 120km to downtown",
                                        time: "Yesterday",
                                        icon: "car.fill",
                                        color: .green
                                    )
                                    
                                    ActivityRow(
                                        title: "Maintenance Due",
                                        subtitle: "Oil change recommended",
                                        time: "3 days ago",
                                        icon: "wrench.fill",
                                        color: .orange
                                    )
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .navigationTitle("Reports")
                .navigationBarTitleDisplayMode(.large)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                // Add new report or export data
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let time: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    DashboardView()
} 