//
//  StationsView.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI
import PhotosUI

struct StationsView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var showingAddStation = false
    @State private var stations: [Station] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
                MenuWrapperView {
            NavigationStack {
                ZStack {
                    VStack {
                        if isLoading {
                            Spacer()
                            ProgressView("Loading stations...")
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        } else if let errorMessage = errorMessage {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                Text("Error loading stations")
                                    .font(.headline)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Button("Retry") {
                                    loadStations()
                                }
                                .foregroundColor(.blue)
                            }
                            .padding()
                            Spacer()
                        } else {
                            // Stations list
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(stations.sorted(by: { $0.distance < $1.distance })) { station in
                                        StationRow(station: station, onStationDeleted: {
                                            loadStations()
                                        })
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .navigationTitle("Stations")
                    .navigationBarTitleDisplayMode(.large)
                    
                    // Floating button - always in bottom right
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
                }
            }
        }
        .sheet(isPresented: $showingAddStation) {
            AddStationView(stations: $stations, onStationAdded: {
                loadStations()
            })
        }
        .onAppear {
            loadStations()
        }
    }
    
    private func loadStations() {
        guard firebaseManager.isAuthenticated else {
            errorMessage = "Please sign in to view your stations"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        firebaseManager.fetchStations { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let fetchedStations):
                    self.stations = fetchedStations
                    // Load images for each station concurrently (but with limit)
                    loadStationImagesOptimized(for: fetchedStations)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadStationImagesOptimized(for stations: [Station]) {
        // Load images in batches to avoid overwhelming the network
        let batchSize = 3
        let batches = stations.chunked(into: batchSize)
        
        for (batchIndex, batch) in batches.enumerated() {
            // Stagger batch loading to spread network load
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(batchIndex) * 0.2) {
                for station in batch {
                    self.loadStationImage(for: station)
                }
            }
        }
    }
    
    private func loadStationImage(for station: Station) {
        firebaseManager.loadStationImage(stationId: station.id.uuidString) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    if let image = image {
                        // Update the station with the loaded image
                        if let index = self.stations.firstIndex(where: { $0.id == station.id }) {
                            self.stations[index].image = image
                        }
                    }
                case .failure(let error):
                    print("Failed to load image for station \(station.name): \(error.localizedDescription)")
                }
            }
        }
    }
}

struct Station: Identifiable {
    let id: UUID
    let name: String
    let address: String
    let fuelTypes: [String]
    let currentPrices: [String: Double]
    let rating: Double
    let distance: Double // in kilometers
    var isFavorite: Bool
    var image: UIImage?
    
    init(id: UUID = UUID(), name: String, address: String, fuelTypes: [String], currentPrices: [String: Double], rating: Double, distance: Double, isFavorite: Bool, image: UIImage? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.fuelTypes = fuelTypes
        self.currentPrices = currentPrices
        self.rating = rating
        self.distance = distance
        self.isFavorite = isFavorite
        self.image = image
    }
}

struct StationRow: View {
    let station: Station
    var onStationDeleted: (() -> Void)?
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: price)) ?? ""
    }
    
    var body: some View {
        NavigationLink(destination: StationDetailView(station: station, onStationDeleted: onStationDeleted)) {
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
                                    Text(formatPrice(price))
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
    @StateObject private var firebaseManager = FirebaseManager.shared
    var onStationAdded: (() -> Void)?
    
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var selectedFuelTypes: Set<String> = []
    @State private var regularPrice: String = ""
    @State private var premiumPrice: String = ""
    @State private var dieselPrice: String = ""
    @State private var e85Price: String = ""
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    private let availableFuelTypes = ["Regular", "Premium", "Diesel", "E85"]
    
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
    
    private func addStation() {
        var prices: [String: Double] = [:]
        
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
        
        print("🔍 Creating new station with prices: \(prices)")
        print("🔍 Selected fuel types: \(Array(selectedFuelTypes))")
        print("🔍 Price field values:")
        print("   - Regular: '\(regularPrice)' -> \(Double(regularPrice) ?? 0)")
        print("   - Premium: '\(premiumPrice)' -> \(Double(premiumPrice) ?? 0)")
        print("   - Diesel: '\(dieselPrice)' -> \(Double(dieselPrice) ?? 0)")
        print("   - E85: '\(e85Price)' -> \(Double(e85Price) ?? 0)")
        
        let newStation = Station(
            name: name,
            address: address,
            fuelTypes: Array(selectedFuelTypes),
            currentPrices: prices,
            rating: 0.0,
            distance: 0.0,
            isFavorite: false,
            image: selectedImage
        )
        
        // Save to Firebase
        firebaseManager.saveStation(newStation) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stationId):
                    // Upload image if selected
                    if let image = selectedImage {
                        firebaseManager.uploadStationImage(image, stationId: stationId) { imageResult in
                            DispatchQueue.main.async {
                                switch imageResult {
                                case .success(_):
                                    print("✅ Station and image saved successfully")
                                case .failure(let error):
                                    print("❌ Failed to upload image: \(error.localizedDescription)")
                                }
                                // Add to local array and dismiss
                                stations.append(newStation)
                                onStationAdded?()
                                dismiss()
                            }
                        }
                    } else {
                        // Add to local array and dismiss
                        stations.append(newStation)
                        onStationAdded?()
                        dismiss()
                    }
                case .failure(let error):
                    print("❌ Failed to save station: \(error.localizedDescription)")
                    // You could show an error alert here
                }
            }
        }
    }
}

#Preview {
    StationsView()
}

// MARK: - Array Extension for Batching

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
} 