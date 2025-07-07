import Foundation
import FirebaseFirestore
import FirebaseAuth
import UIKit

class VehicleService: ObservableObject {
    private let db = Firestore.firestore()
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
        
        db.collection("users").document(userId).collection("vehicles").document(vehicleId).delete { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Error deleting vehicle: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func saveImage(_ image: UIImage) -> String? {
        print("🖼️ Attempting to save image...")
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("❌ Failed to compress image")
            errorMessage = "Failed to compress image"
            return nil
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "vehicle_\(UUID().uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        print("📁 Saving image to: \(fileURL.path)")
        
        do {
            try imageData.write(to: fileURL)
            print("✅ Image saved successfully: \(fileName)")
            return fileName
        } catch {
            print("❌ Failed to save image: \(error.localizedDescription)")
            errorMessage = "Failed to save image: \(error.localizedDescription)"
            return nil
        }
    }
    
    func loadImage(from path: String) -> UIImage? {
        print("🖼️ Attempting to load image from: \(path)")
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(path)
        
        print("📁 Loading image from: \(fileURL.path)")
        
        guard let imageData = try? Data(contentsOf: fileURL) else {
            print("❌ Failed to load image data")
            return nil
        }
        
        guard let image = UIImage(data: imageData) else {
            print("❌ Failed to create UIImage from data")
            return nil
        }
        
        print("✅ Image loaded successfully")
        return image
    }
} 