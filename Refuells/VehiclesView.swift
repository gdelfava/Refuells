import SwiftUI

struct Vehicle: Identifiable, Codable {
    var id = UUID()
    var year: Int
    var imageName: String // Use asset name or URL
    var plate: String
    var vin: String
    var model: String
    var trim: String
    var manufacturer: String
    var bodyType: String
    var doors: String
    var enatisDocument: Data? = nil
    var enatisFileName: String = ""
    
    // Metrics fields
    var initialOdometer: String = "371km"
    var aaRatePerKm: String = "R1.75"
    var fuelType: String = "Petrol Unleaded 95"
    var manufacturerLPer100km: String = "6.70L/100km"
    
    // Wheels & Tyres fields
    var frontTyreSize: String = "225/60 R17"
    var rearTyreSize: String = "225/60 R17"
    var spareTyre: String = "Biscuit Size"
    
    // Payload fields
    var payload: String = "N/A"
    var tare: String = "1300kg"
    var gvm: String = "1684kg"
    
    // Dimensions fields
    var length: String = "4318mm"
    var width: String = "1831mm"
    var height: String = "1662mm"
    var wheelBase: String = "2610mm"
    var driveWheels: String = "Front"
    var groundClearance: String = "180mm"
    var bootCapacity: String = "1100"
    
    // Engine & Power fields
    var engineNumber: String = "SQRE4T15CDQRF00209"
    var engineSize: String = "1498 cc"
    var numberOfCylinders: String = "4"
    var power: String = "108 kW @ 5 500 rpm"
    var torque: String = "210 NM @ 4 000 rpm"
    
    // Finance fields
    var financeCompany: String = "Absa Bank"
    var financeAccountNumber: String = "00050043750"
    var financeContractDocument: Data? = nil
    var financeContractFileName: String = ""
    
    // Insurance fields
    var insuranceCompany: String = "Discovery Insure"
    var insurancePolicyNumber: String = "4003637528"
    var insurancePolicyDocument: Data? = nil
    var insurancePolicyFileName: String = ""
    
    // Service Plans fields
    var serviceInterval: String = "15000km"
    var servicePlan: String = "5 years/ 60,000km"
    var maintenancePlan: String = "60 mo"
    var warrantyPeriod: String = "5 years/ 150,000km"
    var engineWarranty: String = "10 years/ 1 Million km"
    var roadsideAssistance: String = "5 years/ Unlimited km"
    
    // Firestore document ID
    var documentId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, year, imageName, plate, vin, model, trim, manufacturer, bodyType, doors
        case enatisDocument, enatisFileName
        case initialOdometer, aaRatePerKm, fuelType, manufacturerLPer100km
        case frontTyreSize, rearTyreSize, spareTyre
        case payload, tare, gvm
        case length, width, height, wheelBase, driveWheels, groundClearance, bootCapacity
        case engineNumber, engineSize, numberOfCylinders, power, torque
        case financeCompany, financeAccountNumber, financeContractDocument, financeContractFileName
        case insuranceCompany, insurancePolicyNumber, insurancePolicyDocument, insurancePolicyFileName
        case serviceInterval, servicePlan, maintenancePlan, warrantyPeriod, engineWarranty, roadsideAssistance
        case documentId
    }
}

struct VehiclesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vehicleService = VehicleService()
    @State private var showingAddVehicle = false
    @State private var showingError = false
    
    var groupedVehicles: [Int: [Vehicle]] {
        Dictionary(grouping: vehicleService.vehicles, by: { $0.year })
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if vehicleService.isLoading {
                    ProgressView("Loading vehicles...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vehicleService.vehicles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Vehicles")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Add your first vehicle to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Add Vehicle") {
                            showingAddVehicle = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(groupedVehicles.keys.sorted(by: >), id: \.self) { year in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("\(year)")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.leading, 8)
                                    ForEach(groupedVehicles[year] ?? []) { vehicle in
                                        if let index = vehicleService.vehicles.firstIndex(where: { $0.id == vehicle.id }) {
                                            NavigationLink(destination: VehicleDetailView(vehicle: $vehicleService.vehicles[index], vehicleService: vehicleService)) {
                                                VehicleCard(vehicle: vehicle)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 8)
                    }
                }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Vehicles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddVehicle = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(vehicleService.errorMessage ?? "An error occurred")
        }
        .onReceive(vehicleService.$errorMessage) { errorMessage in
            showingError = errorMessage != nil
        }
        .sheet(isPresented: $showingAddVehicle) {
            AddVehicleView(vehicleService: vehicleService)
        }
    }
}

struct VehicleCard: View {
    let vehicle: Vehicle
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Vehicle image
            Image(vehicle.imageName)
                .resizable()
                .aspectRatio(16/9, contentMode: .fill)
                .frame(height: 180)
                .clipped()
                .cornerRadius(16)
                .padding(.top, 8)
                .accessibilityHidden(true) // Hide image from VoiceOver since it's decorative
            
            // Plate / VIN
            if !vehicle.plate.isEmpty || !vehicle.vin.isEmpty {
                Text("\(vehicle.plate.uppercased()) / \(vehicle.vin.uppercased())")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.orange)
                    .padding(.top, 2)
                    .accessibilityLabel("Vehicle identification")
                    .accessibilityValue("\(vehicle.plate.isEmpty ? "" : "Plate \(vehicle.plate.uppercased())") \(vehicle.vin.isEmpty ? "" : "VIN \(vehicle.vin.uppercased())")")
            }
            
            // Model
            Text(vehicle.model)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .accessibilityLabel("Model")
                .accessibilityValue(vehicle.model)
            
            // Trim
            Text(vehicle.trim)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .accessibilityLabel("Trim")
                .accessibilityValue(vehicle.trim)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(.systemGray5), lineWidth: 3)
        )
        .shadow(color: Color(.black).opacity(0.07), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Vehicle Card")
        .accessibilityValue("\(vehicle.model), \(vehicle.trim)")
        .accessibilityHint("Double tap to view vehicle details")
    }
}

