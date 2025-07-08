import Foundation
import FirebaseStorage
import FirebaseAuth
import UIKit

enum StorageError: Error, LocalizedError {
    case notAuthenticated
    case compressionFailed
    case uploadFailed(Error)
    case downloadFailed(Error)
    case invalidImageData
    case invalidURL
    case deleteFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .compressionFailed:
            return "Failed to compress image"
        case .uploadFailed(let error):
            return "Upload failed: \(error.localizedDescription)"
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .invalidImageData:
            return "Invalid image data"
        case .invalidURL:
            return "Invalid URL"
        case .deleteFailed(let error):
            return "Delete failed: \(error.localizedDescription)"
        }
    }
}

class FirebaseStorageService: ObservableObject {
    private let storage = Storage.storage()
    @Published var isUploading = false
    @Published var isDownloading = false
    @Published var errorMessage: String?
    
    // MARK: - Upload Image
    
    func uploadVehicleImage(_ image: UIImage, for vehicleId: String) async throws -> String {
        print("🖼️ Starting image upload for vehicle: \(vehicleId)")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ User not authenticated")
            throw StorageError.notAuthenticated
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("❌ Failed to compress image")
            throw StorageError.compressionFailed
        }
        
        print("📊 Image size: \(imageData.count / 1024) KB")
        
        // Create storage reference with proper path structure
        let storageRef = storage.reference()
        let imagePath = "users/\(userId)/vehicles/\(vehicleId)/image.jpg"
        let imageRef = storageRef.child(imagePath)
        
        print("📁 Uploading to path: \(imagePath)")
        
        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public, max-age=31536000" // 1 year cache
        
        do {
            // Upload the image data
            let _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
            print("✅ Image uploaded successfully")
            
            // Get the download URL
            let downloadURL = try await imageRef.downloadURL()
            print("🔗 Download URL: \(downloadURL.absoluteString)")
            
            return downloadURL.absoluteString
            
        } catch {
            print("❌ Upload failed: \(error.localizedDescription)")
            throw StorageError.uploadFailed(error)
        }
    }
    
    // MARK: - Download Image
    
    func downloadVehicleImage(from urlString: String) async throws -> UIImage {
        print("🖼️ Starting image download from: \(urlString)")
        
        guard URL(string: urlString) != nil else {
            print("❌ Invalid URL: \(urlString)")
            throw StorageError.invalidURL
        }
        
        do {
            // Create storage reference from URL
            let storageRef = storage.reference(forURL: urlString)
            
            // Download with size limit (10MB)
            let data = try await storageRef.data(maxSize: 10 * 1024 * 1024)
            print("📊 Downloaded data size: \(data.count / 1024) KB")
            
            guard let image = UIImage(data: data) else {
                print("❌ Failed to create UIImage from data")
                throw StorageError.invalidImageData
            }
            
            print("✅ Image downloaded successfully")
            return image
            
        } catch {
            print("❌ Download failed: \(error.localizedDescription)")
            throw StorageError.downloadFailed(error)
        }
    }
    
    // MARK: - Delete Image
    
    func deleteVehicleImage(for vehicleId: String) async throws {
        print("🗑️ Starting image deletion for vehicle: \(vehicleId)")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ User not authenticated")
            throw StorageError.notAuthenticated
        }
        
        let storageRef = storage.reference()
        let imagePath = "users/\(userId)/vehicles/\(vehicleId)/image.jpg"
        let imageRef = storageRef.child(imagePath)
        
        print("📁 Deleting from path: \(imagePath)")
        
        do {
            try await imageRef.delete()
            print("✅ Image deleted successfully")
        } catch {
            print("❌ Delete failed: \(error.localizedDescription)")
            throw StorageError.deleteFailed(error)
        }
    }
    
    // MARK: - Check if image exists
    
    func imageExists(for vehicleId: String) async -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            return false
        }
        
        let storageRef = storage.reference()
        let imagePath = "users/\(userId)/vehicles/\(vehicleId)/image.jpg"
        let imageRef = storageRef.child(imagePath)
        
        do {
            let _ = try await imageRef.getMetadata()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Get image URL without downloading
    
    func getImageURL(for vehicleId: String) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw StorageError.notAuthenticated
        }
        
        let storageRef = storage.reference()
        let imagePath = "users/\(userId)/vehicles/\(vehicleId)/image.jpg"
        let imageRef = storageRef.child(imagePath)
        
        let downloadURL = try await imageRef.downloadURL()
        return downloadURL.absoluteString
    }
} 