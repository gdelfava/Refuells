//
//  StationDetailView.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI
import MapKit

struct StationDetailView: View {
    let station: Station
    @Environment(\.dismiss) private var dismiss
    @State private var isFavorite: Bool
    @State private var showingDirections = false
    @State private var showingEditForm = false
    
    init(station: Station) {
        self.station = station
        self._isFavorite = State(initialValue: station.isFavorite)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header section
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(station.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text(station.address)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                isFavorite.toggle()
                            }) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(isFavorite ? .red : .gray)
                            }
                        }
                        
                        // Rating and distance
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", station.rating))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("\(String(format: "%.1f", station.distance)) km away")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Edit and Delete buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            showingEditForm = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            // Delete station
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                    }
                    
                    // Fuel prices section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Fuel Prices")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(station.fuelTypes, id: \.self) { fuelType in
                                if let price = station.currentPrices[fuelType] {
                                    FuelPriceCard(
                                        fuelType: fuelType,
                                        price: price
                                    )
                                }
                            }
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showingDirections = true
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Get Directions")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            // Call station
                        }) {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("Call Station")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Additional info section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Station Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            InfoRow(icon: "fuelpump.fill", title: "Fuel Types", value: station.fuelTypes.joined(separator: ", "))
                            InfoRow(icon: "clock.fill", title: "Hours", value: "24/7")
                            InfoRow(icon: "creditcard.fill", title: "Payment", value: "Cash, Credit, Debit")
                            InfoRow(icon: "car.fill", title: "Services", value: "Self-service, Full-service")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Station Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingDirections) {
            DirectionsView(station: station)
        }
        .sheet(isPresented: $showingEditForm) {
            EditStationView(station: station)
        }
    }
}

struct FuelPriceCard: View {
    let fuelType: String
    let price: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Text(fuelType)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("$\(String(format: "%.2f", price))")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

struct DirectionsView: View {
    let station: Station
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Directions to \(station.name)")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Text("This would integrate with Apple Maps or Google Maps to provide turn-by-turn directions to the station.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Directions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    StationDetailView(station: Station(
        name: "Shell Station",
        address: "123 Main Street, Downtown",
        fuelTypes: ["Regular", "Premium", "Diesel"],
        currentPrices: ["Regular": 1.85, "Premium": 2.15, "Diesel": 1.95],
        rating: 4.5,
        distance: 2.3,
        isFavorite: true
    ))
} 