struct VehicleDetailView: View {
    @Binding var vehicle: Vehicle
    @Environment(\.dismiss) private var dismiss
    let vehicleService: VehicleService
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Main vehicle image
                    Image(vehicle.imageName)
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    // Model and trim (keep this below the image)
                    VStack(spacing: 2) {
                        Text(vehicle.model)
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        Text(vehicle.trim)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    // Summary cards (horizontal scroll)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            SummaryCard(title: "Total Distance", value: "9157km")
                            SummaryCard(title: "Total Fuel Purchased", value: "925L")
                            SummaryCard(title: "Total Fuel Spend", value: "R19474.74")
                            SummaryCard(title: "Vehicle Range", value: "761km")
                        }
                        .padding(.horizontal)
                    }
                    // Info sections
                    VStack(spacing: 16) {
                        VehicleSection(
                            title: "Basic Details",
                            editable: true,
                            content: {
                                VehicleRow(label: "Manufacturer", value: vehicle.manufacturer)
                                VehicleRow(label: "Year", value: "\(vehicle.year)")
                                VehicleRow(label: "Licence Plate", value: vehicle.plate)
                                VehicleRow(label: "Body Type", value: vehicle.bodyType)
                                VehicleRow(label: "Doors", value: vehicle.doors)
                                
                                // eNATIS Registration display
                                HStack(alignment: .center, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("eNATIS Registration")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        HStack(spacing: 4) {
                                            if let _ = vehicle.enatisDocument {
                                                Text(vehicle.enatisFileName.isEmpty ? "eNATIS Document" : vehicle.enatisFileName)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.primary)
                                                Image(systemName: "doc.fill")
                                                    .foregroundColor(.blue)
                                            } else {
                                                Text("Upload eNATIS Document")
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.orange)
                                                Image(systemName: "plus.circle")
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            },
                            vehicle: vehicle,
                            onUpdate: { updatedVehicle in
                                vehicle = updatedVehicle
                                saveVehicleToFirestore(updatedVehicle)
                            },
                            vehicleService: vehicleService
                        )
                        
                        VehicleSection(
                            title: "Metrics",
                            editable: true,
                            content: {
                                VehicleRow(label: "Initial Odometer", value: vehicle.initialOdometer)
                                VehicleRow(label: "AA Rate /km", value: vehicle.aaRatePerKm)
                                VehicleRow(label: "Fuel Type", value: vehicle.fuelType)
                                VehicleRow(label: "Manufacturer L/100km", value: vehicle.manufacturerLPer100km)
                            },
                            vehicle: vehicle,
                            onUpdate: { updatedVehicle in
                                vehicle = updatedVehicle
                                saveVehicleToFirestore(updatedVehicle)
                            },
                            vehicleService: vehicleService
                        )
                        
                        VehicleSection(
                            title: "Wheels & Tyres",
                            editable: true,
                            content: {
                                VehicleRow(label: "Tyre Size (Front)", value: vehicle.frontTyreSize)
                                VehicleRow(label: "Tyre Size (Rear)", value: vehicle.rearTyreSize)
                                VehicleRow(label: "Spare Tyre", value: vehicle.spareTyre)
                            },
                            vehicle: vehicle,
                            onUpdate: { updatedVehicle in
                                vehicle = updatedVehicle
                                saveVehicleToFirestore(updatedVehicle)
                            },
                            vehicleService: vehicleService
                        )
                        
                        VehicleSection(
                            title: "Payload",
                            editable: true,
                            content: {
                                VehicleRow(label: "Payload", value: vehicle.payload)
                                VehicleRow(label: "Tare", value: vehicle.tare)
                                VehicleRow(label: "GVM", value: vehicle.gvm)
                            },
                            vehicle: vehicle,
                            onUpdate: { updatedVehicle in
                                vehicle = updatedVehicle
                                saveVehicleToFirestore(updatedVehicle)
                            },
                            vehicleService: vehicleService
                        )
                        
                        VehicleSection(
                            title: "Dimensions",
                            editable: true,
                            content: {
                                VehicleRow(label: "Length", value: vehicle.length)
                                VehicleRow(label: "Width", value: vehicle.width)
                                VehicleRow(label: "Height", value: vehicle.height)
                                VehicleRow(label: "Wheel Base", value: vehicle.wheelBase)
                                VehicleRow(label: "Drive Wheels", value: vehicle.driveWheels)
                                VehicleRow(label: "Ground Clearance", value: vehicle.groundClearance)
                                VehicleRow(label: "Boot Capacity", value: vehicle.bootCapacity)
                            },
                            vehicle: vehicle,
                            onUpdate: { updatedVehicle in
                                vehicle = updatedVehicle
                                saveVehicleToFirestore(updatedVehicle)
                            },
                            vehicleService: vehicleService
                        )
                        
                        VehicleSection(
                            title: "Engine & Power",
                            editable: true,
                            content: {
                                VehicleRow(label: "Engine Number", value: vehicle.engineNumber)
                                VehicleRow(label: "Engine Size", value: vehicle.engineSize)
                                VehicleRow(label: "Number of Cylinders", value: vehicle.numberOfCylinders)
                                VehicleRow(label: "Power", value: vehicle.power)
                                VehicleRow(label: "Torque", value: vehicle.torque)
                            },
                            vehicle: vehicle,
                            onUpdate: { updatedVehicle in
                                vehicle = updatedVehicle
                                saveVehicleToFirestore(updatedVehicle)
                            },
                            vehicleService: vehicleService
                        )
                        
                        VehicleSection(
                            title: "Finance",
                            editable: true,
                            content: {
                                VehicleRow(label: "Finance Company", value: vehicle.financeCompany)
                                VehicleRow(label: "Finance Acc #", value: vehicle.financeAccountNumber)
                                
                                // Finance Contract display
                                HStack(alignment: .center, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Finance Contract")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        HStack(spacing: 4) {
                                            if let _ = vehicle.financeContractDocument {
                                                Text(vehicle.financeContractFileName.isEmpty ? "Finance Contract" : vehicle.financeContractFileName)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.primary)
                                                Image(systemName: "doc.fill")
                                                    .foregroundColor(.blue)
                                            } else {
                                                Text("Upload Finance Contract")
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.orange)
                                                Image(systemName: "plus.circle")
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            },
                            vehicle: vehicle,
                            onUpdate: { updatedVehicle in
                                vehicle = updatedVehicle
                                saveVehicleToFirestore(updatedVehicle)
                            },
                            vehicleService: vehicleService
                        )
                        
                        VehicleSection(
                            title: "Insurance",
                            editable: true,
                            content: {
                                VehicleRow(label: "Insurance Company", value: vehicle.insuranceCompany)
                                VehicleRow(label: "Insurance Policy Number", value: vehicle.insurancePolicyNumber)
                                
                                // Insurance Policy display
                                HStack(alignment: .center, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Insurance Policy")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        HStack(spacing: 4) {
                                            if let _ = vehicle.insurancePolicyDocument {
                                                Text(vehicle.insurancePolicyFileName.isEmpty ? "Insurance Policy" : vehicle.insurancePolicyFileName)
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.primary)
                                                Image(systemName: "doc.fill")
                                                    .foregroundColor(.blue)
                                            } else {
                                                Text("Upload Insurance Policy")
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.orange)
                                                Image(systemName: "plus.circle")
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            },
                            vehicle: vehicle,
                            onUpdate: { updatedVehicle in
                                vehicle = updatedVehicle
                                saveVehicleToFirestore(updatedVehicle)
                            },
                            vehicleService: vehicleService
                        )
                        
                        VehicleSection(
                            title: "Service Plans",
                            editable: true,
                            content: {
                                VehicleRow(label: "Service Interval", value: vehicle.serviceInterval)
                                VehicleRow(label: "Service Plan", value: vehicle.servicePlan)
                                VehicleRow(label: "Maintenance Plan", value: vehicle.maintenancePlan)
                                VehicleRow(label: "Warranty Period", value: vehicle.warrantyPeriod)
                                VehicleRow(label: "Engine Warranty", value: vehicle.engineWarranty)
                                VehicleRow(label: "Roadside Assistance", value: vehicle.roadsideAssistance)
                            },
                            vehicle: vehicle,
                            onUpdate: { updatedVehicle in
                                vehicle = updatedVehicle
                                saveVehicleToFirestore(updatedVehicle)
                            },
                            vehicleService: vehicleService
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveVehicleToFirestore(_ updatedVehicle: Vehicle) {
        vehicleService.updateVehicle(updatedVehicle) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Vehicle updated successfully
                    break
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 2)
        )
    }
}

