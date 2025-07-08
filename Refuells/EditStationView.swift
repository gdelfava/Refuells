//
//  EditStationView.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI

struct EditStationView: View {
    let station: Station
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var address: String
    @State private var selectedFuelTypes: Set<String>
    @State private var regularPrice: String
    @State private var premiumPrice: String
    @State private var dieselPrice: String
    @State private var e85Price: String
    @State private var rating: Double
    @State private var distance: String
    @State private var isFavorite: Bool
    
    private let availableFuelTypes = ["Regular", "Premium", "Diesel", "E85"]
    
    init(station: Station) {
        self.station = station
        self._name = State(initialValue: station.name)
        self._address = State(initialValue: station.address)
        self._selectedFuelTypes = State(initialValue: Set(station.fuelTypes))
        self._regularPrice = State(initialValue: station.currentPrices["Regular"]?.description ?? "")
        self._premiumPrice = State(initialValue: station.currentPrices["Premium"]?.description ?? "")
        self._dieselPrice = State(initialValue: station.currentPrices["Diesel"]?.description ?? "")
        self._e85Price = State(initialValue: station.currentPrices["E85"]?.description ?? "")
        self._rating = State(initialValue: station.rating)
        self._distance = State(initialValue: station.distance.description)
        self._isFavorite = State(initialValue: station.isFavorite)
    }
    
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
                    
                    HStack {
                        Text("Distance (km)")
                        Spacer()
                        TextField("0.0", text: $distance)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Rating")
                        Spacer()
                        Text("\(String(format: "%.1f", rating))")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Favorite")
                        Spacer()
                        Toggle("", isOn: $isFavorite)
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
                    
                    if selectedFuelTypes.contains("E85") {
                        HStack {
                            Text("E85 Price")
                            Spacer()
                            TextField("0.00", text: $e85Price)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty || address.isEmpty || selectedFuelTypes.isEmpty)
                }
            }
            .navigationTitle("Edit Station")
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
    
    private func saveChanges() {
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
        if selectedFuelTypes.contains("E85"), let price = Double(e85Price) {
            prices["E85"] = price
        }
        
        // Here you would typically update the station in your data source
        // For now, we'll just dismiss the view
        print("Updated station: \(name) with prices: \(prices)")
        dismiss()
    }
}

#Preview {
    EditStationView(station: Station(
        name: "Shell Station",
        address: "123 Main Street, Downtown",
        fuelTypes: ["Regular", "Premium", "Diesel"],
        currentPrices: ["Regular": 1.85, "Premium": 2.15, "Diesel": 1.95],
        rating: 4.5,
        distance: 2.3,
        isFavorite: true
    ))
} 