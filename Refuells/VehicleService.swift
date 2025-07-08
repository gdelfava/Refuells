import Foundation
import FirebaseFirestore
import FirebaseAuth
import UIKit

class VehicleService: ObservableObject {
    private let db = Firestore.firestore()
    private let storageService = FirebaseStorageService()
    @Published var vehicles: [Vehicle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        fetchVehicles()
    }
    
    func fetchVehicles() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        db.collection("users").document(userId).collection("vehicles")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "Error fetching vehicles: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        self?.vehicles = []
                        return
                    }
                    
                    self?.vehicles = documents.compactMap { document in
                        try? document.data(as: Vehicle.self)
                    }
                }
            }
    }
    
    func addVehicle(_ vehicle: Vehicle) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try db.collection("users").document(userId).collection("vehicles").addDocument(from: vehicle) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = "Error adding vehicle: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error adding vehicle: \(error.localizedDescription)"
            }
        }
    }
    
    func updateVehicle(_ vehicle: Vehicle) {
        guard let userId = Auth.auth().currentUser?.uid,
              let vehicleId = vehicle.id else {
            errorMessage = "Invalid vehicle data"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try db.collection("users").document(userId).collection("vehicles").document(vehicleId).setData(from: vehicle) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = "Error updating vehicle: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error updating vehicle: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteVehicle(_ vehicle: Vehicle) {
        guard let userId = Auth.auth().currentUser?.uid,
              let vehicleId = vehicle.id else {
            errorMessage = "Invalid vehicle data"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // First delete the image from Firebase Storage if it exists
        if vehicle.imageURL != nil {
            Task {
                do {
                    try await storageService.deleteVehicleImage(for: vehicleId)
                    print("✅ Vehicle image deleted from storage")
                } catch {
                    print("⚠️ Failed to delete vehicle image: \(error.localizedDescription)")
                }
            }
        }
        
        // Then delete the vehicle document
        db.collection("users").document(userId).collection("vehicles").document(vehicleId).delete { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Error deleting vehicle: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Image Management
    
    func uploadVehicleImage(_ image: UIImage, for vehicleId: String) async throws -> String {
        return try await storageService.uploadVehicleImage(image, for: vehicleId)
    }
    
    func downloadVehicleImage(from urlString: String) async throws -> UIImage {
        return try await storageService.downloadVehicleImage(from: urlString)
    }
    
    func deleteVehicleImage(for vehicleId: String) async throws {
        try await storageService.deleteVehicleImage(for: vehicleId)
    }
    
    func imageExists(for vehicleId: String) async -> Bool {
        return await storageService.imageExists(for: vehicleId)
    }
} 