struct VehicleSection<Content: View>: View {
    let title: String
    let editable: Bool
    @State private var isEditing = false
    let content: Content
    var vehicle: Vehicle? = nil
    var onUpdate: ((Vehicle) -> Void)? = nil
    var vehicleService: VehicleService? = nil
    
    init(
        title: String,
        editable: Bool = false,
        @ViewBuilder content: () -> Content,
        vehicle: Vehicle? = nil,
        onUpdate: ((Vehicle) -> Void)? = nil,
        vehicleService: VehicleService? = nil
    ) {
        self.title = title
        self.editable = editable
        self.content = content()
        self.vehicle = vehicle
        self.onUpdate = onUpdate
        self.vehicleService = vehicleService
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.black)
                Spacer()
                if editable {
                    Button(action: { isEditing = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(16)
                    }
                    .accessibilityLabel("Edit \(title)")
                    .accessibilityHint("Double tap to edit \(title) details")
                }
            }
            .padding(.bottom, 8)
            VStack(spacing: 0) {
                content
            }
            .padding(.bottom, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray5), lineWidth: 2)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title) Section")
        .sheet(isPresented: $isEditing) {
            if title == "Basic Details", let vehicle = vehicle, let vehicleService = vehicleService {
                EditBasicDetailsView(vehicle: vehicle, onSave: { updatedVehicle in
                    onUpdate?(updatedVehicle)
                    isEditing = false
                }, vehicleService: vehicleService)
            } else if title == "Metrics", let vehicle = vehicle {
                EditMetricsView(vehicle: vehicle, onSave: { updatedVehicle in
                    onUpdate?(updatedVehicle)
                    isEditing = false
                })
            } else if title == "Wheels & Tyres", let vehicle = vehicle {
                EditWheelsTyresView(vehicle: vehicle, onSave: { updatedVehicle in
                    onUpdate?(updatedVehicle)
                    isEditing = false
                })
            } else if title == "Payload", let vehicle = vehicle {
                EditPayloadView(vehicle: vehicle, onSave: { updatedVehicle in
                    onUpdate?(updatedVehicle)
                    isEditing = false
                })
            } else if title == "Dimensions", let vehicle = vehicle {
                EditDimensionsView(vehicle: vehicle, onSave: { updatedVehicle in
                    onUpdate?(updatedVehicle)
                    isEditing = false
                })
            } else if title == "Engine & Power", let vehicle = vehicle {
                EditEnginePowerView(vehicle: vehicle, onSave: { updatedVehicle in
                    onUpdate?(updatedVehicle)
                    isEditing = false
                })
            } else if title == "Finance", let vehicle = vehicle, let vehicleService = vehicleService {
                EditFinanceView(vehicle: vehicle, onSave: { updatedVehicle in
                    onUpdate?(updatedVehicle)
                    isEditing = false
                }, vehicleService: vehicleService)
            } else if title == "Insurance", let vehicle = vehicle, let vehicleService = vehicleService {
                EditInsuranceView(vehicle: vehicle, onSave: { updatedVehicle in
                    onUpdate?(updatedVehicle)
                    isEditing = false
                }, vehicleService: vehicleService)
            } else if title == "Service Plans", let vehicle = vehicle {
                EditServicePlansView(vehicle: vehicle, onSave: { updatedVehicle in
                    onUpdate?(updatedVehicle)
                    isEditing = false
                })
            }
        }
    }
}

