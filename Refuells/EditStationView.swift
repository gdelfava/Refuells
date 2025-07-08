//
//  EditStationView.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI
import PhotosUI

struct EditStationView: View {
    let station: Station
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseManager = FirebaseManager.shared
    var onStationUpdated: (() -> Void)?
    
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
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isSaving = false
    
    private let availableFuelTypes = ["Regular", "Premium", "Diesel", "E85"]
    
    init(station: Station, onStationUpdated: (() -> Void)? = nil) {
        self.station = station
        self.onStationUpdated = onStationUpdated
        self._name = State(initialValue: station.name)
        self._address = State(initialValue: station.address)
        self._selectedFuelTypes = State(initialValue: Set(station.fuelTypes))
        self._regularPrice = State(initialValue: station.currentPrices["Regular"]?.description ?? "")
        self._premiumPrice = State(initialValue: station.currentPrices["Premium"]?.description ?? "")
        self._dieselPrice = State(initialValue: station.currentPrices["Diesel"]?.description ?? "")
        self._e85Price = State(initialValue: station.currentPrices["E85"]?.description ?? "")
        
        print("🔍 Initializing EditStationView with station data:")
        print("   - Station prices: \(station.currentPrices)")
        print("   - Regular price: \(station.currentPrices["Regular"]?.description ?? "nil")")
        print("   - Premium price: \(station.currentPrices["Premium"]?.description ?? "nil")")
        print("   - Diesel price: \(station.currentPrices["Diesel"]?.description ?? "nil")")
        print("   - E85 price: \(station.currentPrices["E85"]?.description ?? "nil")")
        print("   - Regular price field will be initialized to: '\(station.currentPrices["Regular"]?.description ?? "")'")
        print("   - Premium price field will be initialized to: '\(station.currentPrices["Premium"]?.description ?? "")'")
        print("   - Diesel price field will be initialized to: '\(station.currentPrices["Diesel"]?.description ?? "")'")
        print("   - E85 price field will be initialized to: '\(station.currentPrices["E85"]?.description ?? "")'")
        self._rating = State(initialValue: station.rating)
        self._distance = State(initialValue: station.distance.description)
        self._isFavorite = State(initialValue: station.isFavorite)
        self._selectedImage = State(initialValue: station.image)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Station Image") {
                    VStack(spacing: 12) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                                .frame(height: 200)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        Text("No Image Selected")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                )
                        }
                        
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                Text(selectedImage == nil ? "Add Photo" : "Change Photo")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
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
                    Button(action: {
                        saveChanges()
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Saving...")
                                    .foregroundColor(.white)
                            } else {
                                Text("Save Changes")
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(isSaving ? Color.gray : Color.blue)
                        .cornerRadius(8)
                    }
                    .disabled(name.isEmpty || address.isEmpty || selectedFuelTypes.isEmpty || isSaving)
                }
            }
            .navigationTitle(isSaving ? "Saving..." : "Edit Station")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
            }
            .onChange(of: selectedPhotoItem) { oldValue, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
    }
    
    private func parsePrice(_ priceString: String) -> Double? {
        // Remove any whitespace
        let cleaned = priceString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If empty, return nil
        if cleaned.isEmpty {
            return nil
        }
        
        // Try parsing with period first (standard format)
        if let price = Double(cleaned) {
            return price
        }
        
        // Try parsing with comma (European format)
        let commaReplaced = cleaned.replacingOccurrences(of: ",", with: ".")
        if let price = Double(commaReplaced) {
            return price
        }
        
        // If it's just a whole number, convert to double
        if let intValue = Int(cleaned) {
            return Double(intValue)
        }
        
        return nil
    }
    
    private func saveChanges() {
        // Start saving state
        isSaving = true
        
        var prices: [String: Double] = [:]
        
        print("🔍 Price field values:")
        print("   - Regular: '\(regularPrice)' -> \(Double(regularPrice) ?? 0)")
        print("   - Premium: '\(premiumPrice)' -> \(Double(premiumPrice) ?? 0)")
        print("   - Diesel: '\(dieselPrice)' -> \(Double(dieselPrice) ?? 0)")
        print("   - E85: '\(e85Price)' -> \(Double(e85Price) ?? 0)")
        
        if selectedFuelTypes.contains("Regular"), let price = parsePrice(regularPrice) {
            prices["Regular"] = price
        }
        if selectedFuelTypes.contains("Premium"), let price = parsePrice(premiumPrice) {
            prices["Premium"] = price
        }
        if selectedFuelTypes.contains("Diesel"), let price = parsePrice(dieselPrice) {
            prices["Diesel"] = price
        }
        if selectedFuelTypes.contains("E85"), let price = parsePrice(e85Price) {
            prices["E85"] = price
        }
        
        print("🔍 Updating station with prices: \(prices)")
        print("🔍 Selected fuel types: \(Array(selectedFuelTypes))")
        
        let updatedStation = Station(
            id: station.id,
            name: name,
            address: address,
            fuelTypes: Array(selectedFuelTypes),
            currentPrices: prices,
            rating: rating,
            distance: Double(distance) ?? station.distance,
            isFavorite: isFavorite,
            image: selectedImage
        )
        
        // Update station in Firebase
        firebaseManager.updateStation(updatedStation) { result in
            DispatchQueue.main.async {
                self.isSaving = false // Stop saving state
                
                switch result {
                case .success(_):
                    print("✅ Station updated successfully in Firebase")
                    // Upload image if selected
                    if let image = selectedImage {
                        self.isSaving = true // Resume saving for image upload
                        
                        // Clear cached image first so new image will be loaded
                        ImageCache.shared.removeImage(for: station.id.uuidString)
                        
                        firebaseManager.uploadStationImage(image, stationId: station.id.uuidString) { imageResult in
                            DispatchQueue.main.async {
                                self.isSaving = false // Stop saving state for image upload
                                
                                switch imageResult {
                                case .success(_):
                                    print("✅ Station image updated successfully")
                                    // Cache the new image immediately
                                    ImageCache.shared.setImage(image, for: station.id.uuidString)
                                case .failure(let error):
                                    print("❌ Failed to upload image: \(error.localizedDescription)")
                                }
                                // Notify parent that station was updated
                                onStationUpdated?()
                                dismiss()
                            }
                        }
                    } else {
                        // Notify parent that station was updated
                        onStationUpdated?()
                        dismiss()
                    }
                case .failure(let error):
                    print("❌ Failed to update station: \(error.localizedDescription)")
                    // Still dismiss on error
                    dismiss()
                }
            }
        }
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
        isFavorite: true,
        image: nil
    ))
} 