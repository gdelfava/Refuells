//
//  StationsView.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI

struct StationsView: View {
    @State private var showingAddStation = false
    @State private var stations: [Station] = [
        Station(
            name: "Shell Station",
            address: "123 Main Street, Downtown",
            fuelTypes: ["Regular", "Premium", "Diesel"],
            currentPrices: ["Regular": 1.85, "Premium": 2.15, "Diesel": 1.95],
            rating: 4.5,
            distance: 2.3,
            isFavorite: true
        ),
        Station(
            name: "BP Gas Station",
            address: "456 Oak Avenue, Midtown",
            fuelTypes: ["Regular", "Premium"],
            currentPrices: ["Regular": 1.82, "Premium": 2.12],
            rating: 4.2,
            distance: 5.1,
            isFavorite: false
        ),
        Station(
            name: "Exxon Mobil",
            address: "789 Pine Road, Uptown",
            fuelTypes: ["Regular", "Premium", "Diesel", "E85"],
            currentPrices: ["Regular": 1.88, "Premium": 2.18, "Diesel": 1.98, "E85": 1.65],
            rating: 4.7,
            distance: 8.7,
            isFavorite: true
        )
    ]
    
    var body: some View {
        MenuWrapperView {
            NavigationStack {
                VStack {
                    // Stations list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(stations.sorted(by: { $0.distance < $1.distance })) { station in
                                StationRow(station: station)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .navigationTitle("Stations")
                .navigationBarTitleDisplayMode(.large)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showingAddStation = true
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
        .sheet(isPresented: $showingAddStation) {
            AddStationView(stations: $stations)
        }
    }
}

struct Station: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let fuelTypes: [String]
    let currentPrices: [String: Double]
    let rating: Double
    let distance: Double // in kilometers
    var isFavorite: Bool
}

struct StationRow: View {
    let station: Station
    
    var body: some View {
        NavigationLink(destination: StationDetailView(station: station)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(station.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(station.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", station.rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(String(format: "%.1f", station.distance))km")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Fuel prices
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fuel Prices")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 15) {
                        ForEach(station.fuelTypes, id: \.self) { fuelType in
                            if let price = station.currentPrices[fuelType] {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fuelType)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("$\(String(format: "%.2f", price))")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
                
                HStack {
                    Button(action: {
                        // Toggle favorite
                    }) {
                        Image(systemName: station.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(station.isFavorite ? .red : .gray)
                    }
                    
                    Spacer()
                    
                    Button("Directions") {
                        // Open directions
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddStationView: View {
    @Binding var stations: [Station]
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var selectedFuelTypes: Set<String> = []
    @State private var regularPrice: String = ""
    @State private var premiumPrice: String = ""
    @State private var dieselPrice: String = ""
    
    private let availableFuelTypes = ["Regular", "Premium", "Diesel", "E85"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Station Details") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Station name", text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Address")
                        Spacer()
                        TextField("Address", text: $address)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Fuel Types") {
                    ForEach(availableFuelTypes, id: \.self) { fuelType in
                        HStack {
                            Text(fuelType)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { selectedFuelTypes.contains(fuelType) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedFuelTypes.insert(fuelType)
                                    } else {
                                        selectedFuelTypes.remove(fuelType)
                                    }
                                }
                            ))
                        }
                    }
                }
                
                Section("Prices") {
                    if selectedFuelTypes.contains("Regular") {
                        HStack {
                            Text("Regular Price")
                            Spacer()
                            TextField("0.00", text: $regularPrice)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    if selectedFuelTypes.contains("Premium") {
                        HStack {
                            Text("Premium Price")
                            Spacer()
                            TextField("0.00", text: $premiumPrice)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    if selectedFuelTypes.contains("Diesel") {
                        HStack {
                            Text("Diesel Price")
                            Spacer()
                            TextField("0.00", text: $dieselPrice)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                Section {
                    Button("Add Station") {
                        addStation()
                    }
                    .disabled(name.isEmpty || address.isEmpty || selectedFuelTypes.isEmpty)
                }
            }
            .navigationTitle("Add Station")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addStation() {
        var prices: [String: Double] = [:]
        
        if selectedFuelTypes.contains("Regular"), let price = Double(regularPrice) {
            prices["Regular"] = price
        }
        if selectedFuelTypes.contains("Premium"), let price = Double(premiumPrice) {
            prices["Premium"] = price
        }
        if selectedFuelTypes.contains("Diesel"), let price = Double(dieselPrice) {
            prices["Diesel"] = price
        }
        
        let newStation = Station(
            name: name,
            address: address,
            fuelTypes: Array(selectedFuelTypes),
            currentPrices: prices,
            rating: 0.0,
            distance: 0.0,
            isFavorite: false
        )
        
        stations.append(newStation)
        dismiss()
    }
}

#Preview {
    StationsView()
} 