struct EditBasicDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle
    let onSave: (Vehicle) -> Void
    let vehicleService: VehicleService
    
    @State private var manufacturer: String
    @State private var year: String
    @State private var plate: String
    @State private var bodyType: String
    @State private var doors: String
    @State private var showingFilePicker = false
    @State private var enatisDocument: Data? = nil
    @State private var enatisFileName: String = ""
    @State private var isUploading = false
    
    init(vehicle: Vehicle, onSave: @escaping (Vehicle) -> Void, vehicleService: VehicleService) {
        self.vehicle = vehicle
        self.onSave = onSave
        self.vehicleService = vehicleService
        _manufacturer = State(initialValue: vehicle.manufacturer)
        _year = State(initialValue: String(vehicle.year))
        _plate = State(initialValue: vehicle.plate)
        _bodyType = State(initialValue: vehicle.bodyType)
        _doors = State(initialValue: vehicle.doors)
        _enatisDocument = State(initialValue: vehicle.enatisDocument)
        _enatisFileName = State(initialValue: vehicle.enatisFileName)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Details") {
                    HStack {
                        Text("Manufacturer")
                        Spacer()
                        TextField("Manufacturer", text: $manufacturer)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Year")
                        Spacer()
                        TextField("Year", text: $year)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Licence Plate")
                        Spacer()
                        TextField("Plate", text: $plate)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Body Type")
                        Spacer()
                        TextField("Body Type", text: $bodyType)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Doors")
                        Spacer()
                        TextField("Doors", text: $doors)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("eNATIS Registration") {
                    if let _ = enatisDocument {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                            Text(enatisFileName.isEmpty ? "eNATIS Document" : enatisFileName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Remove") {
                                enatisDocument = nil
                                enatisFileName = ""
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button(action: { showingFilePicker = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.orange)
                                Text("Upload eNATIS Document")
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Edit Basic Details")
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
                    .disabled(isUploading)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let files):
                    if let file = files.first {
                        do {
                            let data = try Data(contentsOf: file)
                            enatisDocument = data
                            enatisFileName = file.lastPathComponent
                        } catch {
                            print("Error reading file: \(error)")
                        }
                    }
                case .failure(let error):
                    print("Error selecting file: \(error)")
                }
            }
        }
    }
    
    private func saveVehicle() {
        isUploading = true
        
        var updatedVehicle = vehicle
        updatedVehicle.manufacturer = manufacturer
        updatedVehicle.year = Int(year) ?? vehicle.year
        updatedVehicle.plate = plate
        updatedVehicle.bodyType = bodyType
        updatedVehicle.doors = doors
        updatedVehicle.enatisDocument = enatisDocument
        updatedVehicle.enatisFileName = enatisFileName
        
        // Upload file to Firebase Storage if document exists
        if let documentData = enatisDocument, !enatisFileName.isEmpty {
            vehicleService.uploadFile(documentData, fileName: enatisFileName, vehicleId: vehicle.id.uuidString) { result in
                DispatchQueue.main.async {
                    isUploading = false
                    switch result {
                    case .success:
                        onSave(updatedVehicle)
                        dismiss()
                    case .failure(let error):
                        print("Error uploading file: \(error)")
                        // Still save the vehicle even if file upload fails
                        onSave(updatedVehicle)
                        dismiss()
                    }
                }
            }
        } else {
            isUploading = false
            onSave(updatedVehicle)
            dismiss()
        }
    }
}

struct EditMetricsView: View {
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle
    let onSave: (Vehicle) -> Void
    
    @State private var initialOdometer: String
    @State private var aaRatePerKm: String
    @State private var fuelType: String
    @State private var manufacturerLPer100km: String
    
    init(vehicle: Vehicle, onSave: @escaping (Vehicle) -> Void) {
        self.vehicle = vehicle
        self.onSave = onSave
        _initialOdometer = State(initialValue: vehicle.initialOdometer)
        _aaRatePerKm = State(initialValue: vehicle.aaRatePerKm)
        _fuelType = State(initialValue: vehicle.fuelType)
        _manufacturerLPer100km = State(initialValue: vehicle.manufacturerLPer100km)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Metrics") {
                    HStack {
                        Text("Initial Odometer")
                        Spacer()
                        TextField("371km", text: $initialOdometer)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Initial Odometer")
                            .accessibilityHint("Enter the initial odometer reading, for example 371km")
                    }
                    
                    HStack {
                        Text("AA Rate /km")
                        Spacer()
                        TextField("R1.75", text: $aaRatePerKm)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("AA Rate per kilometer")
                            .accessibilityHint("Enter the AA rate per kilometer, for example R1.75")
                    }
                    
                    HStack {
                        Text("Fuel Type")
                        Spacer()
                        TextField("Petrol Unleaded 95", text: $fuelType)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Fuel Type")
                            .accessibilityHint("Enter the fuel type, for example Petrol Unleaded 95")
                    }
                    
                    HStack {
                        Text("Manufacturer L/100km")
                        Spacer()
                        TextField("6.70L/100km", text: $manufacturerLPer100km)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Manufacturer Liters per 100 kilometers")
                            .accessibilityHint("Enter the manufacturer's fuel consumption rating, for example 6.70L/100km")
                    }
                }
            }
            .navigationTitle("Edit Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel editing metrics")
                    .accessibilityHint("Discard changes and return to vehicle details")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedVehicle = vehicle
                        updatedVehicle.initialOdometer = initialOdometer
                        updatedVehicle.aaRatePerKm = aaRatePerKm
                        updatedVehicle.fuelType = fuelType
                        updatedVehicle.manufacturerLPer100km = manufacturerLPer100km
                        onSave(updatedVehicle)
                        dismiss()
                    }
                    .accessibilityLabel("Save metrics")
                    .accessibilityHint("Save changes and return to vehicle details")
                }
            }
        }
    }
}

