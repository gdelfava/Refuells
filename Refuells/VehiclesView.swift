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
    @State private var vehicleImage: UIImage?
    @State private var isLoadingImage = false
    
    var body: some View {
        HStack(spacing: 12) {
            if let vehicleImage = vehicleImage {
                Image(uiImage: vehicleImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if isLoadingImage {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
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
        .onAppear {
            loadVehicleImage()
        }
    }
    
    private func loadVehicleImage() {
        guard let imageURL = vehicle.imageURL, vehicleImage == nil else { return }
        
        isLoadingImage = true
        Task {
            do {
                let image = try await vehicleService.downloadVehicleImage(from: imageURL)
                await MainActor.run {
                    vehicleImage = image
                    isLoadingImage = false
                }
            } catch {
                print("Failed to load vehicle image: \(error.localizedDescription)")
                await MainActor.run {
                    isLoadingImage = false
                }
            }
        }
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
        
        Task {
            var imageURL: String?
            
            if let vehicleImage = vehicleImage {
                do {
                    // Create a temporary vehicle to get an ID for the image path
                    let tempVehicle = Vehicle(
                        name: name,
                        make: make,
                        model: model,
                        year: year,
                        fuelType: fuelType,
                        tankCapacity: capacity
                    )
                    
                    // Add the vehicle first to get an ID
                    vehicleService.addVehicle(tempVehicle)
                    
                    // Wait a moment for the ID to be assigned
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    
                    // Find the vehicle we just added to get its ID
                    if let addedVehicle = vehicleService.vehicles.first(where: { 
                        $0.name == name && $0.make == make && $0.model == model 
                    }) {
                        // Upload the image
                        imageURL = try await vehicleService.uploadVehicleImage(vehicleImage, for: addedVehicle.id!)
                        
                        // Update the vehicle with the image URL
                        let updatedVehicle = addedVehicle.updated(
                            name: name,
                            make: make,
                            model: model,
                            year: year,
                            fuelType: fuelType,
                            tankCapacity: capacity,
                            imageURL: imageURL
                        )
                        
                        vehicleService.updateVehicle(updatedVehicle)
                    }
                } catch {
                    print("Failed to upload image: \(error.localizedDescription)")
                    // Still create the vehicle without image
                    let vehicle = Vehicle(
                        name: name,
                        make: make,
                        model: model,
                        year: year,
                        fuelType: fuelType,
                        tankCapacity: capacity
                    )
                    vehicleService.addVehicle(vehicle)
                }
            } else {
                // No image selected
                let vehicle = Vehicle(
                    name: name,
                    make: make,
                    model: model,
                    year: year,
                    fuelType: fuelType,
                    tankCapacity: capacity
                )
                vehicleService.addVehicle(vehicle)
            }
            
            await MainActor.run {
                dismiss()
            }
        }
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
                    VehicleDetailImageView(vehicle: vehicle, vehicleService: vehicleService)
                    
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

struct VehicleDetailImageView: View {
    let vehicle: Vehicle
    let vehicleService: VehicleService
    @State private var vehicleImage: UIImage?
    @State private var isLoadingImage = false
    
    var body: some View {
        Group {
            if let vehicleImage = vehicleImage {
                Image(uiImage: vehicleImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else if isLoadingImage {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 250)
                    .overlay(
                        ProgressView("Loading image...")
                            .foregroundColor(.gray)
                    )
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
        }
        .onAppear {
            loadVehicleImage()
        }
    }
    
    private func loadVehicleImage() {
        guard let imageURL = vehicle.imageURL, vehicleImage == nil else { return }
        isLoadingImage = true
        Task {
            do {
                let image = try await vehicleService.downloadVehicleImage(from: imageURL)
                await MainActor.run {
                    vehicleImage = image
                    isLoadingImage = false
                }
            } catch {
                print("Failed to load vehicle image: \(error.localizedDescription)")
                await MainActor.run {
                    isLoadingImage = false
                }
            }
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
                    Task {
                        do {
                            let image = try await vehicleService.downloadVehicleImage(from: imageURL)
                            await MainActor.run {
                                vehicleImage = image
                            }
                        } catch {
                            print("Failed to load existing vehicle image: \(error.localizedDescription)")
                        }
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
        
        Task {
            var imageURL: String? = vehicle.imageURL // Keep existing URL if no new image
            
            if let vehicleImage = vehicleImage {
                // Check if this is a new image (not the same as existing)
                let isNewImage = true // For simplicity, always treat as new image
                
                if isNewImage {
                    do {
                        // Upload the new image
                        imageURL = try await vehicleService.uploadVehicleImage(vehicleImage, for: vehicle.id!)
                        print("✅ New image uploaded successfully")
                    } catch {
                        print("❌ Failed to upload new image: \(error.localizedDescription)")
                        // Keep the existing image URL if upload fails
                        imageURL = vehicle.imageURL
                    }
                }
            }
            
            // Create updated vehicle using the Vehicle's updated method
            let updatedVehicle = vehicle.updated(
                name: name,
                make: make,
                model: model,
                year: year,
                fuelType: fuelType,
                tankCapacity: capacity,
                imageURL: imageURL
            )
            
            vehicleService.updateVehicle(updatedVehicle)
            
            await MainActor.run {
                dismiss()
            }
        }
    }
}

#Preview {
    VehiclesView()
} 