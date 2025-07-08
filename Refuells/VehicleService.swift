import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
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
    
    func addVehicle(_ vehicle: Vehicle, completion: @escaping (String?) -> Void = { _ in }) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            completion(nil)
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
                        completion(nil)
                    } else {
                        // Get the document ID from the newly created document
                        self?.db.collection("users").document(userId).collection("vehicles")
                            .order(by: "createdAt", descending: true)
                            .limit(to: 1)
                            .getDocuments { snapshot, error in
                                if let document = snapshot?.documents.first {
                                    completion(document.documentID)
                                } else {
                                    completion(nil)
                                }
                            }
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error adding vehicle: \(error.localizedDescription)"
                completion(nil)
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
    
    func uploadVehicleImage(_ image: UIImage, vehicleId: String, completion: @escaping (Result<String, Error>) -> Void) {
        FirebaseManager.shared.uploadVehicleImage(image, vehicleId: vehicleId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let imageURL):
                    print("✅ Image uploaded successfully: \(imageURL)")
                    completion(.success(imageURL))
                case .failure(let error):
                    print("❌ Image upload failed: \(error.localizedDescription)")
                    self.errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    completion(.failure(error))
                }
            }
        }
    }
    
    func deleteVehicleImage(vehicleId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        FirebaseManager.shared.deleteVehicleImage(vehicleId: vehicleId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Image deleted successfully")
                    completion(.success(()))
                case .failure(let error):
                    print("❌ Image deletion failed: \(error.localizedDescription)")
                    self.errorMessage = "Failed to delete image: \(error.localizedDescription)"
                    completion(.failure(error))
                }
            }
        }
    }
    
    func loadImageFromURL(_ urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            completion(nil)
            return
        }
        
        print("🖼️ Loading image from URL: \(urlString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to load image: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    print("❌ Failed to create image from data")
                    completion(nil)
                    return
                }
                
                print("✅ Image loaded successfully from URL")
                completion(image)
            }
        }.resume()
    }
} 