struct EditWheelsTyresView: View {
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle
    let onSave: (Vehicle) -> Void
    
    @State private var frontTyreSize: String
    @State private var rearTyreSize: String
    @State private var spareTyre: String
    
    init(vehicle: Vehicle, onSave: @escaping (Vehicle) -> Void) {
        self.vehicle = vehicle
        self.onSave = onSave
        _frontTyreSize = State(initialValue: vehicle.frontTyreSize)
        _rearTyreSize = State(initialValue: vehicle.rearTyreSize)
        _spareTyre = State(initialValue: vehicle.spareTyre)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Wheels & Tyres") {
                    HStack {
                        Text("Front Tyre Size")
                        Spacer()
                        TextField("225/60 R17", text: $frontTyreSize)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Front Tyre Size")
                            .accessibilityHint("Enter the front tyre size, for example 225/60 R17")
                    }
                    
                    HStack {
                        Text("Rear Tyre Size")
                        Spacer()
                        TextField("225/60 R17", text: $rearTyreSize)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Rear Tyre Size")
                            .accessibilityHint("Enter the rear tyre size, for example 225/60 R17")
                    }
                    
                    HStack {
                        Text("Spare Tyre")
                        Spacer()
                        TextField("Biscuit Size", text: $spareTyre)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Spare Tyre")
                            .accessibilityHint("Enter the spare tyre type, for example Biscuit Size")
                    }
                }
            }
            .navigationTitle("Edit Wheels & Tyres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel editing wheels and tyres")
                    .accessibilityHint("Discard changes and return to vehicle details")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedVehicle = vehicle
                        updatedVehicle.frontTyreSize = frontTyreSize
                        updatedVehicle.rearTyreSize = rearTyreSize
                        updatedVehicle.spareTyre = spareTyre
                        onSave(updatedVehicle)
                        dismiss()
                    }
                    .accessibilityLabel("Save wheels and tyres")
                    .accessibilityHint("Save changes and return to vehicle details")
                }
            }
        }
    }
}

struct EditPayloadView: View {
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle
    let onSave: (Vehicle) -> Void
    
    @State private var payload: String
    @State private var tare: String
    @State private var gvm: String
    
    init(vehicle: Vehicle, onSave: @escaping (Vehicle) -> Void) {
        self.vehicle = vehicle
        self.onSave = onSave
        _payload = State(initialValue: vehicle.payload)
        _tare = State(initialValue: vehicle.tare)
        _gvm = State(initialValue: vehicle.gvm)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Payload") {
                    HStack {
                        Text("Payload")
                        Spacer()
                        TextField("N/A", text: $payload)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Payload")
                            .accessibilityHint("Enter the payload capacity, for example N/A or 384kg")
                    }
                    
                    HStack {
                        Text("Tare")
                        Spacer()
                        TextField("1300kg", text: $tare)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Tare Weight")
                            .accessibilityHint("Enter the tare weight, for example 1300kg")
                    }
                    
                    HStack {
                        Text("GVM")
                        Spacer()
                        TextField("1684kg", text: $gvm)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Gross Vehicle Mass")
                            .accessibilityHint("Enter the gross vehicle mass, for example 1684kg")
                    }
                }
            }
            .navigationTitle("Edit Payload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel editing payload")
                    .accessibilityHint("Discard changes and return to vehicle details")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedVehicle = vehicle
                        updatedVehicle.payload = payload
                        updatedVehicle.tare = tare
                        updatedVehicle.gvm = gvm
                        onSave(updatedVehicle)
                        dismiss()
                    }
                    .accessibilityLabel("Save payload")
                    .accessibilityHint("Save changes and return to vehicle details")
                }
            }
        }
    }
}

struct EditDimensionsView: View {
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle
    let onSave: (Vehicle) -> Void
    
    @State private var length: String
    @State private var width: String
    @State private var height: String
    @State private var wheelBase: String
    @State private var driveWheels: String
    @State private var groundClearance: String
    @State private var bootCapacity: String
    
    init(vehicle: Vehicle, onSave: @escaping (Vehicle) -> Void) {
        self.vehicle = vehicle
        self.onSave = onSave
        _length = State(initialValue: vehicle.length)
        _width = State(initialValue: vehicle.width)
        _height = State(initialValue: vehicle.height)
        _wheelBase = State(initialValue: vehicle.wheelBase)
        _driveWheels = State(initialValue: vehicle.driveWheels)
        _groundClearance = State(initialValue: vehicle.groundClearance)
        _bootCapacity = State(initialValue: vehicle.bootCapacity)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Dimensions") {
                    HStack {
                        Text("Length")
                        Spacer()
                        TextField("4318mm", text: $length)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Length")
                            .accessibilityHint("Enter the vehicle length, for example 4318mm")
                    }
                    
                    HStack {
                        Text("Width")
                        Spacer()
                        TextField("1831mm", text: $width)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Width")
                            .accessibilityHint("Enter the vehicle width, for example 1831mm")
                    }
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("1662mm", text: $height)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Height")
                            .accessibilityHint("Enter the vehicle height, for example 1662mm")
                    }
                    
                    HStack {
                        Text("Wheel Base")
                        Spacer()
                        TextField("2610mm", text: $wheelBase)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Wheel Base")
                            .accessibilityHint("Enter the wheel base, for example 2610mm")
                    }
                    
