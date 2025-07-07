import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class VehicleService: ObservableObject {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    @Published var vehicles: [Vehicle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        fetchVehicles()
    }
    
    // MARK: - CRUD Operations
    
    func fetchVehicles() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        
        db.collection("users").document(userId).collection("vehicles")
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
    
    func addVehicle(_ vehicle: Vehicle, completion: @escaping (Result<Vehicle, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(VehicleError.userNotAuthenticated))
            return
        }
        
        var newVehicle = vehicle
        newVehicle.id = UUID()
        
        do {
            let docRef = try db.collection("users").document(userId).collection("vehicles").addDocument(from: newVehicle)
            newVehicle.id = UUID(uuidString: docRef.documentID) ?? vehicle.id
            completion(.success(newVehicle))
        } catch {
            completion(.failure(error))
        }
    }
    
    func updateVehicle(_ vehicle: Vehicle, completion: @escaping (Result<Vehicle, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(VehicleError.userNotAuthenticated))
            return
        }
        
        do {
            try db.collection("users").document(userId).collection("vehicles").document(vehicle.id.uuidString).setData(from: vehicle)
            completion(.success(vehicle))
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteVehicle(_ vehicle: Vehicle, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(VehicleError.userNotAuthenticated))
            return
        }
        
        // Delete associated files from Storage
        deleteVehicleFiles(vehicle) { [weak self] result in
            switch result {
            case .success:
                // Delete document from Firestore
                self?.db.collection("users").document(userId).collection("vehicles").document(vehicle.id.uuidString).delete { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - File Upload Operations
    
    func uploadFile(_ data: Data, fileName: String, vehicleId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(VehicleError.userNotAuthenticated))
            return
        }
        
        let storageRef = storage.reference().child("users/\(userId)/vehicles/\(vehicleId)/\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "application/octet-stream"
        
        storageRef.putData(data, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(VehicleError.uploadFailed))
                }
            }
        }
    }
    
    func downloadFile(fileName: String, vehicleId: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(VehicleError.userNotAuthenticated))
            return
        }
        
        let storageRef = storage.reference().child("users/\(userId)/vehicles/\(vehicleId)/\(fileName)")
        
        storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(VehicleError.downloadFailed))
            }
        }
    }
    
    private func deleteVehicleFiles(_ vehicle: Vehicle, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(VehicleError.userNotAuthenticated))
            return
        }
        
        let storageRef = storage.reference().child("users/\(userId)/vehicles/\(vehicle.id.uuidString)")
        
        storageRef.listAll { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let items = result?.items else {
                completion(.success(()))
                return
            }
            
            let group = DispatchGroup()
            var deleteError: Error?
            
            for item in items {
                group.enter()
                item.delete { error in
                    if let error = error {
                        deleteError = error
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                if let error = deleteError {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
}

// MARK: - Error Types

enum VehicleError: LocalizedError {
    case userNotAuthenticated
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .uploadFailed:
            return "Failed to upload file"
        case .downloadFailed:
            return "Failed to download file"
        }
    }
} 