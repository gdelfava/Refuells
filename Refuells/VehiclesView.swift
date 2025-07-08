import SwiftUI
import PhotosUI

struct VehiclesView: View {
    @StateObject private var vehicleService = VehicleService()
    @State private var showingAddVehicle = false
    @State private var selectedVehicle: Vehicle?
    
    var body: some View {
        NavigationView {
            ZStack {
                if vehicleService.isLoading {
                    ProgressView("Loading vehicles...")
                } else if vehicleService.vehicles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Vehicles")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Add your first vehicle to start tracking fuel consumption")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Add Vehicle") {
                            showingAddVehicle = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(vehicleService.vehicles) { vehicle in
                            VehicleRowView(vehicle: vehicle, vehicleService: vehicleService)
                                .onTapGesture {
                                    selectedVehicle = vehicle
                                }
                        }
                        .onDelete(perform: deleteVehicles)
                    }
                }
            }
            .navigationTitle("Vehicles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddVehicle = true
                    }
                }
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView(vehicleService: vehicleService)
            }
            .sheet(item: $selectedVehicle) { vehicle in
                VehicleDetailView(vehicle: vehicle, vehicleService: vehicleService)
            }
            .alert("Error", isPresented: .constant(vehicleService.errorMessage != nil)) {
                Button("OK") {
                    vehicleService.errorMessage = nil
                }
            } message: {
                Text(vehicleService.errorMessage ?? "")
            }
        }
    }
    
    private func deleteVehicles(offsets: IndexSet) {
        for index in offsets {
            let vehicle = vehicleService.vehicles[index]
            vehicleService.deleteVehicle(vehicle)
        }
    }
}

struct VehicleRowView: View {
    let vehicle: Vehicle
    let vehicleService: VehicleService
    