                    HStack {
                        Text("Drive Wheels")
                        Spacer()
                        TextField("Front", text: $driveWheels)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Drive Wheels")
                            .accessibilityHint("Enter the drive wheels, for example Front")
                    }
                    
                    HStack {
                        Text("Ground Clearance")
                        Spacer()
                        TextField("180mm", text: $groundClearance)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Ground Clearance")
                            .accessibilityHint("Enter the ground clearance, for example 180mm")
                    }
                    
                    HStack {
                        Text("Boot Capacity")
                        Spacer()
                        TextField("1100", text: $bootCapacity)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Boot Capacity")
                            .accessibilityHint("Enter the boot capacity, for example 1100")
                    }
                }
            }
            .navigationTitle("Edit Dimensions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel editing dimensions")
                    .accessibilityHint("Discard changes and return to vehicle details")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedVehicle = vehicle
                        updatedVehicle.length = length
                        updatedVehicle.width = width
                        updatedVehicle.height = height
                        updatedVehicle.wheelBase = wheelBase
                        updatedVehicle.driveWheels = driveWheels
                        updatedVehicle.groundClearance = groundClearance
                        updatedVehicle.bootCapacity = bootCapacity
                        onSave(updatedVehicle)
                        dismiss()
                    }
                    .accessibilityLabel("Save dimensions")
                    .accessibilityHint("Save changes and return to vehicle details")
                }
            }
        }
    }
}

struct EditEnginePowerView: View {
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle
    let onSave: (Vehicle) -> Void
    
    @State private var engineNumber: String
    @State private var engineSize: String
    @State private var numberOfCylinders: String
    @State private var power: String
    @State private var torque: String
    
    init(vehicle: Vehicle, onSave: @escaping (Vehicle) -> Void) {
        self.vehicle = vehicle
        self.onSave = onSave
        _engineNumber = State(initialValue: vehicle.engineNumber)
        _engineSize = State(initialValue: vehicle.engineSize)
        _numberOfCylinders = State(initialValue: vehicle.numberOfCylinders)
        _power = State(initialValue: vehicle.power)
        _torque = State(initialValue: vehicle.torque)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Engine & Power") {
                    HStack {
                        Text("Engine Number")
                        Spacer()
                        TextField("SQRE4T15CDQRF00209", text: $engineNumber)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Engine Number")
                            .accessibilityHint("Enter the engine number")
                    }
                    
                    HStack {
                        Text("Engine Size")
                        Spacer()
                        TextField("1498 cc", text: $engineSize)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Engine Size")
                            .accessibilityHint("Enter the engine size, for example 1498 cc")
                    }
                    
                    HStack {
                        Text("Number of Cylinders")
                        Spacer()
                        TextField("4", text: $numberOfCylinders)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Number of Cylinders")
                            .accessibilityHint("Enter the number of cylinders, for example 4")
                    }
                    
                    HStack {
                        Text("Power")
                        Spacer()
                        TextField("108 kW @ 5 500 rpm", text: $power)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Power")
                            .accessibilityHint("Enter the power output, for example 108 kW @ 5 500 rpm")
                    }
                    
                    HStack {
                        Text("Torque")
                        Spacer()
                        TextField("210 NM @ 4 000 rpm", text: $torque)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Torque")
                            .accessibilityHint("Enter the torque output, for example 210 NM @ 4 000 rpm")
                    }
                }
            }
            .navigationTitle("Edit Engine & Power")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel editing engine and power")
                    .accessibilityHint("Discard changes and return to vehicle details")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedVehicle = vehicle
                        updatedVehicle.engineNumber = engineNumber
                        updatedVehicle.engineSize = engineSize
                        updatedVehicle.numberOfCylinders = numberOfCylinders
                        updatedVehicle.power = power
                        updatedVehicle.torque = torque
                        onSave(updatedVehicle)
                        dismiss()
                    }
                    .accessibilityLabel("Save engine and power")
                    .accessibilityHint("Save changes and return to vehicle details")
                }
            }
        }
    }
}

struct EditFinanceView: View {
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle
    let onSave: (Vehicle) -> Void
    let vehicleService: VehicleService
    
    @State private var financeCompany: String
    @State private var financeAccountNumber: String
    @State private var showingFilePicker = false
    @State private var financeContractDocument: Data? = nil
    @State private var financeContractFileName: String = ""
    
    init(vehicle: Vehicle, onSave: @escaping (Vehicle) -> Void, vehicleService: VehicleService) {
        self.vehicle = vehicle
        self.onSave = onSave
        self.vehicleService = vehicleService
        _financeCompany = State(initialValue: vehicle.financeCompany)
        _financeAccountNumber = State(initialValue: vehicle.financeAccountNumber)
        _financeContractDocument = State(initialValue: vehicle.financeContractDocument)
        _financeContractFileName = State(initialValue: vehicle.financeContractFileName)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Finance") {
                    HStack {
                        Text("Finance Company")
                        Spacer()
                        TextField("Absa Bank", text: $financeCompany)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Finance Company")
                            .accessibilityHint("Enter the finance company name")
                    }
                    
                    HStack {
                        Text("Finance Account Number")
                        Spacer()
                        TextField("00050043750", text: $financeAccountNumber)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Finance Account Number")
                            .accessibilityHint("Enter the finance account number")
                    }
                }
                
