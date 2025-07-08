//
//  FirebaseManager.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseStorage
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices
import Network

class FirebaseManager: NSObject, ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var networkStatus = "Unknown"
    
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    
    private override init() {
        super.init()
        setupNetworkMonitoring()
        setupFirebase()
        checkAuthState()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.networkStatus = "Connected"
                    print("✅ Network connection available")
                } else {
                    self?.networkStatus = "Disconnected"
                    print("❌ No network connection")
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    private func setupFirebase() {
        // Check if Firebase is already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase configured successfully")
            
            // Test Firebase connection
            testFirebaseConnection()
        } else {
            print("ℹ️ Firebase already configured")
        }
    }
    
    private func testFirebaseConnection() {
        // Test Firestore connection
        let db = Firestore.firestore()
        db.collection("test").document("connection").getDocument { document, error in
            if let error = error {
                print("⚠️ Firebase connection test failed: \(error.localizedDescription)")
                print("🔍 This might be due to:")
                print("   - Network connectivity issues")
                print("   - Firebase project not properly configured")
                print("   - Simulator network limitations")
            } else {
                print("✅ Firebase connection test successful")
            }
        }
    }
    
    func checkAuthState() {
        print("🔍 Checking authentication state...")
        if let user = Auth.auth().currentUser {
            print("✅ User is authenticated: \(user.displayName ?? "Unknown")")
            self.currentUser = user
            self.isAuthenticated = true
        } else {
            print("ℹ️ No authenticated user found")
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    func signInWithGoogle() {
        print("🚀 Starting Google Sign-In...")
        isLoading = true
        errorMessage = nil
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            let error = "Firebase configuration error - missing client ID"
            print("❌ \(error)")
            errorMessage = error
            isLoading = false
            return
        }
        
        print("✅ Client ID found: \(clientID)")
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            let error = "Unable to present sign-in view"
            print("❌ \(error)")
            errorMessage = error
            isLoading = false
            return
        }
        
        print("📱 Presenting Google Sign-In...")
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Google Sign-In error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    let error = "Failed to get user token"
                    print("❌ \(error)")
                    self?.errorMessage = error
                    return
                }
                
                print("✅ Google Sign-In successful, authenticating with Firebase...")
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                             accessToken: user.accessToken.tokenString)
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ Firebase authentication error: \(error.localizedDescription)")
                            self?.errorMessage = error.localizedDescription
                        } else {
                            print("✅ Firebase authentication successful")
                            self?.checkAuthState()
                        }
                    }
                }
            }
        }
    }
    
    func signInWithApple() {
        print("🚀 Starting Apple Sign-In...")
        isLoading = true
        errorMessage = nil
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func signOut() {
        print("🚪 Signing out...")
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            print("✅ Sign out successful")
            checkAuthState()
        } catch {
            print("❌ Sign out error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Firebase Storage Methods
    
    func uploadVehicleImage(_ image: UIImage, vehicleId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        // Optimize image before upload
        let optimizedImage = optimizeImageForUpload(image)
        guard let imageData = optimizedImage.jpegData(compressionQuality: 0.4) else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
            return
        }
        
        print("📏 Optimized vehicle image size: \(imageData.count / 1024)KB")
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imagePath = "users/\(userId)/vehicles/\(vehicleId)/vehicle_image.jpg"
        let imageRef = storageRef.child(imagePath)
        
        print("📤 Uploading image to Firebase Storage: \(imagePath)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("❌ Upload failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Get download URL
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ Failed to get download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "FirebaseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                print("✅ Image uploaded successfully: \(downloadURL.absoluteString)")
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    func deleteVehicleImage(vehicleId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imagePath = "users/\(userId)/vehicles/\(vehicleId)/vehicle_image.jpg"
        let imageRef = storageRef.child(imagePath)
        
        print("🗑️ Deleting image from Firebase Storage: \(imagePath)")
        
        imageRef.delete { error in
            if let error = error {
                print("❌ Delete failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("✅ Image deleted successfully")
            completion(.success(()))
        }
    }
    
    // MARK: - Station Management Methods
    
    func uploadStationImage(_ image: UIImage, stationId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        // Optimize image before upload
        let optimizedImage = optimizeImageForUpload(image)
        guard let imageData = optimizedImage.jpegData(compressionQuality: 0.4) else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
            return
        }
        
        print("📏 Optimized image size: \(imageData.count / 1024)KB")
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imagePath = "users/\(userId)/stations/\(stationId)/station_image.jpg"
        let imageRef = storageRef.child(imagePath)
        
        print("📤 Uploading station image to Firebase Storage: \(imagePath)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("❌ Station image upload failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Get download URL
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ Failed to get station image download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "FirebaseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                print("✅ Station image uploaded successfully: \(downloadURL.absoluteString)")
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    func deleteStationImage(stationId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imagePath = "users/\(userId)/stations/\(stationId)/station_image.jpg"
        let imageRef = storageRef.child(imagePath)
        
        print("🗑️ Deleting station image from Firebase Storage: \(imagePath)")
        
        imageRef.delete { error in
            if let error = error {
                print("❌ Station image delete failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("✅ Station image deleted successfully")
            completion(.success(()))
        }
    }
    
    func saveStation(_ station: Station, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let db = Firestore.firestore()
        let stationData: [String: Any] = [
            "name": station.name,
            "address": station.address,
            "fuelTypes": station.fuelTypes,
            "currentPrices": station.currentPrices,
            "rating": station.rating,
            "distance": station.distance,
            "isFavorite": station.isFavorite,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        let stationId = station.id.uuidString
        let stationRef = db.collection("users").document(userId).collection("stations").document(stationId)
        
        print("💾 Saving station to Firestore: \(station.name)")
        print("📊 Station data being saved:")
        print("   - Name: \(station.name)")
        print("   - Address: \(station.address)")
        print("   - Fuel Types: \(station.fuelTypes)")
        print("   - Current Prices: \(station.currentPrices)")
        print("   - Rating: \(station.rating)")
        print("   - Distance: \(station.distance)")
        print("   - Is Favorite: \(station.isFavorite)")
        
        stationRef.setData(stationData) { error in
            if let error = error {
                print("❌ Failed to save station: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("✅ Station saved successfully with ID: \(stationId)")
            completion(.success(stationId))
        }
    }
    
    func updateStation(_ station: Station, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let db = Firestore.firestore()
        let stationData: [String: Any] = [
            "name": station.name,
            "address": station.address,
            "fuelTypes": station.fuelTypes,
            "currentPrices": station.currentPrices,
            "rating": station.rating,
            "distance": station.distance,
            "isFavorite": station.isFavorite,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        let stationId = station.id.uuidString
        let stationRef = db.collection("users").document(userId).collection("stations").document(stationId)
        
        print("🔄 Updating station in Firestore: \(station.name)")
        
        stationRef.updateData(stationData) { error in
            if let error = error {
                print("❌ Failed to update station: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("✅ Station updated successfully")
            completion(.success(()))
        }
    }
    
    func deleteStation(_ stationId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let db = Firestore.firestore()
        let stationRef = db.collection("users").document(userId).collection("stations").document(stationId)
        
        print("🗑️ Deleting station from Firestore: \(stationId)")
        
        stationRef.delete { error in
            if let error = error {
                print("❌ Failed to delete station: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("✅ Station deleted successfully")
            completion(.success(()))
        }
    }
    
    func fetchStations(completion: @escaping (Result<[Station], Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let db = Firestore.firestore()
        let stationsRef = db.collection("users").document(userId).collection("stations")
        
        print("📥 Fetching stations from Firestore for user: \(userId)")
        
        stationsRef.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Failed to fetch stations: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("✅ No stations found")
                completion(.success([]))
                return
            }
            
            var stations: [Station] = []
            
            for document in documents {
                let data = document.data()
                
                print("📥 Fetched document data for station: \(document.documentID)")
                print("   - Raw data: \(data)")
                
                guard let name = data["name"] as? String,
                      let address = data["address"] as? String,
                      let fuelTypes = data["fuelTypes"] as? [String],
                      let currentPrices = data["currentPrices"] as? [String: Double],
                      let rating = data["rating"] as? Double,
                      let distance = data["distance"] as? Double,
                      let isFavorite = data["isFavorite"] as? Bool else {
                    print("⚠️ Invalid station data for document: \(document.documentID)")
                    print("   - Name: \(data["name"] ?? "nil")")
                    print("   - Address: \(data["address"] ?? "nil")")
                    print("   - Fuel Types: \(data["fuelTypes"] ?? "nil")")
                    print("   - Current Prices: \(data["currentPrices"] ?? "nil")")
                    print("   - Rating: \(data["rating"] ?? "nil")")
                    print("   - Distance: \(data["distance"] ?? "nil")")
                    print("   - Is Favorite: \(data["isFavorite"] ?? "nil")")
                    continue
                }
                
                let station = Station(
                    id: UUID(uuidString: document.documentID) ?? UUID(),
                    name: name,
                    address: address,
                    fuelTypes: fuelTypes,
                    currentPrices: currentPrices,
                    rating: rating,
                    distance: distance,
                    isFavorite: isFavorite,
                    image: nil // Images will be loaded separately
                )
                
                stations.append(station)
            }
            
            print("✅ Fetched \(stations.count) stations successfully")
            completion(.success(stations))
        }
    }
    
    func loadStationImage(stationId: String, completion: @escaping (Result<UIImage?, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        // Check cache first
        if let cachedImage = ImageCache.shared.image(for: stationId) {
            print("🎯 Using cached image for station: \(stationId)")
            completion(.success(cachedImage))
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imagePath = "users/\(userId)/stations/\(stationId)/station_image.jpg"
        let imageRef = storageRef.child(imagePath)
        
        print("📥 Loading station image from Firebase Storage: \(imagePath)")
        
        // Reduced max size for faster loading (2MB instead of 10MB)
        imageRef.getData(maxSize: 2 * 1024 * 1024) { data, error in
            if let error = error {
                // If image doesn't exist, return nil (not an error)
                if (error as NSError).code == StorageErrorCode.objectNotFound.rawValue {
                    print("ℹ️ No station image found for: \(stationId)")
                    completion(.success(nil))
                    return
                }
                
                print("❌ Failed to load station image: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let imageData = data,
                  let image = UIImage(data: imageData) else {
                print("❌ Failed to create image from data")
                completion(.failure(NSError(domain: "FirebaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])))
                return
            }
            
            // Cache the loaded image
            ImageCache.shared.setImage(image, for: stationId)
            print("✅ Station image loaded and cached successfully")
            completion(.success(image))
        }
    }
    
    // MARK: - Image Optimization
    
    private func optimizeImageForUpload(_ image: UIImage) -> UIImage {
        // Define target size for station images (max 800px on longest side)
        let maxDimension: CGFloat = 800
        let size = image.size
        
        // Calculate new size maintaining aspect ratio
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: (maxDimension * size.height) / size.width)
        } else {
            newSize = CGSize(width: (maxDimension * size.width) / size.height, height: maxDimension)
        }
        
        // Only resize if image is larger than target
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        print("📏 Resizing image from \(size) to \(newSize)")
        
        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
}

// MARK: - Image Cache

class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        // Configure cache limits
        cache.countLimit = 50 // Max 50 images in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // Max 50MB total
    }
    
    func image(for key: String) -> UIImage? {
        return cache.object(forKey: NSString(string: key))
    }
    
    func setImage(_ image: UIImage, for key: String) {
        // Estimate image size in bytes for cost calculation
        let cost = Int(image.size.width * image.size.height * 4) // Rough estimate: width × height × 4 bytes per pixel
        cache.setObject(image, forKey: NSString(string: key), cost: cost)
    }
    
    func removeImage(for key: String) {
        cache.removeObject(forKey: NSString(string: key))
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}

// MARK: - Apple Sign In Delegates
extension FirebaseManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("✅ Apple Sign-In authorization successful")
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            let error = "Failed to get Apple ID credential"
            print("❌ \(error)")
            errorMessage = error
            isLoading = false
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            let error = "Failed to get Apple ID token"
            print("❌ \(error)")
            errorMessage = error
            isLoading = false
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            let error = "Failed to convert Apple ID token to string"
            print("❌ \(error)")
            errorMessage = error
            isLoading = false
            return
        }
        
        print("✅ Apple ID token obtained, authenticating with Firebase...")
        
        let credential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: idTokenString,
            rawNonce: ""
        )
        
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Firebase authentication error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                } else {
                    print("✅ Firebase authentication successful")
                    self?.checkAuthState()
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple Sign-In error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
}

extension FirebaseManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
} 