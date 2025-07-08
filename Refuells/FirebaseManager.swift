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
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
            return
        }
        
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