                Section("Finance Contract") {
                    if let _ = financeContractDocument {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                            Text(financeContractFileName.isEmpty ? "Finance Contract" : financeContractFileName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Remove") {
                                financeContractDocument = nil
                                financeContractFileName = ""
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button(action: { showingFilePicker = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.orange)
                                Text("Upload Finance Contract")
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Edit Finance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel editing finance")
                    .accessibilityHint("Discard changes and return to vehicle details")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVehicle()
                    }
                    .accessibilityLabel("Save finance")
                    .accessibilityHint("Save changes and return to vehicle details")
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let files):
                    if let file = files.first {
                        do {
                            let data = try Data(contentsOf: file)
                            financeContractDocument = data
                            financeContractFileName = file.lastPathComponent
                        } catch {
                            print("Error reading file: \(error)")
                        }
                    }
                case .failure(let error):
                    print("Error selecting file: \(error)")
                }
            }
        }
    }
    
    private func saveVehicle() {
        // Upload file to Firebase Storage if document exists
        if let documentData = financeContractDocument, !financeContractFileName.isEmpty {
            vehicleService.uploadFile(documentData, fileName: financeContractFileName, vehicleId: vehicle.id.uuidString) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        var updatedVehicle = self.vehicle
                        updatedVehicle.financeCompany = self.financeCompany
                        updatedVehicle.financeAccountNumber = self.financeAccountNumber
                        updatedVehicle.financeContractDocument = self.financeContractDocument
                        updatedVehicle.financeContractFileName = self.financeContractFileName
                        self.onSave(updatedVehicle)
                        self.dismiss()
                    case .failure(let error):
                        print("Error uploading file: \(error)")
                        // Still save the vehicle even if file upload fails
                        var updatedVehicle = self.vehicle
                        updatedVehicle.financeCompany = self.financeCompany
                        updatedVehicle.financeAccountNumber = self.financeAccountNumber
                        updatedVehicle.financeContractDocument = self.financeContractDocument
                        updatedVehicle.financeContractFileName = self.financeContractFileName
                        self.onSave(updatedVehicle)
                        self.dismiss()
                    }
                }
            }
        } else {
            var updatedVehicle = vehicle
            updatedVehicle.financeCompany = financeCompany
            updatedVehicle.financeAccountNumber = financeAccountNumber
            updatedVehicle.financeContractDocument = financeContractDocument
            updatedVehicle.financeContractFileName = financeContractFileName
            onSave(updatedVehicle)
            dismiss()
        }
    }
}

struct EditInsuranceView: View {
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle
    let onSave: (Vehicle) -> Void
    let vehicleService: VehicleService
    
    @State private var insuranceCompany: String
    @State private var insurancePolicyNumber: String
    @State private var showingFilePicker = false
    @State private var insurancePolicyDocument: Data? = nil
    @State private var insurancePolicyFileName: String = ""
    
    init(vehicle: Vehicle, onSave: @escaping (Vehicle) -> Void, vehicleService: VehicleService) {
        self.vehicle = vehicle
        self.onSave = onSave
        self.vehicleService = vehicleService
        _insuranceCompany = State(initialValue: vehicle.insuranceCompany)
        _insurancePolicyNumber = State(initialValue: vehicle.insurancePolicyNumber)
        _insurancePolicyDocument = State(initialValue: vehicle.insurancePolicyDocument)
        _insurancePolicyFileName = State(initialValue: vehicle.insurancePolicyFileName)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Insurance") {
                    HStack {
                        Text("Insurance Company")
                        Spacer()
                        TextField("Discovery Insure", text: $insuranceCompany)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Insurance Company")
                            .accessibilityHint("Enter the insurance company name")
                    }
                    
                    HStack {
                        Text("Insurance Policy Number")
                        Spacer()
                        TextField("4003637528", text: $insurancePolicyNumber)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Insurance Policy Number")
                            .accessibilityHint("Enter the insurance policy number")
                    }
                }
                
                Section("Insurance Policy") {
                    if let _ = insurancePolicyDocument {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                            Text(insurancePolicyFileName.isEmpty ? "Insurance Policy" : insurancePolicyFileName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Remove") {
                                insurancePolicyDocument = nil
                                insurancePolicyFileName = ""
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button(action: { showingFilePicker = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.orange)
                                Text("Upload Insurance Policy")
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Edit Insurance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel editing insurance")
                    .accessibilityHint("Discard changes and return to vehicle details")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveVehicle()
                    }
                    .accessibilityLabel("Save insurance")
                    .accessibilityHint("Save changes and return to vehicle details")
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let files):
                    if let file = files.first {
                        do {
                            let data = try Data(contentsOf: file)
                            insurancePolicyDocument = data
                            insurancePolicyFileName = file.lastPathComponent
                        } catch {
                            print("Error reading file: \(error)")
                        }
                    }
                case .failure(let error):
                    print("Error selecting file: \(error)")
                }
            }
        }
    }
    
    private func saveVehicle() {
        // Upload file to Firebase Storage if document exists
        if let documentData = insurancePolicyDocument, !insurancePolicyFileName.isEmpty {
            vehicleService.uploadFile(documentData, fileName: insurancePolicyFileName, vehicleId: vehicle.id.uuidString) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        var updatedVehicle = self.vehicle
                        updatedVehicle.insuranceCompany = self.insuranceCompany
                        updatedVehicle.insurancePolicyNumber = self.insurancePolicyNumber
                        updatedVehicle.insurancePolicyDocument = self.insurancePolicyDocument
                        updatedVehicle.insurancePolicyFileName = self.insurancePolicyFileName
                        self.onSave(updatedVehicle)
                        self.dismiss()
                    case .failure(let error):
                        print("Error uploading file: \(error)")
                        // Still save the vehicle even if file upload fails
                        var updatedVehicle = self.vehicle
                        updatedVehicle.insuranceCompany = self.insuranceCompany
                        updatedVehicle.insurancePolicyNumber = self.insurancePolicyNumber
                        updatedVehicle.insurancePolicyDocument = self.insurancePolicyDocument
                        updatedVehicle.insurancePolicyFileName = self.insurancePolicyFileName
                        self.onSave(updatedVehicle)
                        self.dismiss()
                    }
                }
            }
        } else {
            var updatedVehicle = vehicle
            updatedVehicle.insuranceCompany = insuranceCompany
            updatedVehicle.insurancePolicyNumber = insurancePolicyNumber
            updatedVehicle.insurancePolicyDocument = insurancePolicyDocument
            updatedVehicle.insurancePolicyFileName = insurancePolicyFileName
            onSave(updatedVehicle)
            dismiss()
        }
    }
}