    var body: some View {
        HStack(spacing: 12) {
            if let imageURL = vehicle.imageURL {
                AsyncImageView(url: imageURL, placeholder: "car.fill", contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "car.fill")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.name)
                    .font(.headline)
                
                Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(vehicle.fuelType)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(vehicle.tankCapacity))L")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddVehicleView: View {
    @ObservedObject var vehicleService: VehicleService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var fuelType = "Petrol"
    @State private var tankCapacity = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var vehicleImage: UIImage?
    
    private let fuelTypes = ["Petrol", "Diesel", "Electric", "Hybrid", "LPG"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Vehicle Information") {
                    TextField("Vehicle Name", text: $name)
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    
                    Stepper("Year: \(year)", value: $year, in: 1900...Calendar.current.component(.year, from: Date()))
                    
                    Picker("Fuel Type", selection: $fuelType) {
                        ForEach(fuelTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    TextField("Tank Capacity (L)", text: $tankCapacity)
                        .keyboardType(.decimalPad)
                }
                
                Section("Vehicle Image") {
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        if let vehicleImage = vehicleImage {
                            Image(uiImage: vehicleImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            HStack {
                                Image(systemName: "photo")
                                Text("Select Image")
                            }
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVehicle()
                    }
                    .disabled(name.isEmpty || make.isEmpty || model.isEmpty || tankCapacity.isEmpty)
                }
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        vehicleImage = image
                    }
                }
            }
        }
    }
    
    private func saveVehicle() {
        guard let capacity = Double(tankCapacity) else { return }
        
        // Create vehicle first without image URL
        let vehicle = Vehicle(
            name: name,
            make: make,
            model: model,
            year: year,
            fuelType: fuelType,
            tankCapacity: capacity,
            imageURL: nil
        )
        
        // Add vehicle to get the ID
        vehicleService.addVehicle(vehicle) { vehicleId in
            guard let vehicleId = vehicleId else { return }
            
            // Upload image if selected
            if let vehicleImage = self.vehicleImage {
                self.vehicleService.uploadVehicleImage(vehicleImage, vehicleId: vehicleId) { result in
                    switch result {
                    case .success(let imageURL):
                        // Update vehicle with image URL
                        let updatedVehicle = vehicle.updated(
                            name: vehicle.name,
                            make: vehicle.make,
                            model: vehicle.model,
                            year: vehicle.year,
                            fuelType: vehicle.fuelType,
                            tankCapacity: vehicle.tankCapacity,
                            imageURL: imageURL
                        )
                        self.vehicleService.updateVehicle(updatedVehicle)
                    case .failure(let error):
                        print("Failed to upload image: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        dismiss()
    }
}

struct VehicleDetailView: View {
    let vehicle: Vehicle
    @ObservedObject var vehicleService: VehicleService
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditVehicle = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let imageURL = vehicle.imageURL {
                        AsyncImageView(url: imageURL, placeholder: "car.fill", contentMode: .fill)
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 250)
                            .overlay(
                                Image(systemName: "car.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(title: "Name", value: vehicle.name)
                        DetailRow(title: "Make", value: vehicle.make)
                        DetailRow(title: "Model", value: vehicle.model)
                        DetailRow(title: "Year", value: "\(vehicle.year)")
                        DetailRow(title: "Fuel Type", value: vehicle.fuelType)
                        DetailRow(title: "Tank Capacity", value: "\(Int(vehicle.tankCapacity))L")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 2)
                }
                .padding()
            }
            .navigationTitle(vehicle.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditVehicle = true
                    }
                }
            }
            .sheet(isPresented: $showingEditVehicle) {
                EditVehicleView(vehicle: vehicle, vehicleService: vehicleService)
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct EditVehicleView: View {
    let vehicle: Vehicle
    @ObservedObject var vehicleService: VehicleService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var fuelType = "Petrol"
    @State private var tankCapacity = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var vehicleImage: UIImage?
    
    private let fuelTypes = ["Petrol", "Diesel", "Electric", "Hybrid", "LPG"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Vehicle Information") {
                    TextField("Vehicle Name", text: $name)
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    
                    Stepper("Year: \(year)", value: $year, in: 1900...Calendar.current.component(.year, from: Date()))
                    
                    Picker("Fuel Type", selection: $fuelType) {
                        ForEach(fuelTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    TextField("Tank Capacity (L)", text: $tankCapacity)
                        .keyboardType(.decimalPad)
                }
                
                Section("Vehicle Image") {
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        if let vehicleImage = vehicleImage {
                            Image(uiImage: vehicleImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            HStack {
                                Image(systemName: "photo")
                                Text("Select Image")
                            }
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVehicle()
                    }
                    .disabled(name.isEmpty || make.isEmpty || model.isEmpty || tankCapacity.isEmpty)
                }
            }
            .onAppear {
                // Initialize form fields with existing vehicle data
                name = vehicle.name
                make = vehicle.make
                model = vehicle.model
                year = vehicle.year
                fuelType = vehicle.fuelType
                tankCapacity = String(Int(vehicle.tankCapacity))
                
                // Load existing image if available
                if let imageURL = vehicle.imageURL {
                    vehicleService.loadImageFromURL(imageURL) { image in
                        vehicleImage = image
                    }
                }
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        vehicleImage = image
                    }
                }
            }
        }
    }
    
    private func saveVehicle() {
        guard let capacity = Double(tankCapacity) else { return }
        
        // If a new image was selected, upload it first
        if let vehicleImage = vehicleImage {
            guard let vehicleId = vehicle.id else { return }
            
            vehicleService.uploadVehicleImage(vehicleImage, vehicleId: vehicleId) { result in
                switch result {
                case .success(let imageURL):
                    // Update vehicle with new image URL
                    let updatedVehicle = self.vehicle.updated(
                        name: self.name,
                        make: self.make,
                        model: self.model,
                        year: self.year,
                        fuelType: self.fuelType,
                        tankCapacity: capacity,
                        imageURL: imageURL
                    )
                    self.vehicleService.updateVehicle(updatedVehicle)
                    self.dismiss()
                case .failure(let error):
                    print("Failed to upload image: \(error.localizedDescription)")
                    // Update vehicle without image URL
                    let updatedVehicle = self.vehicle.updated(
                        name: self.name,
                        make: self.make,
                        model: self.model,
                        year: self.year,
                        fuelType: self.fuelType,
                        tankCapacity: capacity,
                        imageURL: self.vehicle.imageURL
                    )
                    self.vehicleService.updateVehicle(updatedVehicle)
                    self.dismiss()
                }
            }
        } else {
            // No new image selected, keep the original image URL
            let updatedVehicle = vehicle.updated(
                name: name,
                make: make,
                model: model,
                year: year,
                fuelType: fuelType,
                tankCapacity: capacity,
                imageURL: vehicle.imageURL
            )
            
            vehicleService.updateVehicle(updatedVehicle)
            dismiss()
        }
    }
}

#Preview {
    VehiclesView()
} 