struct EditServicePlansView: View {
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle
    let onSave: (Vehicle) -> Void
    
    @State private var serviceInterval: String
    @State private var servicePlan: String
    @State private var maintenancePlan: String
    @State private var warrantyPeriod: String
    @State private var engineWarranty: String
    @State private var roadsideAssistance: String
    
    init(vehicle: Vehicle, onSave: @escaping (Vehicle) -> Void) {
        self.vehicle = vehicle
        self.onSave = onSave
        _serviceInterval = State(initialValue: vehicle.serviceInterval)
        _servicePlan = State(initialValue: vehicle.servicePlan)
        _maintenancePlan = State(initialValue: vehicle.maintenancePlan)
        _warrantyPeriod = State(initialValue: vehicle.warrantyPeriod)
        _engineWarranty = State(initialValue: vehicle.engineWarranty)
        _roadsideAssistance = State(initialValue: vehicle.roadsideAssistance)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Service Plans") {
                    HStack {
                        Text("Service Interval")
                        Spacer()
                        TextField("15000km", text: $serviceInterval)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Service Interval")
                            .accessibilityHint("Enter the service interval, for example 15000km")
                    }
                    
                    HStack {
                        Text("Service Plan")
                        Spacer()
                        TextField("5 years/ 60,000km", text: $servicePlan)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Service Plan")
                            .accessibilityHint("Enter the service plan details")
                    }
                    
                    HStack {
                        Text("Maintenance Plan")
                        Spacer()
                        TextField("60 mo", text: $maintenancePlan)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Maintenance Plan")
                            .accessibilityHint("Enter the maintenance plan duration")
                    }
                    
                    HStack {
                        Text("Warranty Period")
                        Spacer()
                        TextField("5 years/ 150,000km", text: $warrantyPeriod)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Warranty Period")
                            .accessibilityHint("Enter the warranty period details")
                    }
                    
                    HStack {
                        Text("Engine Warranty")
                        Spacer()
                        TextField("10 years/ 1 Million km", text: $engineWarranty)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Engine Warranty")
                            .accessibilityHint("Enter the engine warranty details")
                    }
                    
                    HStack {
                        Text("Roadside Assistance")
                        Spacer()
                        TextField("5 years/ Unlimited km", text: $roadsideAssistance)
                            .multilineTextAlignment(.trailing)
                            .accessibilityLabel("Roadside Assistance")
                            .accessibilityHint("Enter the roadside assistance details")
                    }
                }
            }
            .navigationTitle("Edit Service Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel editing service plans")
                    .accessibilityHint("Discard changes and return to vehicle details")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedVehicle = vehicle
                        updatedVehicle.serviceInterval = serviceInterval
                        updatedVehicle.servicePlan = servicePlan
                        updatedVehicle.maintenancePlan = maintenancePlan
                        updatedVehicle.warrantyPeriod = warrantyPeriod
                        updatedVehicle.engineWarranty = engineWarranty
                        updatedVehicle.roadsideAssistance = roadsideAssistance
                        onSave(updatedVehicle)
                        dismiss()
                    }
                    .accessibilityLabel("Save service plans")
                    .accessibilityHint("Save changes and return to vehicle details")
                }
            }
        }
    }
}

struct VehicleRow: View {
    let label: String
    let value: String
    var isLink: Bool = false
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                HStack(spacing: 4) {
                    Text(value)
                        .font(.subheadline.bold())
                        .foregroundColor(isLink ? .black : .primary)
                    if isLink {
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.orange)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
        .accessibilityAddTraits(isLink ? [.isButton, .isLink] : [])
    }
}

struct AddVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    let vehicleService: VehicleService
    
    @State private var year: String = ""
    @State private var model: String = ""
    @State private var trim: String = ""
    @State private var manufacturer: String = ""
    @State private var plate: String = ""
    @State private var vin: String = ""
    @State private var bodyType: String = ""
    @State private var doors: String = ""
    @State private var imageName: String = "chery-tiggo-4-pro-base-model"
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    HStack {
                        Text("Year")
                        Spacer()
                        TextField("2024", text: $year)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Manufacturer")
                        Spacer()
                        TextField("Chery", text: $manufacturer)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Model")
                        Spacer()
                        TextField("Tiggo 4 Pro DCT", text: $model)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Trim")
                        Spacer()
                        TextField("Elite 1.5 SE", text: $trim)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Registration") {
                    HStack {
                        Text("License Plate")
                        Spacer()
                        TextField("KLR942EC", text: $plate)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("VIN")
                        Spacer()
                        TextField("LVVDB21B5RC074961", text: $vin)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Details") {
                    HStack {
                        Text("Body Type")
                        Spacer()
                        TextField("Cross-over", text: $bodyType)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Doors")
                        Spacer()
                        TextField("5", text: $doors)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
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
                    .disabled(isLoading || !isFormValid)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !year.isEmpty && !model.isEmpty && !manufacturer.isEmpty
    }
    
    private func saveVehicle() {
        guard let yearInt = Int(year) else {
            errorMessage = "Please enter a valid year"
            showingError = true
            return
        }
        
        isLoading = true
        
        let newVehicle = Vehicle(
            year: yearInt,
            imageName: imageName,
            plate: plate,
            vin: vin,
            model: model,
            trim: trim,
            manufacturer: manufacturer,
            bodyType: bodyType,
            doors: doors
        )
        
        vehicleService.addVehicle(newVehicle) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    VehiclesView()
} 